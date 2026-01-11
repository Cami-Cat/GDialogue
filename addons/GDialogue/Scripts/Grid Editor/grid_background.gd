@tool
extends ColorRect

var default_cell_size : float = 32.0
var zoom_level : float = 1.0
var world_panning : Vector2 = Vector2.ZERO

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Wait for Godot to process before initializing, so it may create the Global.
	await get_tree().process_frame
	GDialogue.grid_moved.connect(_move_grid)
	GDialogue.grid_zoomed.connect(_zoom)
	# Duplicate material to prevent altering base material.
	material = material.duplicate(true)
	_initialize_shader_parameters()

func _initialize_shader_parameters() -> void:
	material.set_shader_parameter("cell_size", default_cell_size)

## ────────────────────────────────────────────────────────────────────────────
## - Input Handling
## ────────────────────────────────────────────────────────────────────────────

func move_to(in_position : Vector2) -> void:
	material.set_shader_parameter("offset", -in_position)

func _process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	material.set_shader_parameter("cell_size", default_cell_size * zoom_level)
	var world_offset = (world_panning * zoom_level) - (viewport_size / 2.0)
	material.set_shader_parameter("world_offset", world_offset.round())
	return

func _move_grid(in_position : Vector2, _current_zoom : float) -> void:
	world_panning -= in_position / _current_zoom

func _zoom(in_zoom : float) -> void:
	var previous_zoom = zoom_level
	zoom_level = in_zoom
	zoom_level = clampf(zoom_level, 0.2, 2.5)
	
	var zoom_anchor = get_viewport_rect().size / 2
	var zoom_diff = (1 / zoom_level) - (1 / previous_zoom)
	world_panning += (zoom_anchor * zoom_diff)
	
	if zoom_level <= 0.5:
		material.set_shader_parameter("dot_size_px", 1.0)
	else:
		material.set_shader_parameter("dot_size_px", 2.0)
