@tool
class_name GridEditor
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Enum declarations
## ────────────────────────────────────────────────────────────────────────────

# Tool mode enum, for defining what effect a button on the interface will have.
enum TOOL_MODE {
	NONE,
	ADD, EDIT, REMOVE, 			## Node tools
	PAN, SELECT, BOX_SELECT, 	## Grid tools
}

static var TOOL_NAMES : Dictionary[TOOL_MODE, String] = {
	TOOL_MODE.NONE : "None",
	TOOL_MODE.ADD : "Add", TOOL_MODE.EDIT : "Edit", TOOL_MODE.REMOVE : "Remove",
	TOOL_MODE.PAN : "Pan", TOOL_MODE.SELECT : "Select", TOOL_MODE.BOX_SELECT : "Box Select",
}

# Store history for all actions, important for undo-redo integration.
var history : History = History.new()
# When to cull history to preserve resources.
var history_limit : int = 50
# Save history between sessions? Consumes more resources.
var save_history : bool = false

## ────────────────────────────────────────────────────────────────────────────
## - Internal variables
## ────────────────────────────────────────────────────────────────────────────

# Store the selected tool to alter input behaviour
var current_tool_mode : TOOL_MODE = TOOL_MODE.NONE

## ────────────────────────────────────────────────────────────────────────────
## - Define attached Components
## ────────────────────────────────────────────────────────────────────────────

# Box select, for when you want to select multiple components at once.
var box_select : BoxSelect
var node_parent : Control

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Await to allow Godot to process and create the Global class before intiializing self.
	await get_tree().process_frame
	
	# Force a grid setup.
	_setup_grid()

func _setup_grid() -> void:
	# Connect the setup for future plugin reloads.
	GDialogue.set_node_parent.connect(_set_node_parent)
	GDialogue.plugin_loaded.connect(_setup_grid)
	# Reset the currently selected tool
	GDialogue.grid_tool_changed.emit(TOOL_MODE.NONE)
	GDialogue.get_tool.emit()
	
	# Set that self is ready.
	GDialogue.grid_ready.emit(self)

	GDialogue.get_history_list.connect(_get_history)
	GDialogue.add_action_to_history.connect(_add_action_to_history)
	GDialogue.grid_tool_changed.connect(_tool_changed)
	

## ────────────────────────────────────────────────────────────────────────────
## - Handle Internals
## ────────────────────────────────────────────────────────────────────────────

## Run on tool change, does not alter anything visually, only alters internal behaviour.
## Attach visuals to the member signal [signal GDialogue.grid_tool_changed] to access this same information.
func _tool_changed(to_tool : TOOL_MODE) -> void:
	if current_tool_mode == to_tool : return
	current_tool_mode = to_tool
	return 

func _set_node_parent(in_node : Control) -> void:
	node_parent = in_node
	return

## ────────────────────────────────────────────────────────────────────────────
## - Select Logic
## ────────────────────────────────────────────────────────────────────────────

func _create_box_select() -> void:
	box_select = BoxSelect.new()
	add_child(box_select)
	return

func _end_box_select() -> void:
	box_select.queue_free()
	return

## ────────────────────────────────────────────────────────────────────────────
## - Define action subclass
## ────────────────────────────────────────────────────────────────────────────

class Action extends Resource:
	
	## ────────────────────────────────────────────────────────────────────────
	## - Enum Declarations
	## ────────────────────────────────────────────────────────────────────────
	
	enum HISTORY_TYPE {
		NONE,
		ADDITION, REMOVAL, EDIT,
		TRANSFORM,
		UNDO, REDO,
		ERROR
	}

	static var TYPE_NAMES : Dictionary[HISTORY_TYPE, String] = {
		HISTORY_TYPE.NONE : "None",
		HISTORY_TYPE.ADDITION : "Added", HISTORY_TYPE.REMOVAL : "Removed", HISTORY_TYPE.EDIT : "Edited",
		HISTORY_TYPE.TRANSFORM : "Transformed",
		HISTORY_TYPE.UNDO : "Undo", HISTORY_TYPE.REDO : "Redo",
		HISTORY_TYPE.ERROR : "Error",
	}

	## ────────────────────────────────────────────────────────────────────────
	## - Init values
	## ────────────────────────────────────────────────────────────────────────

	var _type : HISTORY_TYPE
	var _description : String
	var _when : String
	
	var _data_before : Variant
	var _data_after	 : Variant
	
	func _init(in_type : HISTORY_TYPE, in_description : String, in_data_before : Variant, in_data_after : Variant) -> void:
		_type = in_type
		_description = in_description
		_when = Time.get_time_string_from_system()
		_data_before = in_data_before
		_data_after = in_data_after
		return

	## ────────────────────────────────────────────────────────────────────────
	## - Get Functions
	## ────────────────────────────────────────────────────────────────────────

	func get_data_before() -> Variant:
		return _data_before
	
	func get_data_after() -> Variant:
		return _data_after

	func get_when() -> String:
		return _when
	
	func get_description() -> String:
		return _description
	
	func get_type() -> String:
		return TYPE_NAMES[_type]

	func get_action_as_dict() -> Dictionary:
		var dict : Dictionary = {}
		dict = {
			"Type" : get_type(),
			"Description" : get_description(),
			"When" : get_when(),
			"Data Before" : get_data_before(),
			"Data After" : get_data_after()
		}
		return dict

## ────────────────────────────────────────────────────────────────────────────
## - Define history subclass
## ────────────────────────────────────────────────────────────────────────────

func _get_history() -> void:
	GDialogue.got_history_list.emit(history)

func _add_action_to_history(action : Action) -> bool:
	GDialogue.print_log(str(action.get_action_as_dict()), GDialogue.LOG_TYPES.SUCCESS)
	history.create_new_action(action)
	if history._actions.has(action):
		return true
	return false

class History:
	
	var _actions : Array[Action]

	func create_new_action(in_action : Action) -> Action:
		_actions.append(in_action)
		return in_action

	func get_actions() -> Array[Action]:
		return _actions
	
	func get_latest_action() -> Action:
		return _actions.back()
	
	func clear_history() -> bool:
		_actions.clear()
		if _actions.size() == 0:
			return true
		return false
