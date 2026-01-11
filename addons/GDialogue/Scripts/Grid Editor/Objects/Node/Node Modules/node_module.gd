class_name NodeModule
extends Control

signal module_loaded()

static var title_theme : Theme = preload("res://addons/GDialogue/Assets/Themes/t_history_description.tres")

# Name the node module.
@export var title_text : StringName = "Module Descriptor"

## ────────────────────────────────────────────────────────────────────────────
## - Peform Setup
## ────────────────────────────────────────────────────────────────────────────

func _init() -> void:
	#wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_connect_signals()

func _ready() -> void:
	return
	
func _connect_signals() -> void:
	module_loaded.connect(_create_title)
	return

func _get_return_signal() -> Array[Signal]:
	return []

func _set_values(in_size : Vector2, in_anchor : Control.LayoutPreset) -> void:
	if !is_node_ready() : await ready
	call_deferred("set_anchors_preset", in_anchor)
	await set_deferred("size", in_size)
	module_loaded.emit()
	return

func _create_title() -> void:
	var _label = Label.new()
	_label.theme = title_theme
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = title_text
	
	get_parent().add_child(_label)
	
	_label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_label.position.y -= (_label.size.y / 2)
	_label.position.x += (_label.size.x / 8)
	return
