@tool
class_name History_Entry
extends Control

@export var type: Label 
@export var description: Label 
@export var value_before: Label 
@export var value_after: Label 

func _set_action_data(in_action : GridEditor.Action) -> void:
	type.text = in_action.get_type()
	description.text = in_action.get_description()
	value_before.text = str(in_action.get_data_before())
	value_after.text = str(in_action.get_data_after())
	return
