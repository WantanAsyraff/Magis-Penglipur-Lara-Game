class_name BossHealthBar extends Control
var boss: Boss
@onready var name_label: Label = %BossName
@onready var health_label: Label = %BossHealth
@onready var phase_label: Label = %BossPhase
@onready var bar: ProgressBar = %BossBar
@onready var announcement: Label = %Announcement
@onready var announcement_timer: Timer = $AnnouncementTimer

func _ready() -> void:
	get_viewport().size_changed.connect(_layout_header)
	_layout_header()
	announcement_timer.timeout.connect(func(): announcement.text = "")

func bind_boss(actor: Boss) -> void:
	boss = actor
	name_label.text = boss.boss_name
	boss.boss_hurt.connect(_refresh)
	boss.phase_changed.connect(_phase_changed)
	boss.boss_died.connect(_refresh)
	_refresh()
	_update_phase()

func _refresh(_amount: float = 0) -> void:
	if not is_instance_valid(boss): return
	bar.max_value = boss.max_health
	bar.value = boss.current_health
	health_label.text = "%.0f / %.0f" % [boss.current_health, boss.max_health]

func _update_phase() -> void:
	if not is_instance_valid(boss) or boss.current_phase == null: return
	phase_label.text = "Phase %d · %s" % [boss.current_phase_index + 1, boss.current_phase.phase_name]
	var fill := StyleBoxFlat.new()
	fill.bg_color = boss.current_phase.phase_colour
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fill)
	_refresh()

func _phase_changed(_index: int, phase: BossPhaseData) -> void:
	_update_phase()
	announcement.text = phase.phase_name + " — phase transition"
	announcement.modulate = phase.phase_colour
	announcement_timer.start(maxf(phase.transition_duration, phase.transition_invincible_duration))

func _layout_header() -> void:
	# Keep the boss header clear of the player's stats and adjacent effect icons.
	var width := get_viewport_rect().size.x
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	if width >= 1000:
		size = Vector2(minf(640,width-702),112)
		position = Vector2(width-size.x-24,12)
	else:
		size = Vector2(minf(600,width-48),112)
		position = Vector2(24,320 if width < 750 else 300)
