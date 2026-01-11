@tool
class_name IconTextureRect
extends TextureRect

@export var icon_name : StringName = &"CodeFoldedRightArrow" :
	set(a):
		icon_name = a
		_set_icon()

func _ready() -> void:
	_set_icon()
	_set_icon_size()

func _set_icon_size() -> void:
	size = Vector2(16, 16)
	return

func _set_icon() -> void:
	if !EditorInterface.get_editor_theme().has_icon(icon_name, "EditorIcons") : return
	texture = EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")
	return
