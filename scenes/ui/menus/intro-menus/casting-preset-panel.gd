class_name CastingPresetPanel extends PanelContainer
signal confirmed(preset: String)
signal backed
var selected := "IJKL"
var submitting := false
var cards: Array[Button] = []
var confirm_button: Button
var message: Label
func _ready() -> void:
	theme = ControlsStyle.theme()
	var backdrop := StyleBoxFlat.new(); backdrop.bg_color = Color("121520")
	add_theme_stylebox_override("panel", backdrop)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER; column.add_theme_constant_override("separation", 24); margin.add_child(column)
	ControlsStyle.label(column, "Choose Your Spellcasting Controls", 30).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ControlsStyle.label(column, "You can change this later in Settings.", 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 24); column.add_child(row)
	for preset in ControlBindings.PRESETS:
		var text := "IJKL — Letter-key casting\n\n       I\n    J  K  L\n\nI = Up · K = Down\nJ = Left · L = Right" if preset == "IJKL" else "WASD — Standard letter-key casting\n\n       W\n    A  S  D\n\nW = Up · S = Down\nA = Left · D = Right"
		var card := ControlsStyle.button(row, text, select.bind(preset))
		card.toggle_mode = true; card.custom_minimum_size = Vector2(330, 230); cards.append(card)
	message = ControlsStyle.label(column, "", 16); message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var footer := HBoxContainer.new(); footer.alignment = BoxContainer.ALIGNMENT_CENTER; footer.add_theme_constant_override("separation", 24); column.add_child(footer)
	ControlsStyle.button(footer, "Back", func(): backed.emit())
	confirm_button = ControlsStyle.button(footer, "Confirm controls", func(): confirmed.emit(selected))
	select(ControlBindings.preset_name(ControlBindings.snapshot()))
	(cards[1] if selected == "WASD" else cards[0]).grab_focus()
func select(preset: String) -> void:
	selected = preset
	for i in cards.size(): cards[i].set_pressed_no_signal(ControlBindings.PRESETS.keys()[i] == preset)
	# Custom is kept until the user explicitly selects and confirms one of the cards.
	confirm_button.disabled = preset == "Custom"
	message.text = "Current controls: Custom. Select a card to replace only the four casting keys." if preset == "Custom" else preset + " selected"
func lock_submission() -> void:
	submitting = true
	for button in find_children("*", "Button"): button.disabled = true
func _unhandled_input(event: InputEvent) -> void:
	if submitting:
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled(); backed.emit()
