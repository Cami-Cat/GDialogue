@tool
extends Node

## ────────────────────────────────────────────────────────────────────────────
## - Singleton Settings
## ────────────────────────────────────────────────────────────────────────────

const additional_error_info : bool = true

## ────────────────────────────────────────────────────────────────────────────
## - Static Variables
## ────────────────────────────────────────────────────────────────────────────

static var _physics_server : RID
static var _grid_zoom_level : float
static var _grid : GridEditor

## ────────────────────────────────────────────────────────────────────────────
## - Palette
## ────────────────────────────────────────────────────────────────────────────

static var _palette : Array = preload("res://addons/GDialogue/Assets/Palette/p_dialogue_editor.tres").colors

enum COLOR_LIST {
	Grid_Background, Grid_Dot, 																					# | Grid Specifics
	Box_Select_Rect, Box_Select_Outline, 																		# | Box Select Specifics
	Node_Background, Node_Highlight, Node_Header, Node_Type, 													# | Node Specifics
	Text_Edit_Background, Text_Edit_Placeholder, Text_Edit_Caret, Text_Edit_Normal, Text_Edit_Highlighted ,  	# | Text Edit Specifics
	Header, Icon, Icon_Secondary_Colour																			# | Utility Objects
}

## @experimental: This is not a constant dictionary so that it is possible to populate at runtime.
## Access any colour within the GDialogue plaette using this property.
static var editor_colours : Dictionary[COLOR_LIST, Color] = {}

func _init_palette() -> void:
	# Firstly, create all of the keys in the dictionary.
	for color in COLOR_LIST.keys():
		editor_colours.get_or_add(COLOR_LIST.get(color), Color())
		
	for color in COLOR_LIST.keys():
		# If the palette is not as large as the number of colours that you want, fill the difference with a black colour so as to prevent errors.
		if _palette.size() < COLOR_LIST.size():
			for i in (COLOR_LIST.size() - _palette.size()):
				_palette.append(Color())
		# Use the value (integer) of the enum key as the accessor (cannot access with just "color" as it assumes it is a string 
		editor_colours[COLOR_LIST.get(color)] = _palette[COLOR_LIST.get(color)]
	return

func get_valid_colours() -> Array:
	return COLOR_LIST.keys()

## ────────────────────────────────────────────────────────────────────────────
## - Error Codes
## ────────────────────────────────────────────────────────────────────────────

enum LOG_COLOURS {
	ERROR, WARN, LOG, INFO, SUCCESS
}

const Log_Colours : Dictionary[LOG_COLOURS, Color] = {
	LOG_COLOURS.ERROR : Color(1.0, 0.177, 0.254, 1.0),
	LOG_COLOURS.WARN : Color(1.0, 0.523, 0.156, 1.0),
	LOG_COLOURS.LOG : Color(0.634, 0.634, 0.634, 1.0),
	LOG_COLOURS.INFO : Color(0.344, 0.344, 0.344, 1.0),
	LOG_COLOURS.SUCCESS : Color(0.0, 0.646, 0.169, 1.0),
}

enum ERROR_CODE {
	INVALID_GRID, INVALID_NODE_CONTAINER, INVALID_NODE, INVALID_PALETTE_COLOUR, INVALID_NODE_MODULE
}

const Error_Dict : Dictionary[ERROR_CODE, String] = {
	ERROR_CODE.INVALID_GRID : "Grid is invalid (Plugin Error).",
	ERROR_CODE.INVALID_NODE_CONTAINER : "Node Container is invalid (Plugin Error).",
	ERROR_CODE.INVALID_NODE : "Node is invalid.",
	ERROR_CODE.INVALID_PALETTE_COLOUR : "Colour [%s] does not exist within the GDialogue palette.",
	ERROR_CODE.INVALID_NODE_MODULE : "Error constructing Node Module for node [%s]: Script [%s] is not a valid extension of NodeModule"
}

## Print an error from [enum ERROR_CODE] with [member args] being any additional strings related to the error.
## NOTE : Mostly for internal use, but you can also hijack this if you would like.
func print_error(error_code : ERROR_CODE, ...args) -> void:
	var error_color = Color(1.0, 0.287, 0.225, 1.0)
	var error_code_string : String = Error_Dict[error_code]
	
	# Match the number of string replacements with the argument count. Shorten argument count if it's larger, rather than vice-versa
	if Error_Dict[error_code].count("%s") < args.size():
		args.resize(Error_Dict[error_code].count("%s"))
	# If there are string replacements, replace them all with the argument array as string.
	if args.size() > 0:
		error_code_string = str(Error_Dict[error_code] % args)
	
	# Update the colour of the string to red and introduce the error prefix
	var error_string = "[color=%s] ◈ GDialogue Error : %s[/color]" % [error_color.to_html(), error_code_string]
	
	# Additional error info provides suggestions on ways to avoid these errors.
	if !additional_error_info : 
		print_rich(error_string)
		return
	
	match error_code:
		ERROR_CODE.INVALID_PALETTE_COLOUR : error_string += "\n[color=%s] ╰> Find valid colours by using GDialogue.get_valid_colours()[/color]"
		ERROR_CODE.INVALID_NODE_MODULE : error_string += "\n[color=%s] ╰> Script reference must extend NodeModule[/color]"
	print_rich(error_string % [Log_Colours[LOG_COLOURS.INFO].to_html()])
	return

## ────────────────────────────────────────────────────────────────────────────
## - Define plugin signals
## ────────────────────────────────────────────────────────────────────────────

## - Plugin State Handling

signal plugin_loaded()

## - In-Game dialogue signals

signal dialogue_triggered()
signal next_line()
signal next_dialogue()

## - Grid mangement

signal grid_ready(in_grid : GridEditor)
signal grid_moved(relative_to : Vector2, current_zoom : float)
signal grid_zoomed(relative_to : float)
signal grid_tool_changed(tool_mode : GridEditor.TOOL_MODE)
signal grid_node_hover_state_changed(node : Node, state : bool)
signal grid_node_selected(overwrite : bool, node : Node)
signal grid_nodes_selected(overwrite : bool, nodes : Array[Node])
signal grid_area_created(in_area_rid : RID)
signal set_node_parent(in_node : Control)

## - Selection

signal node_selected(node : GridNode, additive : bool)
signal nodes_selected(nodes : Array[GridNode], additive : bool)

## - History

signal add_action_to_history(in_action : GridEditor.Action)
signal get_history_list()
signal got_history_list(in_history : GridEditor.History)

## - Tool Handling

signal get_tool()
signal got_tool(in_tool : GridEditor.TOOL_MODE)


## ────────────────────────────────────────────────────────────────────────────
## - Global Setup
## ────────────────────────────────────────────────────────────────────────────

func _init() -> void:
	_init_palette()
	_connect_signals()

func _connect_signals() -> void:
	set_node_parent.connect(_set_node_parent)
	grid_area_created.connect(_add_area_to_space)
	grid_zoomed.connect(_set_zoom)
	grid_ready.connect(_set_grid)

func _ready() -> void:
	_create_physics_space()
	# You've loaded, emit that you're ready.
	plugin_loaded.emit()

## ────────────────────────────────────────────────────────────────────────────
## - Grid Handlers
## ────────────────────────────────────────────────────────────────────────────

func _set_grid(in_node : GridEditor) -> void:
	_grid = in_node
	return

func _set_zoom(in_zoom : float) -> void:
	_grid_zoom_level = in_zoom
	return

## Node parent is the root of all "Nodes" - Nodes being each object on the grid.
## This node enables grid navigation and is necessary to the plugin.
func _set_node_parent(in_node : Control) -> void:
	# Assure that we do not call this in an infinite loop.
	set_node_parent.disconnect(_set_node_parent)
	
	# If the grid is currently unloaded, wait for it to finish (finish connecting signals)
	# Then emit the signal again to capture it.
	if !_grid : 
		await grid_ready
		set_node_parent.emit(in_node)
	# If the grid is already ready, that means that the grid is finished, and we do not need to emit a second time.
	
	# Ensure that this signal is reconnected.
	set_node_parent.connect(_set_node_parent)
	return


## ────────────────────────────────────────────────────────────────────────────
## - Plugin Physics Space
## ────────────────────────────────────────────────────────────────────────────

func _create_physics_space() -> void:
	## Create a space in the Physics server, so as not to run any physics within the game world.
	_physics_server = PhysicsServer2D.space_create()
	PhysicsServer2D.space_set_active(_physics_server, true)

func _add_area_to_space(area_rid : RID) -> void:
	PhysicsServer2D.area_set_space(area_rid, _physics_server)
	return
