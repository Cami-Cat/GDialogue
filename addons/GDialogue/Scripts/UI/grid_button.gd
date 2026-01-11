@tool
class_name GridButton
extends Button

## ────────────────────────────────────────────────────────────────────────────
## - Exposed variables
## ────────────────────────────────────────────────────────────────────────────

## The built-in icon name in the Godot Editor that you want it to display.
@export var _icon_name : StringName = &"UndoRedo" :
	set(a):
		_icon_name = a
		_set_icon()
## Should the icon display flipped (vertically) so that Undo becomes Redo, for example.
@export var flip_icon : bool = false :
	set(a):
		flip_icon = a
		_set_icon()
## Attach a specific tool mode to the button.
@export var tool_mode : GridEditor.TOOL_MODE :
	set(a):
		tool_mode = a

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	toggled.connect(_toggled)
	_set_icon()

func _set_icon() -> void:
	if EditorInterface.get_editor_theme().has_icon(_icon_name, "EditorIcons"):
		icon = EditorInterface.get_editor_theme().get_icon(_icon_name, "EditorIcons").duplicate()
		if flip_icon:
			icon.get_image().flip_x()
			var _flipped_image_tex : Texture2D = ImageTexture.create_from_image(icon.get_image())
			icon = _flipped_image_tex

func _toggled(_toggle_mode : bool) -> void:
	if _toggle_mode:
		GDialogue.grid_tool_changed.emit(tool_mode)
		return
	GDialogue.grid_tool_changed.emit(GridEditor.TOOL_MODE.NONE)
	return
