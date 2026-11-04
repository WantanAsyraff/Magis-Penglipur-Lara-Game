extends CPUParticles2D
## Four fixed CPU emitters: 6 accepted-input + 12 idle + 32 flow + 24 release.
@export_range(0.0, 3.0) var intensity_scale := 1.0
@export_range(0.01, 1.0) var direction_gain := 0.18
@export_range(0.05, 2.0) var fade_seconds := 0.35
@export_range(1, 64) var aura_quantity := 12
@export_range(1, 64) var flow_quantity := 32
@export_range(1, 64) var release_quantity := 24
@export_range(0.1, 2.0) var aura_lifetime := 0.8
@export var drift_speed := 35.0
@export var particle_size := 1.0
@export var aura_radius := 65.0
@export var default_colour := Color(0.48, 0.72, 0.9, 0.75)
var bursts := 0
var releases := 0
var buildup := 0.0
var strength := 0.0
var aura: CPUParticles2D
var flow: CPUParticles2D
var release: CPUParticles2D
var player: Player
var active := false
var tint: Color
var last_chain := -1
var preparing := false

func _ready() -> void:
	player = get_parent() as Player
	amount = clampi(amount, 1, 16)
	position = Vector2(0, -25)
	tint = default_colour
	aura = _emitter("IdleAura", aura_quantity, false)
	flow = _emitter("ComboFlow", flow_quantity, false)
	release = _emitter("CastRelease", release_quantity, true)
	release.spread = 180; release.initial_velocity_min = 80; release.initial_velocity_max = 150
	release.lifetime = 0.45
	player.incantation_direction_accepted.connect(_accepted)
	player.ready.connect(_bind, CONNECT_ONE_SHOT)

func _emitter(title: String, count: int, burst: bool) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.name = title; emitter.emitting = false
	emitter.amount = clampi(count, 1, 64); emitter.lifetime = aura_lifetime
	emitter.one_shot = burst; emitter.explosiveness = 1.0 if burst else 0.0
	emitter.texture = texture; emitter.local_coords = false
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE; emitter.emission_sphere_radius = aura_radius
	emitter.direction = Vector2(0, -1); emitter.spread = 90
	emitter.gravity = Vector2(0, -12)
	emitter.initial_velocity_min = drift_speed * 0.4; emitter.initial_velocity_max = drift_speed
	emitter.tangential_accel_min = 10; emitter.tangential_accel_max = 25
	emitter.scale_amount_min = particle_size * 0.6; emitter.scale_amount_max = particle_size
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	emitter.color_ramp = gradient
	add_child(emitter)
	return emitter

func _bind() -> void:
	if not player.is_multiplayer_authority():
		visible = false; set_process(false); return
	Player_Global_Data.casting_changed.connect(_stance)
	player.incantations.changed.connect(_resolver_changed)
	player.casting.request_status.connect(_status)
	player.casting.delivery_succeeded.connect(_completed)
	player.hitbox.died.connect(_clear)
	player.presentation_died.connect(_clear)
	player.casting_cancelled.connect(func(): buildup = 0; preparing = false)
	player.incantation_rejected.connect(func(): buildup *= 0.5)
	_stance(player._in_casting_stance)

func _stance(value: bool) -> void:
	active = value
	if not value: buildup = 0; preparing = false

func _resolver_changed() -> void:
	# Player marks explicit clears/rebuilds as new chains before clearing the resolver.
	# A terminal push clears internally before its accepted signal: retain that charge for launch.
	if player.incantations.get_sequence_snapshot().is_empty() and player._new_chain: buildup = 0

func _accepted(_direction: String) -> void:
	if not player.is_multiplayer_authority(): return
	bursts += 1
	if last_chain != player.incantation_chain_id:
		buildup = 0; last_chain = player.incantation_chain_id
	buildup = minf(1.0, buildup + direction_gain)
	restart()

func _status(_id: int, _chain: int, spell: SpellData, status: SpellCastingComponent.RequestStatus, _reason: String) -> void:
	if status in [SpellCastingComponent.RequestStatus.PREPARING, SpellCastingComponent.RequestStatus.CHANNELING]:
		preparing = true
		tint = spell.spell_colour
		buildup = minf(1.0, buildup + direction_gain)
	elif status in [SpellCastingComponent.RequestStatus.CANCELLED, SpellCastingComponent.RequestStatus.INTERRUPTED]:
		buildup = 0; preparing = false
	elif status == SpellCastingComponent.RequestStatus.FAILED:
		buildup *= 0.5; preparing = false

func _completed(context: SpellCastContext) -> void:
	if not player.is_multiplayer_authority() or player.get_meta("combat_dead", false): return
	releases += 1
	preparing = false
	release.color = context.spell.spell_colour
	# Follow dispatch, not recognition. Each completed prefix may release independently.
	release.position = Vector2(20 * (-1 if player.get_node("PlayerSprite").flip_h else 1), -8)
	release.restart()
	if context.incantation_chain_id == player.incantation_chain_id:
		buildup = buildup * 0.55 if not player.incantations.get_sequence_snapshot().is_empty() else 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	var blocked: bool = player.get_meta("combat_dead", false) or Dialogic.current_timeline != null or QuestOfferDialog.is_open()
	visible = not blocked
	var target := (0.22 + buildup * intensity_scale) if active and not blocked else 0.0
	strength = move_toward(strength, target, delta / maxf(fade_seconds, 0.05))
	aura.emitting = strength > 0.01
	flow.emitting = strength > 0.25
	aura.modulate = Color(default_colour, minf(strength * 2.0, 0.65))
	flow.modulate = Color(tint, clampf(strength - 0.15, 0.0, 0.75))
	# During preparation the same flow emitter gathers near the authored cast marker.
	flow.position = player.castMarker.position * 0.25 if preparing else Vector2.ZERO
	flow.radial_accel_min = -35.0 if preparing else 0.0
	flow.radial_accel_max = -15.0 if preparing else 8.0
	if strength <= 0.01: tint = default_colour

func _clear() -> void:
	active = false; buildup = 0; strength = 0
	emitting = false; aura.emitting = false; flow.emitting = false; release.emitting = false
	hide(); set_process(false)
