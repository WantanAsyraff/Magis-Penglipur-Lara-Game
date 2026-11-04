extends Control
const ROW_SCENE := preload("res://scenes/ui/menus/bind-list.tscn")
const SAVE_PATH := ControlBindings.SAVE_PATH
# Public registry retained for tools and validation.
const ACTIONS := [["move_left"], ["move_right"], ["climb_up"], ["climb_down"], ["jump"], ["dash"], ["block"], ["interact"], ["open_phone"], ["paused"], ["incantation_up"], ["incantation_down"], ["incantation_left"], ["incantation_right"], ["cancel_casting"], ["clear_incantation"], ["start_incantation"], ["pushback"], ["cycle_target"], ["casting_aim_lock"]]
var draft: Dictionary
var category := "Movement"
var advanced := false
var assistance_mode: int
var bind_list: VBoxContainer
var _rows: Array[KeybindRow] = []
var _listening_row: KeybindRow
var _assistance: OptionButton
var status: Label
var section_title: Label
var preset_label: Label
var tabs: Array[Button] = []
var content: VBoxContainer
var _applied := false

func _ready() -> void:
	theme = ControlsStyle.theme()
	draft = ControlBindings.snapshot()
	assistance_mode = Player_Global_Data.assistance_mode
	var bg := ColorRect.new(); bg.color = Color("121520")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	content = VBoxContainer.new(); content.add_theme_constant_override("separation", 14); margin.add_child(content)
	ControlsStyle.label(content, "CONTROLS & INPUT", 30)
	ControlsStyle.label(content, "Customize how you play Magis Penglipur Lara", 16).modulate = Color("b6bccb")
	var navigation := HBoxContainer.new(); content.add_child(navigation)
	for title in ControlBindings.CATEGORIES:
		var button := ControlsStyle.button(navigation, title, _select_category.bind(title))
		button.toggle_mode = true; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.append(button)
	section_title = ControlsStyle.label(content, "", 22)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(scroll)
	bind_list = VBoxContainer.new(); bind_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bind_list.add_theme_constant_override("separation", 8); scroll.add_child(bind_list)
	status = ControlsStyle.label(content, "Select a binding to edit. Keyboard, mouse and controller supported.", 15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation", 12); content.add_child(footer)
	ControlsStyle.button(footer, "Reset section", _reset_section)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; footer.add_child(spacer)
	ControlsStyle.button(footer, "Cancel", _on_cancel)
	ControlsStyle.button(footer, "Apply", _on_save)
	_select_category(category)
	tabs[0].grab_focus()

func _select_category(title: String) -> void:
	_stop_listening()
	category = title
	for button in tabs: button.set_pressed_no_signal(button.text == title)
	section_title.text = title.to_upper()
	_build_rows()

func _build_rows() -> void:
	for child in bind_list.get_children(): bind_list.remove_child(child); child.queue_free()
	_rows.clear()
	if category == "Spellcasting":
		preset_label = ControlsStyle.label(bind_list, "Control preset · " + ControlBindings.preset_name(draft))
		var presets := HBoxContainer.new(); bind_list.add_child(presets)
		for preset in ControlBindings.PRESETS: ControlsStyle.button(presets, preset, _preset.bind(preset))
		var row := HBoxContainer.new(); bind_list.add_child(row)
		ControlsStyle.label(row, "Incantation assistance").size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_assistance = OptionButton.new()
		for title in ["Guided", "Minimal", "Off"]: _assistance.add_item(title)
		_assistance.select(assistance_mode); _assistance.item_selected.connect(func(mode): assistance_mode = mode); row.add_child(_assistance)
	for entry in ControlBindings.CATEGORIES[category]:
		if entry.size() > 2 and not advanced: continue
		if not InputMap.has_action(entry[0]): continue
		var row: KeybindRow = ROW_SCENE.instantiate(); bind_list.add_child(row)
		row.setup(entry[0], entry[1], draft.get(entry[0], []))
		row.rebind_requested.connect(_on_rebind_requested); _rows.append(row)
	# Preserve future/project-specific supported actions in Interface advanced.
	if category == "Interface" and advanced:
		var known := []
		for entries in ControlBindings.CATEGORIES.values():
			for entry in entries: known.append(entry[0])
		for action in draft:
			if action in known: continue
			var row: KeybindRow = ROW_SCENE.instantiate(); bind_list.add_child(row)
			row.setup(action, String(action).capitalize(), draft[action]); row.rebind_requested.connect(_on_rebind_requested); _rows.append(row)
	if category in ["Spellcasting", "Interface"]:
		ControlsStyle.button(bind_list, "Hide advanced options ▴" if advanced else "Show advanced options ▾", func(): advanced = not advanced; _build_rows())

func _preset(preset: String) -> void:
	ControlBindings.set_preset(draft, preset)
	_build_rows()
	status.text = preset + " selected. Apply to save. UI arrow navigation remains available."

func _input(event: InputEvent) -> void:
	if _listening_row == null: return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_stop_listening(); return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		_stop_listening(); return
	if event is InputEventKey:
		if not event.pressed or event.echo or event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]: return
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) < 0.7: return
	elif event is InputEventJoypadButton or event is InputEventMouseButton:
		if not event.pressed: return
	else: return
	var binding: InputEvent = event.duplicate()
	if binding is InputEventKey:
		binding.physical_keycode = event.physical_keycode if event.physical_keycode else event.keycode
		binding.keycode = 0; binding.unicode = 0; binding.pressed = false
	var action := _listening_row.action_name
	var conflicts := ControlBindings.conflicts(draft, action, binding)
	var focus := _listening_row.primary_btn
	_stop_listening()
	if not conflicts.is_empty():
		var dialog := ConfirmationDialog.new(); dialog.title = "Shared binding"
		dialog.dialog_text = "Also assigned to: %s. Keep this shared binding?" % ", ".join(conflicts)
		add_child(dialog)
		dialog.confirmed.connect(func(): _assign(action, binding); dialog.queue_free(); focus.grab_focus())
		dialog.canceled.connect(func(): dialog.queue_free(); focus.grab_focus())
		dialog.popup_centered()
	else: _assign(action, binding)

func _assign(action: String, binding: InputEvent) -> void:
	ControlBindings.replace_family(draft, action, binding)
	for row in _rows:
		row.events = draft[row.action_name]; row.refresh_display()
	if category == "Spellcasting": preset_label.text = "Control preset · " + ControlBindings.preset_name(draft)
	status.text = "Binding updated. Apply to save."

func _on_rebind_requested(row: KeybindRow) -> void:
	_stop_listening(); _listening_row = row; row.set_listening(true)
	status.text = "Press a key, mouse button or controller input. Escape / controller B cancels."
func _stop_listening() -> void:
	if is_instance_valid(_listening_row):
		_listening_row.set_listening(false); _listening_row.primary_btn.grab_focus()
	_listening_row = null
func _reset_section() -> void:
	_stop_listening()
	for entry in ControlBindings.CATEGORIES[category]: draft[entry[0]] = ControlBindings.defaults(entry[0])
	if category == "Spellcasting": assistance_mode = 0
	_build_rows(); status.text = "Section reset in draft. Apply to save."
func _on_save() -> void:
	_stop_listening()
	var error := ControlBindings.save_bindings(draft)
	if error != OK: status.text = "Could not save controls: " + error_string(error); return
	if Player_Global_Data.set_assistance_mode(assistance_mode) != OK:
		status.text = "Could not save assistance preference."; return
	ControlBindings.apply(draft); _applied = true; _go_back()
func _on_cancel() -> void:
	_stop_listening(); _go_back()
func _on_back_button_pressed() -> void:
	_on_cancel()
func _go_back() -> void:
	if Player_Global_Data.previous_scene == "":
		get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/main-menu.tscn")
	else:
		Player_Manager.last_player_position = Player_Global_Data.previous_position
		SceneManager.change_scene(Player_Global_Data.previous_scene)
		Player_Global_Data.p_moveable = true
func _save_to_file(path: String = SAVE_PATH) -> void:
	ControlBindings.save_bindings(draft, path)
static func load_from_file(path: String = SAVE_PATH) -> void:
	ControlBindings.load_bindings(path)
