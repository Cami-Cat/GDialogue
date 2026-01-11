class_name NodeHeader
extends Label

const _theme = preload("res://addons/GDialogue/Assets/Themes/t_node_header.tres")

var _size : Vector2
var _anchor_preset : Control.LayoutPreset

func _init(in_size : Vector2, in_anchor : Control.LayoutPreset, in_text : StringName) -> void:
	# As we're creating a new instance, regardless of what the scene sees - this theme is not set.
	theme = _theme
	# We then set the modulate to the header colour
	set_deferred("self:modulate", GDialogue.editor_colours[GDialogue.COLOR_LIST.Node_Header])
	# Store the anchor and size settings passed in.
	# Godot doesn't let us set these in _init() (even with set_deferred()); (Controls are wonky)
	# Therefore, I store these and set them in ready instead.
	_anchor_preset = in_anchor
	_size = in_size
	# Text can change regardless, so we set that.
	set_deferred("text", in_text)
	return

func _ready() -> void:
	size = _size
	set_anchors_preset(_anchor_preset)
