@tool
class_name HighlightableRect
extends PanelContainer

signal selected
signal unselected

## ────────────────────────────────────────────────────────────────────────────
## - External Variables
## ────────────────────────────────────────────────────────────────────────────

@export var inner_colour : Color
@export var highlight_colour : Color
@export var selected_colour : Color

## ────────────────────────────────────────────────────────────────────────────
## - Internal Variables
## ────────────────────────────────────────────────────────────────────────────

var stylebox : StyleBoxFlat
var is_selected : bool = false
var can_select : bool = false

var current_tool : GridEditor.TOOL_MODE

## ────────────────────────────────────────────────────────────────────────────
## - Perform Setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	_connect_signals()
	_initialize_stylebox()
	return

func _connect_signals() -> void:
	GDialogue.grid_tool_changed.connect(tool_changed)
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	return

func _initialize_tool() -> void:
	GDialogue.got_tool.connect(tool_changed)
	await get_tree().process_frame
	GDialogue.got_tool.disconnect(tool_changed)

func _initialize_stylebox() -> void:
	theme = preload("res://addons/GDialogue/Assets/Themes/t_highlight_rect.tres").duplicate(true)
	y_sort_enabled = true
	stylebox = get_theme_stylebox("panel", "")
	stylebox.set_border_width_all(1)
	return

## ────────────────────────────────────────────────────────────────────────────
## - Listen for tool changes and alter behaviour accordingly.
## ────────────────────────────────────────────────────────────────────────────

func tool_changed(in_tool : GridEditor.TOOL_MODE) -> void:
	if in_tool == current_tool : return
	if in_tool == GridEditor.TOOL_MODE.PAN:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_PASS
	current_tool = in_tool
	print(in_tool)
	return

## ────────────────────────────────────────────────────────────────────────────
## - Visual Handling.
## ────────────────────────────────────────────────────────────────────────────

func tween_border_highlight(to_alpha : float = 0.0, length : float = 0.0) -> void:
	var tween = create_tween()
	tween.tween_property(stylebox, "border_color:a8", to_alpha, length)
	await tween.finished
	tween.kill()
	return

func _highlight() -> void:
	stylebox.set_expand_margin_all(1)
	stylebox.set_border_width_all(1)
	var alpha = int(255 / 2)
	await tween_border_highlight(alpha, 0.1)
	return

func _unhighlight() -> void:
	await tween_border_highlight(0.0, 0.1)
	stylebox.set_border_width_all(0)
	stylebox.set_expand_margin_all(0)
	return

## ────────────────────────────────────────────────────────────────────────────
## - Input Handling.
## ────────────────────────────────────────────────────────────────────────────

func _on_mouse_enter() -> void:
	## If the current tool is a box select, we don't want to highlight or unhighlight or that will create odd looking interactions,
	## So we'll just return here. It can handle the highlighting itself.
	if current_tool == GridEditor.TOOL_MODE.BOX_SELECT || current_tool == GridEditor.TOOL_MODE.PAN: return
	can_select = true
	if !is_selected:
		_highlight()
	return

func _on_mouse_exit() -> void:
	## If the current tool is a box select, we don't want to highlight or unhighlight or that will create odd looking interactions,
	## So we'll just return here. It can handle the highlighting itself.
	## Further, when Pan is selected, we don't want to be able to select the object, so we also just return.
	if current_tool == GridEditor.TOOL_MODE.BOX_SELECT || current_tool == GridEditor.TOOL_MODE.PAN : return
	can_select = false
	if !is_selected:
		_unhighlight()
	return
