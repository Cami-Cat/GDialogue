class_name NodeBody
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Peform Setup
## ────────────────────────────────────────────────────────────────────────────

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_values(in_size : Vector2, in_anchor : Control.LayoutPreset) -> void:
	if !is_node_ready() : await ready
	size = in_size
	set_anchors_preset(in_anchor)
	return
