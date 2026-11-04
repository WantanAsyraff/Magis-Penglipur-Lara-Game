class_name IncantationAssistant extends Control
const ICONS := SpellSlot.DIRECTION_TEXTURES
const ICON_SIZE := 28
const ARROWS := {"up": "↑", "down": "↓", "left": "←", "right": "→"}
@export_range(1, 4) var max_paths := 4
@export var fallback_icon: Texture2D = preload("res://assets/temp/temp-mana.png")
var player: Player
var dialogue_active := false
var next_row: HBoxContainer
# Read-only compatibility snapshot for callers that inspect eligible next keys.
var direction_icons: Dictionary = {}
var views: Array[Dictionary] = []
var shown_spells: Array[SpellData] = []
var overflow: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_row = HBoxContainer.new(); next_row.alignment = BoxContainer.ALIGNMENT_CENTER
	next_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	next_row.add_theme_constant_override("separation", 18); next_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(next_row)
	for direction in ICONS:
		var icon := TextureRect.new(); icon.texture = ICONS[direction]
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		direction_icons[direction] = icon
	for i in max_paths:
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 4); next_row.add_child(column)
		var path := RichTextLabel.new(); path.bbcode_enabled = true; path.fit_content = true
		path.scroll_active = false; path.custom_minimum_size.x = 138
		path.add_theme_font_size_override("normal_font_size", 22)
		column.add_child(path)
		var icon := TextureRect.new(); icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; column.add_child(icon)
		var title := Label.new(); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 13); title.custom_minimum_size.x = 138
		title.clip_text = true; column.add_child(title)
		views.append({"column": column, "path": path, "icon": icon, "title": title})
		for control in [column, path, icon, title]: control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overflow = Label.new(); overflow.mouse_filter = Control.MOUSE_FILTER_IGNORE; next_row.add_child(overflow)
	next_row.minimum_size_changed.connect(_layout_height)
	hide()

func _layout_height() -> void:
	offset_top = offset_bottom - maxf(110.0, next_row.get_combined_minimum_size().y)

func bind_player(actor: Player) -> void:
	player = actor
	player.incantations.changed.connect(_refresh)
	Player_Global_Data.casting_changed.connect(_visibility_changed)
	Player_Global_Data.assistance_changed.connect(_mode_changed)
	player.hitbox.died.connect(hide)
	Dialogic.timeline_started.connect(_dialogue_started)
	Dialogic.timeline_ended.connect(_dialogue_ended)
	_refresh()

func _refresh() -> void:
	if not is_inside_tree() or not is_instance_valid(player): hide(); return
	var sequence := player.incantations.get_sequence_snapshot()
	var spells := player.incantations.get_matching_spells()
	var exact := player.incantations.get_current_exact_match()
	if exact:
		spells.erase(exact); spells.push_front(exact)
	shown_spells.clear()
	var minimal := Player_Global_Data.assistance_mode == 1
	var limit := mini(max_paths, 2) if minimal else max_paths
	for i in views.size():
		var view := views[i]
		view.column.visible = i < mini(limit, spells.size())
		if not view.column.visible: continue
		var spell: SpellData = spells[i]; shown_spells.append(spell)
		var parts := PackedStringArray()
		var first := maxi(0, sequence.size() - 2) if minimal else 0
		var last := mini(spell.spell_incantation.size(), first + 5) if minimal else spell.spell_incantation.size()
		for index in range(first, last):
			var arrow: String = ARROWS.get(spell.spell_incantation[index], "?")
			parts.append("[b][u]" + arrow + "[/u][/b]" if index < sequence.size() else "[color=#8891a6]" + arrow + "[/color]")
		# Wrap long authored incantations into readable rows without widening the HUD.
		var columns := 8 if not minimal and spells.size() == 1 and spell.spell_incantation.size() > 8 else 5
		view.path.custom_minimum_size.x = 240 if columns == 8 else 138
		var path_text := "… " if first > 0 else ""
		for index in parts.size():
			path_text += parts[index] + ("\n" if (index + 1) % columns == 0 else " ")
		if last < spell.spell_incantation.size(): path_text += " …"
		view.path.text = "[center]" + ("✓ " if spell == exact else "") + path_text + "[/center]"
		view.icon.texture = spell.spell_icon if spell.spell_icon else fallback_icon
		view.title.text = ("✓ " if spell == exact else "") + spell.spell_name
		view.title.visible = not minimal
	for direction in direction_icons: direction_icons[direction].visible = direction in player.incantations.get_valid_next_keys()
	overflow.text = "+%d" % (spells.size() - limit) if spells.size() > limit else ""
	visible = player._in_casting_stance and Player_Global_Data.assistance_mode != 2 and not get_tree().paused and not dialogue_active and not player.get_meta("combat_dead", false) and not spells.is_empty()

func _visibility_changed(_casting: bool) -> void: _refresh()
func _mode_changed(_mode: int) -> void: _refresh()
func _dialogue_started() -> void:
	dialogue_active = true; _refresh()
func _dialogue_ended() -> void:
	dialogue_active = false; _refresh()
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()
	if what == NOTIFICATION_UNPAUSED and is_instance_valid(player): _refresh()
func _exit_tree() -> void:
	for icon in direction_icons.values(): icon.free()
