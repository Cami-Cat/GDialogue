@tool
class_name HistoryButton
extends GridButton

const HISTORY_VIEWER : PackedScene = preload("res://addons/GDialogue/Scenes/UI/history_viewer.tscn")
var history_viewer : HistoryViewer

func _ready() -> void:
	toggled.connect(_button_toggled)
	toggle_mode = true
	return

func _button_toggled(is_toggled : bool) -> void:
	if is_toggled:
		_display_history()
	else:
		_hide_history()
	return 

func _display_history() -> void:
	if history_viewer:
		history_viewer.visible = true
		return
	_construct_history_viewer()
	history_viewer.visible = true
	return

func _construct_history_viewer() -> void:
	history_viewer = HISTORY_VIEWER.instantiate()
	get_owner().add_child(history_viewer)
	return
	
func _hide_history() -> void:
	if history_viewer:
		if history_viewer.can_hide:
			history_viewer.visible = false
	return
