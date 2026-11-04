class_name IncantationAssistant extends Control
const ICONS := SpellSlot.DIRECTION_TEXTURES
const ICON_SCALE := 1.15 * 1.30
const ICON_SIZE := 28 * ICON_SCALE
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
	next_row.add_theme_constant_override("separation", 36); next_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(next_row)
	for direction in ICONS:
		var icon := TextureRect.new(); icon.texture = ICONS[direction]
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		direction_icons[direction] = icon
	for i in max_paths:
		var column := VBoxContainer.new(); column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 10); next_row.add_child(column)
		var icon_row := VBoxContainer.new(); icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		icon_row.add_theme_constant_override("separation", 10); column.add_child(icon_row)
		var key_icon := TextureRect.new(); key_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		key_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon_row.add_child(key_icon)
		var icon := TextureRect.new(); icon.custom_minimum_size = Vector2(26, 26) * ICON_SCALE
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon_row.add_child(icon)
		var title := Label.new(); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 13); title.custom_minimum_size.x = 138
		title.clip_text = true; column.add_child(title)
		views.append({"column": column, "icon": icon, "title": title, "key_icon": key_icon})
		for control in [column, icon_row, key_icon, icon, title]: control.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# Completed prefixes belong to cooldown history; hints show only future combos.
	spells = spells.filter(func(spell): return spell.spell_incantation.size() > sequence.size())
	var exact := player.incantations.get_current_exact_match()
	shown_spells.clear()
	var minimal := Player_Global_Data.assistance_mode == 1
	var limit := mini(max_paths, 2) if minimal else max_paths
	for i in views.size():
		var view := views[i]
		view.column.visible = i < mini(limit, spells.size())
		if not view.column.visible: continue
		var spell: SpellData = spells[i]; shown_spells.append(spell)
		view.key_icon.texture = ICONS.get(spell.spell_incantation[sequence.size()])
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
