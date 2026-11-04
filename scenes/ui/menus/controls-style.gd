class_name ControlsStyle extends RefCounted
static func theme() -> Theme:
	var result: Theme = preload("res://assets/styles/generic-theme.tres").duplicate(true)
	result.default_font = preload("res://assets/font/Bitter/static/Bitter-Regular.ttf")
	result.default_font_size = 18
	for kind in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("25293b") if kind == "normal" else Color("39445a")
		if kind == "disabled": box.bg_color = Color("202332")
		box.set_corner_radius_all(5)
		box.set_content_margin_all(10)
		box.border_color = Color("b6c9db") if kind == "focus" else Color("b49e70")
		box.set_border_width_all(2 if kind in ["focus", "pressed", "hover_pressed"] else 0)
		result.set_stylebox(kind, "Button", box)
	result.set_color("font_color", "Button", Color("ede9df"))
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", Color.WHITE)
	return result

static func label(parent: Node, text: String, font_size: int = 18) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(callback)
	parent.add_child(node)
	return node
