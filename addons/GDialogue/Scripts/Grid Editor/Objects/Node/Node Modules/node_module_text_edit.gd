class_name NodeModuleTextEdit
extends NodeModule

func _init() -> void:
	title_text = "Dialogue Contents"
	super()
	return

func _ready() -> void:
	super()
	_create_text_edit()
	return

func _create_text_edit() -> void:
	if !is_node_ready() : await ready
	
	# Contruct the text edit and add it as a child
	var _text_edit = TextEdit.new()
	
	add_child(_text_edit)
	
	# We then set it to fill the control's space and force the text to wrap.
	# Without wrapping, it would look odd.
	_text_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

	return
