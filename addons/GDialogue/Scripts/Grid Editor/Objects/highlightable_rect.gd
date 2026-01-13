@tool
class_name HighlightableRect
extends PanelContainer

signal selected
signal unselected

## ────────────────────────────────────────────────────────────────────────────
## - Constants
## ────────────────────────────────────────────────────────────────────────────

const MINIMUM_OUTLINE_SIZE : int = 1 # px, minimum required number to render.
const MAXIMUM_OUTLINE_SIZE : int = 5 # px, incase end-user increases scale range, prevent this from getting astronomically large.
const ZOOM_SCALING_COEFFICIENT : float = 1.5 # Alter this to taste, makes the line thickness much more consistent and without odd widths.

const HIGHLIGHTED_OUTLINE_SIZE_DEFAULT : int = 1
const MOUSE_OVER_OUTLINE_SIZE_DEFAULT : int = 1
const UNHIGHLIGHTED_OUTLINE_SIZE_DEFAULT : int = 0

static var HIGHLIGHTED_OUTLINE_ALPHA_DEFAULT : int = (255 / 2) # Half opacity, ([255] is [100%] in RGBA)
static var MOUSE_OVER_OUTLINE_ALPHA_DEFAULT : int = (255 / 4) # Quarter opacity.
static var UNHIGHLIGHTED_OUTLINE_ALPHA_DEFAULT : int = 0

const HIGHLIGHT_ANIMATION_LENGTH : float = 0.1 # Add a little animation for just a touch of polish.

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
	return

func _initialize_tool() -> void:
	GDialogue.got_tool.connect(tool_changed)
	await get_tree().process_frame
	GDialogue.got_tool.disconnect(tool_changed)

func _initialize_stylebox() -> void:
	theme = preload("res://addons/GDialogue/Assets/Themes/t_highlight_rect.tres").duplicate(true)
	y_sort_enabled = true
	stylebox = get_theme_stylebox("panel", "")
	_unhighlight()
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
	is_selected = true
	_update_properties(HIGHLIGHTED_OUTLINE_SIZE_DEFAULT)
	var alpha = HIGHLIGHTED_OUTLINE_ALPHA_DEFAULT
	await tween_border_highlight(alpha, HIGHLIGHT_ANIMATION_LENGTH)
	return

func _unhighlight() -> void:
	is_selected = false
	var alpha = UNHIGHLIGHTED_OUTLINE_ALPHA_DEFAULT
	await tween_border_highlight(alpha, HIGHLIGHT_ANIMATION_LENGTH)
	_update_properties(UNHIGHLIGHTED_OUTLINE_SIZE_DEFAULT)
	return

func _update_properties(new_data : Variant) -> void:
	stylebox.set_border_width_all(new_data)
	stylebox.set_expand_margin_all(new_data)
	return

func _process(delta: float) -> void:
	if is_selected:
		stylebox.set_expand_margin_all(_get_zoomed_size()) 
		stylebox.set_border_width_all(_get_zoomed_size()) 

func _get_zoomed_size() -> int:
	return clampi((HIGHLIGHTED_OUTLINE_SIZE_DEFAULT / (GDialogue._grid_zoom_level / ZOOM_SCALING_COEFFICIENT)), MINIMUM_OUTLINE_SIZE, MAXIMUM_OUTLINE_SIZE)
