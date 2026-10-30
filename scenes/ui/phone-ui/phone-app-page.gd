class_name PhoneAppPage extends Control
signal closed
var page_body: HBoxContainer
var close_button: Button
const INK := Color("24363d")
const MUTED := Color("657477")
const ACCENT := Color("287c72")
const NAVY := Color("1d3039")
func text(value: String, font_size: int = 16, color: Color = INK) -> Label:
	var node := Label.new(); node.text = value; node.add_theme_font_size_override("font_size",font_size); node.add_theme_color_override("font_color",color); return node
func card(color: Color = Color.WHITE) -> PanelContainer:
	var panel := PanelContainer.new(); var box := StyleBoxFlat.new(); box.bg_color = color; box.border_color = Color("e0e5df"); box.set_border_width_all(1); box.set_corner_radius_all(10)
	for edge in ["left","right","top","bottom"]: box.set("content_margin_"+edge,22.0)
	panel.add_theme_stylebox_override("panel",box); return panel
func column(spacing: int = 14) -> VBoxContainer:
	var node := VBoxContainer.new(); node.add_theme_constant_override("separation",spacing); return node
func action(title: String, callback: Callable) -> Button:
	var node := Button.new(); node.text = title; node.pressed.connect(callback); return node
func build_page(title: String, eyebrow: String, subtitle: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://assets/styles/inventory-theme.tres")
	var bg := ColorRect.new(); bg.color = Color("f5f5ef"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var page := column(18); margin.add_child(page)
	var header := HBoxContainer.new(); header.add_theme_constant_override("separation",20); page.add_child(header)
	var titles := column(4); titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(titles)
	titles.add_child(text(eyebrow,12,MUTED)); titles.add_child(text(title,34)); titles.add_child(text(subtitle,14,MUTED))
	close_button = action("Close  ×",_on_back_button_pressed); close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER; header.add_child(close_button)
	page_body = HBoxContainer.new(); page_body.add_theme_constant_override("separation",22); page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL; page.add_child(page_body)
	page.add_child(text("Esc / B  Close     ·     D-pad / arrows  Navigate",12,MUTED))
	close_button.call_deferred("grab_focus")
func _on_back_button_pressed() -> void:
	closed.emit()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit(); get_viewport().set_input_as_handled()
