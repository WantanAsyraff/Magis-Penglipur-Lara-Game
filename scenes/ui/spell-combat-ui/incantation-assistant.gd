class_name IncantationAssistant extends Control

const ICONS := SpellSlot.DIRECTION_TEXTURES
const ICON_SIZE := 64
var player: Player
var dialogue_active: bool = false
var next_row: HBoxContainer
var direction_icons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_row = HBoxContainer.new()
	next_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	next_row.alignment = BoxContainer.ALIGNMENT_CENTER
	next_row.add_theme_constant_override("separation", 16)
	next_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(next_row)
	# Keep four cached icons; input updates only toggle eligible directions.
	for direction in ICONS:
		var icon := TextureRect.new()
		icon.texture = ICONS[direction]
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		next_row.add_child(icon)
		direction_icons[direction] = icon
	hide()

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
	if not is_instance_valid(player):
		hide()
		return
	var keys := player.incantations.get_valid_next_keys()
	for direction in direction_icons:
		direction_icons[direction].visible = direction in keys
	visible = player._in_casting_stance and Player_Global_Data.assistance_mode == 0 and not get_tree().paused and not dialogue_active and not player.get_meta("combat_dead", false) and not keys.is_empty()

func _visibility_changed(_casting: bool) -> void:
	_refresh()

func _mode_changed(_mode: int) -> void:
	_refresh()

func _dialogue_started() -> void:
	dialogue_active = true
	_refresh()

func _dialogue_ended() -> void:
	dialogue_active = false
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()
	if what == NOTIFICATION_UNPAUSED and is_instance_valid(player): _refresh()
