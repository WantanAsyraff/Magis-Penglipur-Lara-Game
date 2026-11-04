class_name KeybindRow extends HBoxContainer
signal rebind_requested(row)
var action_name := ""
var action_label: Label
var primary_btn: Button
var events: Array = []
func _ready() -> void:
	add_theme_constant_override("separation", 16)
	action_label = ControlsStyle.label(self, "")
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_btn = ControlsStyle.button(self, "Edit", func(): rebind_requested.emit(self))
	primary_btn.custom_minimum_size = Vector2(220, 40)
func setup(action: String, display_name: String, bindings: Array = []) -> void:
	action_name = action
	action_label.text = display_name
	events = bindings
	refresh_display()
func refresh_display() -> void:
	var labels := PackedStringArray()
	for event in events:
		if event is InputEventKey:
			labels.append(event.as_text_physical_keycode() if event.physical_keycode else event.as_text_keycode())
		else: labels.append(event.as_text())
	primary_btn.text = " · ".join(labels) if not labels.is_empty() else "Unassigned · Edit"
	primary_btn.tooltip_text = primary_btn.text + " — Select to edit"
func set_listening(active: bool) -> void:
	if active: primary_btn.text = "Press input · Esc cancels"
	else: refresh_display()
static func _get_key_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty(): return "—"
	var event := events[0]
	if event is InputEventKey and event.physical_keycode: return event.as_text_physical_keycode()
	return event.as_text()
