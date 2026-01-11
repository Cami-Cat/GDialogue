@tool
extends EditorPlugin

## ────────────────────────────────────────────────────────────────────────────
## - Define plugin defaults
## ────────────────────────────────────────────────────────────────────────────

const AUTOLOAD_NAME : String = "GDialogue"
const AUTOLOAD_PATH : String = "res://addons/GDialogue/Scripts/Singleton/gdialogue.gd"

## ────────────────────────────────────────────────────────────────────────────
## - Internal variables
## ────────────────────────────────────────────────────────────────────────────

var editor_dock

## ────────────────────────────────────────────────────────────────────────────
## - Perform setup and deconstruction
## ────────────────────────────────────────────────────────────────────────────

func _enable_plugin() -> void:
	construct_autoload()
	pass

func _disable_plugin() -> void:
	destruct_autoload()
	pass

func construct_autoload() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	return

func destruct_autoload() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	return

func _enter_tree() -> void:
	editor_dock = preload("res://addons/GDialogue/Scenes/Grid Editor/grid_editor.tscn").instantiate()
	add_control_to_bottom_panel(editor_dock, "Dialogue Editor")
	pass

func _exit_tree() -> void:
	remove_control_from_bottom_panel(editor_dock)
	pass
