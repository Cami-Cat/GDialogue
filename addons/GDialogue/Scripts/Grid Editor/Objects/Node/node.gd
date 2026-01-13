@tool
class_name GridNode
extends Area2D

## ────────────────────────────────────────────────────────────────────────────
## - Set the area of the Node
## ────────────────────────────────────────────────────────────────────────────

## Project-specific minimum and maximum sizes for nodes.
const MINIMUM_NODE_SIZE 	 : Vector2 = Vector2(200, 100)
const MAXIMUM_NODE_SIZE 	 : Vector2 = Vector2(2000, 1000)
## The threshold that informs the node when it has successfully moved enough not to be deselected on button release.
const MOVEMENT_THRESHOLD	 : float = 1.0

static var DEFAULT_NODE_SIZE : Vector2 = Vector2(400, 200)

## Set the size of the node in the grid, this is separate to the sizes of other nodes. You can set this within new() as-well-
## to construct one with a custom size quickly.
@export var node_size : Vector2 = Vector2(400, 200) :
	set(a):
		a.clamp(MINIMUM_NODE_SIZE, MAXIMUM_NODE_SIZE)
		node_size = a
		return
@export var node_module : Script

## ────────────────────────────────────────────────────────────────────────────
## - Internal Nodes
## ────────────────────────────────────────────────────────────────────────────

var background : HighlightableRect = null
var collision  : CollisionShape2D  = null
var body : Control = null
var body_module : Node = null

var node_selected : bool = true
var mouse_over : bool = false

var input_position : Vector2 = Vector2.ZERO
var just_selected : bool = false
var is_dragging : bool = false

## ────────────────────────────────────────────────────────────────────────────
## - Peform Setup
## ────────────────────────────────────────────────────────────────────────────

func _init(_position : Vector2 = Vector2.ZERO, _in_size : Vector2 = DEFAULT_NODE_SIZE, in_node_module : Script = null) -> void:
	global_position = _position
	node_size = _in_size
	node_module = in_node_module
	return

func _ready() -> void:
	add_to_group("grid_node")
	# Await a frame for whether constructed before GDialogue is ready.
	await get_tree().process_frame
	
	# Construct internal nodes.
	background = _construct_background()
	collision = _construct_collision_box()
	_construct_header_text()
	body = _construct_node_body()
	body_module = add_node_module(node_module)
	
	# Add the area to the custom physics space so that box-select can correctly overlap.
	_connect_physics_to_custom_space()


## ────────────────────────────────────────────────────────────────────────────
## - Node Construction
## ────────────────────────────────────────────────────────────────────────────

func _construct_background() -> HighlightableRect:
	# The background should be a Highlightable Rect, construct a new one.
	var _background = HighlightableRect.new()
	
	# Set background parameters
	_background.size = node_size
	
	add_child(_background)
	return _background

func _construct_collision_box() -> CollisionShape2D:
	# Create a box, add it to the self.
	var _box = CollisionShape2D.new()
	_box.shape = RectangleShape2D.new()
	
	# Set collision parameters.
	_box.shape.size = node_size
	_box.position = (node_size / 2)
	_box.visible = false
	
	add_child(_box)
	return _box

func _construct_header_text() -> NodeHeader:
	var _label = NodeHeader.new(background.size / 4, Control.PRESET_TOP_WIDE, "New Dialogue")
	add_child(_label)
	return _label

func _construct_node_body() -> NodeBody:
	var _body = NodeBody.new()
	background.add_child(_body)
	_body._set_values(Vector2(background.size.x / 2, background.size.y / 3), Control.PRESET_FULL_RECT)
	return _body

func add_node_module(module_type : Script = NodeModule) -> Node:
	if module_type == null : return
	if module_type.get_global_name() != "NodeModule":
		if !module_type.get_base_script() || module_type.get_base_script().get_global_name() != "NodeModule" : 
			GDialogue.print_error(GDialogue.ERROR_CODE.INVALID_NODE_MODULE, self.name, module_type.get_global_name())
			return
	
	var _module = module_type.new()
	body.add_child(_module)
	
	# Half extents
	var half_extent_x = (background.size.x / 2)
	var half_extent_y = (background.size.y / 2)
	
	# Total Margin on the X axis
	var total_margin_x : float = (background.size.x / 10)
	
	_module._set_values(Vector2(half_extent_x - total_margin_x, half_extent_y), Control.PRESET_BOTTOM_WIDE)
	
	# Unfortunately, even setting tne anchor hasn't been updating the position correctly with size taken into account. 
	# Perhaps as a result of call_deferred or set_deferred. But we can handle this manually anyway:
	# Since the difference between this module's x axis and the background's x axis are [total_margin_x], move it by (total_margin_x / 2).
	_module.position.x += (total_margin_x / 2)
	# We'll also Move up by a quarter extent on the Y:
	# quarter_extent = ((background.size.y / 2) / 2)
	_module.position.y -= (half_extent_y / 2)
	_module.module_loaded.connect(_node_finished_loading)
	return _module

func _node_finished_loading() -> void:
	return

## ────────────────────────────────────────────────────────────────────────────
## - Physics Space
## ────────────────────────────────────────────────────────────────────────────

func _connect_physics_to_custom_space() -> void:
	GDialogue.grid_area_created.emit(self)
	# For an area with an already established Collision Shape, you do not need to do any extra stuff. Like in the BoxSelect class.
	# Here, we can just set that we want it to be monitored and the layers that it will occupy.
	PhysicsServer2D.area_set_monitorable(get_rid(), true) # (REQUIREMENT : This is false by default.)
	PhysicsServer2D.area_set_collision_layer(get_rid(), 1) # Areas use Bitmasks, therefore use Bits (1, 2, 4, 8, 16...) rather than Integers.
	PhysicsServer2D.area_set_collision_mask(get_rid(), 1)

## ────────────────────────────────────────────────────────────────────────────
## - Input Handling
## ────────────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Ignore the input outside of itself.
		if !background.get_rect().has_point((get_global_mouse_position() - global_position) / GDialogue._grid_zoom_level) : return
		# So long as the button matches the required button and so long as it isn't an echo:
		if event.button_index == MOUSE_BUTTON_LEFT && !event.is_echo():
			# Select the node, if it's not selected. Otherwise, update the input position.
			if event.is_pressed():
				if !node_selected:
					if Input.is_key_pressed(KEY_CTRL):
						_input_select_node(event.position, false)
					else:
						_input_select_node(event.position, true)
					return
				else:
					_update_input_position(event.position)
					return
			# If the Input Position isn't far enough from the new position of the mouse and you release on click, deselect the node.
			if event.is_released() && ! event.is_echo():
				is_dragging = false
				# Check for whether the node was just selected (on_release will be called on first click), then return early.
				# Check for movement.
				if !_is_just_selected() : 
					if has_moved(event.position):
						var action : GridEditor.Action = GridEditor.Action.new(
							GridEditor.Action.HISTORY_TYPE.TRANSFORM,
							"Moved selected Node.",
							input_position,
							global_position
						)
						GDialogue.add_action_to_history.emit(action)
					
					if !has_moved(event.position):
						if event.button_mask == KEY_MASK_CTRL:
							_input_deselect_node(false)
						else:
							_input_deselect_node(true)
						return
					
	if event is InputEventMouseMotion:
		# If you're already currently dragging, you can completely ignore these checks.
		if !is_dragging:
			# Otherwise, we check for whether the node is selected and if the node *can* be moved.
			if !node_selected || !background.get_rect().has_point((get_global_mouse_position() - global_position) / GDialogue._grid_zoom_level) : return
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			# We update dragging here so we can avoid all those checks above and allow it to keep moving even when the mouse is outside of it's rect.
			# And then move it to the relative position of the event. Multiplied by the zoom level of the grid.
			is_dragging = true
			GDialogue.move_selected_nodes.emit(event.relative / GDialogue._grid_zoom_level)

func _input_select_node(in_position : Vector2 = Vector2.ZERO, overwrite_selected_nodes : bool = true) -> void:
	# We update just_selected so that when we check for release, we don't automatically deselect it.
	just_selected = true
	# We also then set node_selected so that the node is indeed selected.
	GDialogue.grid_node_selected.emit(self, overwrite_selected_nodes)
	# We then update the position of the input to where the input event happened.
	_update_input_position(in_position)

func _input_deselect_node(overwrite_selected_nodes : bool = true) -> void:
	GDialogue.grid_node_deselected.emit(self, overwrite_selected_nodes)
	return

func _is_just_selected() -> bool :
	# If it's just selected, return that it was indeed just selected, but then update it to false so the next check immediately returns false.
	if just_selected:
		just_selected = false
		return true
	return false

func _update_input_position(in_position : Vector2) -> void:
	# We set this for comparison against whether the mouse has moved from the initial position of the event. As seen in the function:
	# has_moved() -> bool:
	input_position = in_position
	
func _move(relative_position : Vector2) -> void:
	# This is called by GDialogue to correctly move multiple nodes relative to their position.
	# This is calculated with (event.relative / _grid_zoom_level) which returns the relative position of the event to the node.
	position += relative_position
	return

func has_moved(in_position : Vector2) -> bool:
	# Create and round a total to prevent floating point errors
	var input_position_total = abs(input_position.x) + abs(input_position.y)
	var in_position_total = abs(in_position.x) + abs(in_position.y)
	# Require the ABSOLUTE (turn a negative value into a positive) difference between positions to be greater than MOVEMENT_THRESHOLD # units
	var position_difference = abs(in_position_total - input_position_total)
	if position_difference > MOVEMENT_THRESHOLD : return true
	return false

## ────────────────────────────────────────────────────────────────────────────
## - Visuals
## ────────────────────────────────────────────────────────────────────────────

func _select_node() -> void:
	background._highlight()
	node_selected = true
	return

func _deselect_node() -> void:
	node_selected = false
	background._unhighlight()
	return
