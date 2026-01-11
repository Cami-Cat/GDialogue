@tool
class_name GridNodeContainer
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Perform Setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	
	_connect_signals()	
	_set_to_default_parameters()
	_construct_node(NodeModuleTextEdit)
	return

## Connect and emit important signals.
func _connect_signals() -> void:
	GDialogue.plugin_loaded.connect(_set_node_parent)
	GDialogue.grid_moved.connect(_move_to)
	GDialogue.grid_zoomed.connect(_zoom_to)
	_set_node_parent()
	return

func _set_node_parent() -> void:
	await get_tree().process_frame
	GDialogue.set_node_parent.emit(self)

## Set the scale to the default 1.0 and the position to Zero on every new grid.
func _set_to_default_parameters() -> void:
	position = Vector2.ZERO
	scale = Vector2.ONE
	return

## ────────────────────────────────────────────────────────────────────────────
## - Transformation Handling
## ────────────────────────────────────────────────────────────────────────────

func _move_to(to : Vector2, current_zoom : float) -> void:
	position += to
	return

# TODO : Add relative movement based on the position of the mouse.
# NOTE : I have attempted this, No solutions that I have tried work thus far.
# Therefore I'll just continue by increasing the scale.
func _zoom_to(zoom_to : float) -> void:
	scale = Vector2(zoom_to, zoom_to)
	return

## ────────────────────────────────────────────────────────────────────────────
## - Node Construction
## ────────────────────────────────────────────────────────────────────────────

func _construct_node(node_module : Script = null, _position : Vector2 = Vector2.ZERO, _size : Vector2 = Vector2.ZERO) -> void:
	var _node = GridNode.new(_position, GridNode.DEFAULT_NODE_SIZE, node_module)
	add_child(_node)
	return
