@tool
class_name GridInputArea
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Internal Variables
## ────────────────────────────────────────────────────────────────────────────

var current_grid_tool : GridEditor.TOOL_MODE

var box_select : BoxSelect

var input_position : Vector2 = Vector2.ZERO
var current_zoom : float = 1.0
var zoom_step : float = 0.08

var has_focus : bool = false

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	GDialogue.grid_tool_changed.connect(grid_tool_changed)
	mouse_entered.connect(_focus_got)
	mouse_exited.connect(_focus_lost)

## ────────────────────────────────────────────────────────────────────────────
## - Focus
## ────────────────────────────────────────────────────────────────────────────

func _focus_got() -> void:
	has_focus = true

func _focus_lost() -> void:
	has_focus = false

## ────────────────────────────────────────────────────────────────────────────
## - Main Input Handling
## ────────────────────────────────────────────────────────────────────────────

func _input(event : InputEvent) -> void:
	## - OVERRIDE CONTROLS:
	# Grid movement
	if event is InputEventMouseMotion:
		# Pan override control
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			_move_grid(event)
		# Pan tool control.
		if current_grid_tool == GridEditor.TOOL_MODE.PAN:
			if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
				_move_grid(event)
	elif event is InputEventMouseButton:
		# Scrolling
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-zoom_step)
		# Box Select override control
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				_create_box_select()
			if event.is_released():
				_end_box_select()
	## - MAIN CONTROLS:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_grid_tool == GridEditor.TOOL_MODE.BOX_SELECT:
				if event.is_pressed():
					_create_box_select()
				if event.is_released():
					_end_box_select()
	return

## ────────────────────────────────────────────────────────────────────────────
## - Update Functions
## ────────────────────────────────────────────────────────────────────────────

func _move_grid(initial_click_point : InputEvent) -> void:
	input_position -= initial_click_point.relative
	GDialogue.grid_moved.emit(initial_click_point.relative, current_zoom)
	return

func _create_box_select() -> void:
	if !has_focus : return
	if box_select : return
	box_select = BoxSelect.new()
	return

func _end_box_select() -> void:
	GDialogue.nodes_selected.emit(box_select.get_selected_nodes())
	box_select.queue_free()
	return

func _zoom(by_amount : float) -> void:
	if !has_focus : return
	current_zoom = clampf(current_zoom + by_amount, 0.2, 2.5)
	GDialogue.grid_zoomed.emit(current_zoom)
	return

## ────────────────────────────────────────────────────────────────────────────
## - Handle tool switching
## ────────────────────────────────────────────────────────────────────────────

## Alter the display of the mouse depending on the selected tool.
func grid_tool_changed(in_tool : GridEditor.TOOL_MODE) -> void:
	match in_tool:
		GridEditor.TOOL_MODE.PAN:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		GridEditor.TOOL_MODE.SELECT:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		GridEditor.TOOL_MODE.BOX_SELECT:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		_:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
	current_grid_tool = in_tool
	return
