extends Control
var creating := false
var selected_profile := 1
var selected_kind := "manual"
var list: VBoxContainer
var details: Label
var status: Label
var name_input: LineEdit
var action: Button
var recover: Button
var remove: Button
var import_button: Button
var buttons: Array[Button] = []
var rows: Array[Dictionary] = []

func _ready() -> void:
	theme = preload("res://assets/styles/generic-theme.tres")
	var bg := ColorRect.new()
	bg.color = Color("121320")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,48)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",20)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = "NEW GAME" if creating else "LOAD GAME"
	heading.add_theme_font_size_override("font_size",42)
	content.add_child(heading)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",32)
	content.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",12)
	scroll.add_child(list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",16)
	columns.add_child(right)
	if creating:
		name_input = LineEdit.new()
		name_input.placeholder_text = "Character name"
		name_input.max_length = 64
		name_input.custom_minimum_size.y = 54
		right.add_child(name_input)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(details)
	action = _button(right,"BEGIN" if creating else "CONTINUE",_activate)
	recover = _button(right,"RECOVER PREVIOUS BACKUP",_recover)
	remove = _button(right,"DELETE SELECTED SAVE",_delete)
	import_button = _button(right,"IMPORT LEGACY QUEST V2",_import)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)
	_button(content,"BACK",func(): get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/main-menu.tscn"))
	for profile in range(1,4):
		for kind in (["manual"] if creating else ["manual","auto"]):
			var button := _button(list,"",_select.bind(profile,kind))
			button.toggle_mode = true
			buttons.append(button)
			rows.append({"profile":profile,"kind":kind})
	# Continue selects the most recently saved valid snapshot, including autosaves.
	if not creating:
		var newest: float = -1
		for row in rows:
			var info := SaveManager.inspect_slot(row.profile,row.kind)
			if info.state == "valid" and info.timestamp > newest:
				newest = info.timestamp
				selected_profile = row.profile
				selected_kind = row.kind
	_refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	for i in rows.size():
		if rows[i].profile == selected_profile and rows[i].kind == selected_kind:
			buttons[i].grab_focus()
			scroll.ensure_control_visible(buttons[i])

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.clip_text = true
	button.custom_minimum_size.y = 58
	button.add_theme_font_size_override("font_size",24)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _select(profile: int, kind: String) -> void:
	selected_profile = profile
	selected_kind = kind
	_refresh()

func _description(info: Dictionary) -> String:
	if info.state != "valid": return String(info.state).capitalize()
	return "%s · Level %d\n%s\n%d min played · %s" % [info.name,info.level,info.location,int(info.playtime/60),Time.get_datetime_string_from_unix_time(int(info.timestamp)).replace("T"," ")+" UTC"]

func _refresh() -> void:
	for i in buttons.size():
		var row := rows[i]
		var info := SaveManager.inspect_slot(row.profile,row.kind)
		buttons[i].text = "Profile %d · %s\n%s" % [row.profile,"Manual" if row.kind == "manual" else "Autosave",_description(info)]
		buttons[i].set_pressed_no_signal(row.profile == selected_profile and row.kind == selected_kind)
	var selected := SaveManager.inspect_slot(selected_profile,selected_kind)
	details.text = "Profile %d · %s\n\n%s" % [selected_profile,selected_kind.capitalize(),_description(selected)]
	if creating: details.text += "\n\nStarts with the authored new-game defaults. Replacing a profile archives its manual save and autosave."
	action.disabled = not creating and selected.state != "valid"
	recover.visible = not creating and SaveManager.inspect_slot(selected_profile,selected_kind,true).state == "valid"
	remove.visible = not creating
	remove.disabled = selected.state == "empty" and not recover.visible
	import_button.visible = creating and SaveManager.legacy_available() and selected.state == "empty" and SaveManager.inspect_slot(selected_profile,"auto").state == "empty"

func _confirm(title: String, text: String, callback: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	add_child(dialog)
	dialog.confirmed.connect(func(): callback.call(); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _activate() -> void:
	if creating:
		var occupied := false
		for kind in ["manual","auto"]:
			for backup in [false,true]: occupied = occupied or SaveManager.inspect_slot(selected_profile,kind,backup).state != "empty"
		if occupied:
			_confirm("Replace profile?","Archive and replace BOTH saves for profile %d? Other profiles are preserved." % selected_profile,_begin.bind(true))
		else: _begin(false)
	else: _load(false)

func _begin(overwrite: bool) -> void:
	action.disabled = true
	var success := await SaveManager.new_game(selected_profile,name_input.text,overwrite)
	if is_instance_valid(self) and not success:
		status.text = SaveManager.last_error
		action.disabled = false

func _load(backup: bool) -> void:
	action.disabled = true
	var success := await SaveManager.load_slot(selected_profile,selected_kind,backup)
	if is_instance_valid(self) and not success:
		status.text = SaveManager.last_error
		_refresh()

func _recover() -> void:
	_confirm("Recover backup?","Load the previous valid save? The damaged file will be preserved. Delete it explicitly before saving to that destination again.",_load.bind(true))

func _delete() -> void:
	_confirm("Delete selected save?","Delete profile %d %s and its backup? This cannot be undone. The other save and profiles are preserved." % [selected_profile,selected_kind],func():
		status.text = "Save deleted." if SaveManager.delete_slot(selected_profile,selected_kind) else SaveManager.last_error
		_refresh())

func _import() -> void:
	_confirm("Import legacy progress?","Import Quest V2 into this empty profile? Position and academic fields use safe new-game defaults. The original file is preserved.",func():
		status.text = "Legacy progress imported. Open Load Game to continue." if SaveManager.import_legacy(selected_profile) else SaveManager.last_error
		_refresh())
