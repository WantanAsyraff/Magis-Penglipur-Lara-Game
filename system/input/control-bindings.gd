class_name ControlBindings extends RefCounted
## Application preferences. Editor drafts never mutate the live InputMap.
const SAVE_PATH := "user://keybinds.cfg"
const CAST_ACTIONS := ["incantation_up", "incantation_down", "incantation_left", "incantation_right"]
const PRESETS := {"IJKL": [KEY_I, KEY_K, KEY_J, KEY_L], "Arrow Keys": [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]}
const CATEGORIES := {
	"Movement": [["move_left", "Move left"], ["move_right", "Move right"], ["climb_up", "Climb up"], ["climb_down", "Climb down"], ["jump", "Jump"], ["dash", "Dash"]],
	"Combat": [["block", "Block / Parry"], ["start_incantation", "Casting stance"], ["pushback", "Push enemies"], ["cycle_target", "Next enemy target"]],
	"Spellcasting": [["incantation_up", "Cast up"], ["incantation_down", "Cast down"], ["incantation_left", "Cast left"], ["incantation_right", "Cast right"], ["cancel_casting", "Cancel active cast / queue", true], ["clear_incantation", "Clear sequence", true], ["casting_aim_lock", "Stop movement", true]],
	"Interface": [["interact", "Interact"], ["open_phone", "Phone"], ["toggle_repertoire", "Show / hide repertoire"], ["paused", "Pause"]]
}
const EVENT_TYPES := ["InputEventKey", "InputEventJoypadButton", "InputEventJoypadMotion", "InputEventMouseButton", "InputEventMouseMotion", "InputEventAction", "InputEventScreenTouch", "InputEventScreenDrag", "InputEventMagnifyGesture", "InputEventPanGesture"]

static func snapshot() -> Dictionary:
	var result := {}
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			result[action] = InputMap.action_get_events(action).duplicate(true)
	return result

static func apply(bindings: Dictionary) -> void:
	for action in bindings:
		if not InputMap.has_action(action): continue
		InputMap.action_erase_events(action)
		for event in bindings[action]:
			if event is InputEvent: InputMap.action_add_event(action, event)

static func defaults(action: String) -> Array:
	return ProjectSettings.get_setting("input/" + action, {"events": []}).events.filter(func(e): return e is InputEvent)

static func set_preset(bindings: Dictionary, preset: String) -> void:
	if not PRESETS.has(preset): return
	for i in CAST_ACTIONS.size():
		var action: String = CAST_ACTIONS[i]
		var events: Array = bindings.get(action, []).filter(func(e): return not e is InputEventKey)
		var key := InputEventKey.new()
		key.device = -1
		key.physical_keycode = PRESETS[preset][i]
		events.push_front(key)
		bindings[action] = events

static func preset_name(bindings: Dictionary) -> String:
	for preset in PRESETS:
		var matches := true
		for i in CAST_ACTIONS.size():
			var keys: Array = bindings.get(CAST_ACTIONS[i], []).filter(func(e): return e is InputEventKey)
			if keys.size() != 1:
				matches = false
				break
			var key: InputEventKey = keys[0]
			if (key.physical_keycode if key.physical_keycode else key.keycode) != PRESETS[preset][i] or key.alt_pressed or key.ctrl_pressed or key.shift_pressed or key.meta_pressed:
				matches = false
		if matches: return preset
	return "Custom"

static func replace_family(bindings: Dictionary, action: String, event: InputEvent) -> void:
	var keyboard := event is InputEventKey
	var controller := event is InputEventJoypadButton or event is InputEventJoypadMotion
	var kept: Array = []
	for old in bindings.get(action, []):
		if keyboard and old is InputEventKey: continue
		if controller and (old is InputEventJoypadButton or old is InputEventJoypadMotion): continue
		if event is InputEventMouseButton and old is InputEventMouseButton: continue
		kept.append(old)
	kept.push_front(event)
	bindings[action] = kept

static func conflicts(bindings: Dictionary, action: String, event: InputEvent) -> PackedStringArray:
	var result := PackedStringArray()
	for other in bindings:
		if other == action: continue
		for old in bindings[other]:
			if old.is_match(event) or (old is InputEventKey and event is InputEventKey and (old.physical_keycode if old.physical_keycode else old.keycode) == (event.physical_keycode if event.physical_keycode else event.keycode) and old.get_modifiers_mask() == event.get_modifiers_mask()):
				result.append(other)
				break
	return result

static func encode(event: InputEvent) -> Dictionary:
	var data := {"type": event.get_class()}
	for property in event.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE and property.name not in ["script", "resource_path", "resource_name", "resource_local_to_scene"]:
			data[property.name] = event.get(property.name)
	return data

static func decode(data: Variant) -> InputEvent:
	if data is int:
		var key := InputEventKey.new(); key.keycode = data; return key
	if not data is Dictionary: return null
	var type: String = data.get("type", "InputEventKey")
	if type not in EVENT_TYPES: return null
	var event := ClassDB.instantiate(type) as InputEvent
	for property in event.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE and property.name not in ["script", "resource_path", "resource_name", "resource_local_to_scene"] and data.has(property.name):
			event.set(property.name, data[property.name])
	return event

static func save_bindings(bindings: Dictionary, path: String = SAVE_PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("format", "version", 2)
	for action in bindings:
		var events: Array = []
		for event in bindings[action]: events.append(encode(event))
		cfg.set_value("keybinds", action, events)
	var error := cfg.save(path + ".tmp")
	if error != OK: return error
	return DirAccess.rename_absolute(path + ".tmp", path)

static func load_bindings(path: String = SAVE_PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or not cfg.has_section("keybinds"): return
	var bindings := snapshot()
	var legacy := int(cfg.get_value("format", "version", 1)) < 2
	for action in cfg.get_section_keys("keybinds"):
		if not InputMap.has_action(action): continue
		# Old files contain keyboards only. Keep the authored nonkeyboard mappings.
		var events: Array = bindings.get(action, []).filter(func(e): return legacy and not e is InputEventKey)
		for data in cfg.get_value("keybinds", action, []):
			var event := decode(data)
			if event: events.append(event)
		bindings[action] = events
	apply(bindings)
