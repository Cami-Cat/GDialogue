@tool
class_name BoxSelect
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Node List
## ────────────────────────────────────────────────────────────────────────────

## An array containing the nodes selected by the box-selection tool.
var selected_nodes : Array[Node]
var highlighted_nodes : Array[Node]

## ────────────────────────────────────────────────────────────────────────────
## - Internal Variables
## ────────────────────────────────────────────────────────────────────────────

## The position of the initial interaction, to handle scaling.
var initial_position : Vector2

## Additional components created at runtime to add functionality.
var rect : Polygon2D
var outline : Line2D
var area : Area2D

## The colour of the selection box and outline.
var draw_colour : Color = Color("e7f3f70e")
var outline_colour : Color = Color("c2e1ea86")

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	GDialogue.grid_node_hover_state_changed.connect(_hover_state_changed)	
	_set_initial_position()
	_set_size_and_anchor()
	_construct_rect()
	z_index = 4096

## Define the beginning global position of the box's (0, 0).
func _set_initial_position() -> void:
	initial_position = get_global_mouse_position()
	global_position = initial_position

## Ensure that the control fills the rect of it's parent, correctly filling the space so that it culls correctly.
func _set_size_and_anchor() -> void:
	set_deferred("set_anchors_preset", Control.PRESET_FULL_RECT)

## ────────────────────────────────────────────────────────────────────────────
## - Construct box and area
## ────────────────────────────────────────────────────────────────────────────

## Construct the drawn rectangle and collision box for the interactions.
## Create in multiple different steps, start with the main "polygon" - allows for complex point positioning, flipping on multiple axis without issues.
## Create the outline then, a closed line2d following the polygon's points.
## Construct then the collision area, where anything inside will be selected.
func _construct_rect() -> void:
	# Create square selection grid
	rect = Polygon2D.new()
	rect.color = draw_colour
	
	add_child(rect)
	add_child(_construct_outline())
	add_child(_construct_area())
	return

## Create an area within a custom physics space.
func _construct_area() -> Area2D:
	area = Area2D.new()
	GDialogue.grid_area_created.emit(area.get_rid())
	# Create a custom physics shape (Convex to match the varied shape drawn by the mouse)
	var _shape = PhysicsServer2D.convex_polygon_shape_create()
	# We need to add the shape to the area in the physics space, otherwise the area will have nothing.
	PhysicsServer2D.area_add_shape(area.get_rid(), _shape)
	PhysicsServer2D.area_set_transform(area.get_rid(), get_global_transform())
	# It should be monitorable by default, but lets just make sure that it is by setting it to true.
	PhysicsServer2D.area_set_monitorable(area.get_rid(), true)
	# Layers use BITMASKS instead of integer indexes, therefore a value of 24 would be a mix between 5 and 4 (16, 8), 
	# this would cause issues as it expects a correct bit.
	# We can use a Bitwise operation or just set it to the correct bit. this isn't going to interact with the game so we'll go with a value of 1.
	PhysicsServer2D.area_set_collision_layer(area.get_rid(), 1)
	PhysicsServer2D.area_set_collision_mask(area.get_rid(), 1)
	return area

## This outline will display above the polygon that makes up the body.
func _construct_outline() -> Line2D:
	# We'll use a line 2D for this.
	outline = Line2D.new()
	
	# We'll set it's colour to be lighter and more opaque than the innards.
	outline.default_color = outline_colour
	# This closed Line2D will then turn into a box.
	outline.closed = true
	# We set the outline to a desirable width (px) 1.0 is a satisfactory default.
	outline.width = 1.0 # px
	return outline

## ────────────────────────────────────────────────────────────────────────────
## - Get the area and Draw
## ────────────────────────────────────────────────────────────────────────────

## Get the rect defined by the mouse's initial position and it's new position. Creating one point for each corner (4).
func _get_mouse_position_from_start() -> PackedVector2Array:
	# Define the four corners of the polygon, in a clockwise order. This is how Godot expects Convex Polygons.
	var return_array : PackedVector2Array = \
			[Vector2(0, 0), 													# 0 | Top Left
			Vector2(0, get_global_mouse_position().y - initial_position.y), 	# 1 | Bottom Left
			get_global_mouse_position() - initial_position, 					# 2 | Bottom Right
			Vector2(get_global_mouse_position().x - initial_position.x, 0)] 	# 3 | Top Right
	return return_array

## Now draw the rectangle as it should be.
func _draw_polygon() -> void:
	rect.polygon = _get_mouse_position_from_start()
	outline.points = _get_mouse_position_from_start()

## ────────────────────────────────────────────────────────────────────────────
## - Physics Processing
## ────────────────────────────────────────────────────────────────────────────

## Should the rectangle be valid and the collision exist, redraw every frame.
func _physics_process(_delta: float) -> void:
	if area:
		_highlight_selected_nodes()
		_draw_polygon()

## Perform physics queries in order to get the current intersections between objects.
func _get_colliders() -> Array[Node]:
	# If it's going to be removed, there's no reason to continue to check, therefore just return an empty array.
	if is_queued_for_deletion():
		return []
	
	# Is the space correctly set to what it needs to be, so that we can actually check it?
	# A custom space is used so that we can process overlaps without processing other nodes within the tree.
	if PhysicsServer2D.area_get_space(area.get_rid()) != GDialogue._physics_server : 
		PhysicsServer2D.area_set_space(area.get_rid(), GDialogue._physics_server)
		return []
	
	# We snapshot the current version of the area here by setting the shape data outside of the draw call.
	var shape_rid = PhysicsServer2D.area_get_shape(area.get_rid(), 0)
	var points = _get_mouse_position_from_start()
	
	# We update the transform afterwards to ensure all position, scale and rotation data is correct
	PhysicsServer2D.area_set_transform(area.get_rid(), Transform2D())
	PhysicsServer2D.shape_set_data(shape_rid, points)
	
	# We create parameters here, with some important reasons why:
	# collide_with_areas is [false] by default. Therefore we need to set it.
	# transform will be a [Transform2D().new()] by default without setting it to the area's transform.
	# collision_mask must match that of the [area].
	# exclude must exclude the [area] to prevent erroneous overlaps with the self.
	# shape_rid is used here instead of [shape] as convex polygons do not have a .shape property. 
	var _parameters = PhysicsShapeQueryParameters2D.new()
	_parameters.collide_with_areas = true
	_parameters.collision_mask = area.collision_mask
	_parameters.exclude = [area.get_rid()]
	_parameters.shape_rid = shape_rid
	_parameters.transform = get_global_transform()
	
	# Now that we have created the parameter, we can check the state for any intersections.
	var _state = PhysicsServer2D.space_get_direct_state(GDialogue._physics_server)
	var _collisions = _state.intersect_shape(_parameters, 128)

	# Should there be intersections, return an array with them.
	if !_collisions.is_empty():
		var keys : Array[Node] = []
		for _collision in _collisions:
			if keys.has(_collision.collider) : continue
			keys.append(_collision.collider)
		return keys
	return []

## ────────────────────────────────────────────────────────────────────────────
## - Visuals
## ────────────────────────────────────────────────────────────────────────────

## Get all of the currently selected nodes and highlight them, also handles unhighlighting nodes that are no longer selected by box select.
func _highlight_selected_nodes() -> void:
	# Like with the collision detection, we don't really want to continue checking if it's queued for deletion, so we'll just return early.
	# Esepcially as colliders will return a null [] if we don't anyway.
	if is_queued_for_deletion():
		return
	var _colliders = _get_colliders()
	# We check for highlighted nodes that are not selected. Unhighlight them if this is the case.
	for _collider in highlighted_nodes:
		if !_colliders.has(_collider):
			highlighted_nodes.erase(_collider)
			_collider._unhighlight()
				
	# Now we can check if there is anything within _colliders, if not, we can just return right away.
	if _colliders.size() == 0 : return
	
	# We then check for all colliders, if there is a new collider within the array we highlight it.
	for _collider in _colliders:
		if _collider.is_in_group("grid_node") && _collider.has_method("_highlight"):
			if highlighted_nodes.has(_collider) : continue
			highlighted_nodes.append(_collider)
			_collider._highlight()
	return

## On an object's hover state changed, this is called. This will handle the selection and deselection as a single central function.
func _hover_state_changed(in_node : Node, state : bool) -> void:
	if !in_node.is_in_group("grid_node") : return
	if state : _select(in_node)
	else	 : _deselect(in_node)
	return

## Add it to the selection.
func _select(in_area : Node) -> void:
	if in_area.has_method("_highlight") : in_area._highlight()
	return

## Remove it from the selection.
func _deselect(in_area : Node) -> void:
	return

## Return all of the connected nodes.
func get_selected_nodes() -> Array[Node]:
	return selected_nodes
