class_name MagicProjectile extends Area2D



# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var spell_data: SpellData = null
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 5.0

var _dot_timer: float = 0.0
var _dot_elapsed: float = 0.0
var _mana_drain_elapsed: float = 0.0
var _slow_elapsed: float = 0.0
var _hit_bodies: Array = []       # For piercing — track already-hit bodies
var _particle_instance: GPUParticles2D

# ─────────────────────────────────────────
# READY
# ─────────────────────────────────────────
func _ready() -> void:
	if not spell_data:
		push_warning("MagicProjectile: no spell_data assigned.")
		queue_free()
		return

	_apply_visuals()
	_apply_lifetime()
	_apply_colour()

	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _apply_visuals() -> void:
	if spell_data.projectile_texture:
		$Sprite2D.texture = spell_data.projectile_texture
	$Sprite2D.scale = Vector2.ONE * spell_data.projectile_size

	if spell_data.projectile_particles:
		_particle_instance = spell_data.projectile_particles.instantiate()
		add_child(_particle_instance)
		_particle_instance.emitting = true

func _apply_lifetime() -> void:
	# Derive lifetime from range and speed so it naturally expires at max range
	if spell_data.projectile_speed > 0:
		lifetime = spell_data.projectile_range / spell_data.projectile_speed
	else:
		lifetime = 5.0

func _apply_colour() -> void:
	$Sprite2D.modulate = spell_data.spell_colour

# ─────────────────────────────────────────
# PHYSICS
# ─────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if spell_data.projectile_speed > 0:
		position += direction * spell_data.projectile_speed * delta

	lifetime -= delta
	if lifetime <= 0:
		queue_free()

# ─────────────────────────────────────────
# HIT
# ─────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	# Piercing — don't re-hit the same body
	if spell_data.piercing and body in _hit_bodies:
		return
	_hit_bodies.append(body)

	_apply_damage(body)
	_apply_knockback(body)
	_apply_stun(body)
	_apply_dot(body)
	_apply_slow(body)
	_apply_mana_drain(body)
	_apply_silence(body)
	_apply_aoe()
	_spawn_impact_particles()

	if not spell_data.piercing:
		queue_free()

# ─────────────────────────────────────────
# DAMAGE & EFFECTS
# ─────────────────────────────────────────
func _apply_damage(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(spell_data.projectile_damage)

func _apply_knockback(body: Node2D) -> void:
	if spell_data.knockback_force <= 0.0:
		return
	if body.has_method("apply_knockback"):
		body.apply_knockback(direction * spell_data.knockback_force)

func _apply_stun(body: Node2D) -> void:
	if spell_data.stunnable and spell_data.stun_dur > 0.0:
		if body.has_method("apply_stun"):
			body.apply_stun(spell_data.stun_dur)

func _apply_dot(body: Node2D) -> void:
	if not spell_data.dot or spell_data.dot_duration <= 0.0:
		return
	if body.has_method("apply_dot"):
		body.apply_dot(
			spell_data.dot_damage,
			spell_data.dot_interval,
			spell_data.dot_duration
		)

func _apply_slow(body: Node2D) -> void:
	if not spell_data.applies_slow or spell_data.slow_duration <= 0.0:
		return
	if body.has_method("apply_slow"):
		body.apply_slow(spell_data.slow_factor, spell_data.slow_duration)

func _apply_mana_drain(body: Node2D) -> void:
	if not spell_data.applies_mana_drain or spell_data.mana_drain_duration <= 0.0:
		return
	if body.has_method("apply_mana_drain"):
		body.apply_mana_drain(spell_data.mana_drain_amount, spell_data.mana_drain_duration)

func _apply_silence(body: Node2D) -> void:
	if not spell_data.applies_silence or spell_data.silence_duration <= 0.0:
		return
	if body.has_method("apply_silence"):
		body.apply_silence(spell_data.silence_duration)

func _apply_aoe() -> void:
	if spell_data.aoe_spell_radius <= 0.0:
		return
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = spell_data.aoe_spell_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = collision_mask

	var results = space.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body == self or body in _hit_bodies:
			continue
		_apply_damage(body)
		_apply_knockback(body)
		_apply_stun(body)
		_apply_dot(body)
		_apply_slow(body)
		_apply_mana_drain(body)
		_apply_silence(body)

func _spawn_impact_particles() -> void:
	if not spell_data.impact_particles:
		return
	var impact = spell_data.impact_particles.instantiate()
	get_parent().add_child(impact)
	impact.global_position = global_position
	impact.modulate = spell_data.spell_colour
	impact.emitting = true
	impact.finished.connect(impact.queue_free)
