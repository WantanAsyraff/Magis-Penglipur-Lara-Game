extends Control


# -------------------------
# SCENE REFS
# -------------------------
@onready var bind_list      : VBoxContainer = %BindList
@onready var save_btn       : Button        = %SaveButton
@onready var cancel_btn     : Button        = %CancelButton
@onready var reset_all_btn  : Button        = %ResetAllButton

const ROW_SCENE := preload("res://scenes/ui/menus/bind-list.tscn")

# -------------------------
# ACTION REGISTRY
# Tuples: [ action_string, display_name, group_header_or_empty ]
# A non-empty group string inserts a separator label above that row.
# -------------------------
const ACTIONS: Array = [
	# ── Movement ──────────────────────────────────────────────
	["move_left",           "Move Left",            "Movement"],
	["move_right",          "Move Right",           ""],
	["climb_up",            "Climb Up",             ""],
	["climb_down",          "Climb Down",           ""],
	# ── Core ──────────────────────────────────────────────────
	["jump",                "Jump",                 "Core"],
	["dash",                "Dash",                 ""],
	["block",               "Block / Parry",        ""],
	["interact",            "Interact",             ""],
	["open_phone",          "Open Phone",           ""],
	["paused",              "Pause",                ""],
	# ── Incantation ───────────────────────────────────────────
	["incantation_up",      "Incantation ↑",        "Incantation"],
	["incantation_down",    "Incantation ↓",        ""],
	["incantation_left",    "Incantation ←",        ""],
	["incantation_right",   "Incantation →",        ""],
	["cancel_casting",      "Cancel Active Cast / Queue", ""],
	["clear_incantation",   "Clear Incantation",    ""],
	# ── Combat / Casting ──────────────────────────────────────
	["start_incantation",   "Toggle Casting Stance","Combat & Casting"],
	["casting_aim_lock",    "Aim Lock / Stop Mode", ""],
]
# -------------------------
# STATE
# -------------------------
var _assistance: OptionButton
var _rows           : Array[KeybindRow] = []
var _listening_row  : KeybindRow        = null
var _saved_snapshot : Dictionary        = {}   # action → Array[InputEvent]

# -------------------------
# LIFECYCLE
# -------------------------
func _ready() -> void:
	print(bind_list) 
	_snapshot_current_binds()
	_build_rows()

	save_btn.pressed.connect(_on_save)
	cancel_btn.pressed.connect(_on_cancel)
	reset_all_btn.pressed.connect(_on_reset_all)

func _input(event: InputEvent) -> void:
	if _listening_row == null:
		return

	# Ignore non-key events and modifier-only presses
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	var key_event := event as InputEventKey
	if key_event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return

	# Escape cancels rebind without changing anything
	if key_event.keycode == KEY_ESCAPE:
		_stop_listening()
		return

	get_viewport().set_input_as_handled()

	# Apply the new binding
	var action := _listening_row.action_name
	InputMap.action_erase_events(action)
	var new_event := InputEventKey.new()
	new_event.keycode = key_event.keycode
	InputMap.action_add_event(action, new_event)

	_stop_listening()

# -------------------------
# BUILD
# -------------------------
func _build_rows() -> void:
	# Clear any existing rows (e.g. on re-open)
	for child in bind_list.get_children():
		child.queue_free()
	_rows.clear()

	var assistance_label := Label.new()
	assistance_label.text = "Incantation assistance"
	bind_list.add_child(assistance_label)
	_assistance = OptionButton.new()
	for title in ["Guided", "Minimal", "Off"]: _assistance.add_item(title)
	_assistance.select(Player_Global_Data.assistance_mode)
	bind_list.add_child(_assistance)

	for entry in ACTIONS:
		var action_str   : String = entry[0]
		var display_name : String = entry[1]
		var group_header : String = entry[2]

		# Section label
		if group_header != "":
			var sep := HSeparator.new()
			bind_list.add_child(sep)
			var lbl := Label.new()
			lbl.text = group_header.to_upper()
			lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
			lbl.add_theme_font_size_override("font_size", 11)
			bind_list.add_child(lbl)

		# Skip actions not registered in the InputMap
		if not InputMap.has_action(action_str):
			continue

		var row : KeybindRow = ROW_SCENE.instantiate()
		bind_list.add_child(row)
		row.setup(action_str, display_name)
		row.rebind_requested.connect(_on_rebind_requested)
		_rows.append(row)

# -------------------------
# LISTENING
# -------------------------
func _on_rebind_requested(row: KeybindRow) -> void:
	# If another row was listening, cancel it first
	if _listening_row != null and _listening_row != row:
		_listening_row.set_listening(false)

	_listening_row = row
	row.set_listening(true)

func _stop_listening() -> void:
	if _listening_row:
		_listening_row.set_listening(false)
		_listening_row = null

# -------------------------
# SAVE / CANCEL / RESET
# -------------------------
func _on_save() -> void:
	_stop_listening()
	Player_Global_Data.set_assistance_mode(_assistance.selected)
	_save_to_file()
	_snapshot_current_binds()
	_go_back()

func _on_cancel() -> void:
	_stop_listening()
	_restore_snapshot()
	for row in _rows:
		row.refresh_display()
	_go_back()

func _go_back() -> void:
	print("Current scene, ", Player_Global_Data.current_scene)
	print("Previous scene, ", Player_Global_Data.previous_scene)
	if Player_Global_Data.previous_scene == "":
		get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/main-menu.tscn")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	print("Position, ", Player_Global_Data.previous_position)
	Player_Global_Data.p_moveable = true

func _on_reset_all() -> void:
	_stop_listening()
	_assistance.select(0)
	for row in _rows:
		row.reset_to_default()

# -------------------------
# PERSISTENCE
# -------------------------
const SAVE_PATH := "user://keybinds.cfg"

func _snapshot_current_binds() -> void:
	_saved_snapshot.clear()
	for entry in ACTIONS:
		var action: String = entry[0]
		if InputMap.has_action(action):
			_saved_snapshot[action] = InputMap.action_get_events(action).duplicate(true)

func _restore_snapshot() -> void:
	for action in _saved_snapshot:
		InputMap.action_erase_events(action)
		for event in _saved_snapshot[action]:
			InputMap.action_add_event(action, event)

func _save_to_file() -> void:
	var cfg := ConfigFile.new()
	for entry in ACTIONS:
		var action: String = entry[0]
		if not InputMap.has_action(action):
			continue
		var keycodes: Array[Dictionary] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				keycodes.append({"keycode": event.keycode, "physical_keycode": event.physical_keycode})
		cfg.set_value("keybinds", action, keycodes)
	cfg.save(SAVE_PATH)

func _on_back_button_pressed() -> void:
	_go_back()

## Call this from your game's boot/autoload to restore saved binds on startup.
static func load_from_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for action in (cfg.get_section_keys("keybinds") if cfg.has_section("keybinds") else []):
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for keycode in cfg.get_value("keybinds", action, []):
			var event := InputEventKey.new()
			if keycode is Dictionary:
				event.keycode = int(keycode.get("keycode", 0))
				event.physical_keycode = int(keycode.get("physical_keycode", 0))
			else:
				event.keycode = int(keycode)
			InputMap.action_add_event(action, event)
