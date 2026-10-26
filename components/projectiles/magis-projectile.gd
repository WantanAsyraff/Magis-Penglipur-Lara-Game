class_name MagicProjectile extends SpellEffect
# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var lifetime: float = 5.0
var _started: bool = false
var _finished: bool = false
var _hit_bodies: Array = []
var _particle_instance: GPUParticles2D

# ─────────────────────────────────────────
# START
# ─────────────────────────────────────────
func start() -> void:
	if _started:
		return
	_started = true
	if cast_context == null:
		cast_context = SpellCastContext.new(source as Node2D, spell_data)
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

func trigger_immediate() -> void:
	# For AOE/self-cast spells that don't rely on body_entered.
	_apply_aoe()
	if spell_data.is_self_cast:
		var hitbox := source.get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox:
			_deliver(source as Node2D)
	_spawn_impact_particles()
	queue_free()

func _apply_lifetime() -> void:
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
	if not _started or _finished or spell_data == null:
		return
	if not cast_context.can_execute():
		queue_free()
		return
	if spell_data.projectile_speed > 0:
		position += direction * spell_data.projectile_speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
# ─────────────────────────────────────────
# HIT
# ─────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if _finished or not _started or not cast_context.can_execute():
		return

	if body == source:
		return

	if body is TileMapLayer or body.is_in_group("world"):
		_apply_aoe()
		_spawn_impact_particles()
		_finished = true
		queue_free()
		return

	if not SpellDelivery.can_target(cast_context, body):
		return

	if body in _hit_bodies:
		return

	_hit_bodies.append(body)

	var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox:
		_deliver(body)

	_apply_aoe()

	if not spell_data.piercing:
		_finished = true
		_spawn_impact_particles()
		queue_free()
	else:
		_spawn_impact_particles()
# ─────────────────────────────────────────
# AOE
# ─────────────────────────────────────────
func _apply_aoe() -> void:
	if spell_data.aoe_spell_radius <= 0.0:
		return
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = spell_data.aoe_spell_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = collision_mask
	var results := space.intersect_shape(query)
	for result in results:
		var body := result.collider as Node2D
		if body == null or body == self or body == source or body in _hit_bodies or not SpellDelivery.can_target(cast_context, body):
			continue
		_hit_bodies.append(body)
		var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox:
			_deliver(body)

# ─────────────────────────────────────────
# IMPACT PARTICLES
# ─────────────────────────────────────────
func _spawn_impact_particles() -> void:
	if not spell_data.impact_particles:
		return
	var impact := spell_data.impact_particles.instantiate()
	get_parent().add_child(impact)
	impact.global_position = global_position
	impact.modulate = spell_data.spell_colour
	impact.emitting = true
	impact.finished.connect(impact.queue_free)
# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────
func _get_child_names(node: Node) -> String:
	var names: Array = []
	for child in node.get_children():
		names.append(child.name)
	return ", ".join(names) if names.size() > 0 else "(none)"

func _deliver(body: Node2D) -> void:
	cast_context.direction = direction
	SpellExecutor.new().execute(cast_context, body)
