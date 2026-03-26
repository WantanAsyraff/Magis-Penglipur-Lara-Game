# KeybindRow.gd
class_name KeybindRow
extends HBoxContainer

signal rebind_requested(row)

@onready var action_label : Label  = $ActionLabel
@onready var primary_btn  : Button = $PrimaryBtn
@onready var reset_btn    : Button = $ResetRowBtn

var action_name : String = ""
var _listening  : bool   = false

func setup(p_action_name: String, display_name: String) -> void:
	action_name = p_action_name
	action_label.text = display_name
	refresh_display()

func refresh_display() -> void:
	if not primary_btn:
		return
	primary_btn.text = _get_key_label(action_name)
	primary_btn.modulate = Color.WHITE

func reset_to_default() -> void:
	InputMap.action_erase_events(action_name)
	for event in ProjectSettings.get_setting("input/" + action_name).events:
		InputMap.action_add_event(action_name, event)
	refresh_display()

func set_listening(active: bool) -> void:
	_listening = active
	if active:
		primary_btn.text = "[ press a key ]"
		primary_btn.modulate = Color(1.0, 0.85, 0.3)
	else:
		refresh_display()

func _ready() -> void:
	primary_btn.pressed.connect(func(): rebind_requested.emit(self))
	reset_btn.pressed.connect(reset_to_default)
	refresh_display()  # ← catches any label set before _ready fired

static func _get_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.as_text_keycode()
		elif event is InputEventMouseButton:
			return "Mouse %d" % event.button_index
		elif event is InputEventJoypadButton:
			return "Pad %d" % event.button_index
	return "—"
