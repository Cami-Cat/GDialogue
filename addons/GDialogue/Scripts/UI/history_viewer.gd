@tool
class_name HistoryViewer
extends Control

## ────────────────────────────────────────────────────────────────────────────
## - Scene references
## ────────────────────────────────────────────────────────────────────────────

const ACTION_SCENE : PackedScene = preload("res://addons/GDialogue/Scenes/UI/history_entry.tscn")

## ────────────────────────────────────────────────────────────────────────────
## - Connected Nodes
## ────────────────────────────────────────────────────────────────────────────

@onready var action_container: VBoxContainer = $"ScrollContainer/Action Container"
@onready var empty_label: Label = $"Panel/Empty Label"

## ────────────────────────────────────────────────────────────────────────────
## - Internal Variables
## ────────────────────────────────────────────────────────────────────────────

var can_hide : bool = true

## ────────────────────────────────────────────────────────────────────────────
## - Perform Setup
## ────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	z_index = 4096
	y_sort_enabled = true

	# Perform initial history setup
	_get_data()
	return

func _connect_signals() -> void:
	GDialogue.add_action_to_history.connect(_history_updated)
	GDialogue.got_history_list.connect(_get_data)
	return

## ────────────────────────────────────────────────────────────────────────────
## - History Updates
## ────────────────────────────────────────────────────────────────────────────

func _history_updated(in_action : GridEditor.Action) -> void:
	create_action_display(in_action)
	return

func _get_data(in_history : GridEditor.History = null) -> void:
	# We'll check for history being parsed, if there is none then we'll try to grab a history list.
	# The history list can be empty, this just ensures that there's an object to listen to.
	if !in_history:
		GDialogue.get_history_list.emit()
		return
	for action in in_history._actions:
		create_action_display(action)
	return

func create_action_display(in_action : GridEditor.Action) -> void:
	# Instantiate the scene for each "action."
	var action : History_Entry = ACTION_SCENE.instantiate()

	# Update the data of the action.
	action._set_action_data(in_action)
	
	action_container.add_child(action)
	# Once an action is added, hide the "empty_label" node.
	if empty_label.visible == true && action_container.get_children().size() > 0:
		empty_label.visible = false
	return
