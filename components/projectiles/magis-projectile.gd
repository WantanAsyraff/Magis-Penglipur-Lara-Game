class_name MagicProjectile extends SpellEffect
# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var lifetime: float = 5.0
var _hit_bodies: Array = []
var _particle_instance: GPUParticles2D

# ─────────────────────────────────────────
# START
# ─────────────────────────────────────────
func start() -> void:
	print("[MagicProjectile] start() called. source=%s | spell_data=%s" % [source, spell_data])
	if not spell_data:
		push_warning("MagicProjectile: no spell_data assigned.")
		queue_free()
		return
	print("[MagicProjectile] spell_data OK: %s | speed=%.1f | range=%.1f | piercing=%s | aoe=%.1f" % [
		spell_data.resource_name, spell_data.projectile_speed,
		spell_data.projectile_range, spell_data.piercing, spell_data.aoe_spell_radius
	])
	print("[MagicProjectile] collision_layer=%d | collision_mask=%d" % [collision_layer, collision_mask])
	print("[MagicProjectile] monitoring=%s | monitorable=%s" % [monitoring, monitorable])
	_apply_visuals()
	_apply_lifetime()
	_apply_colour()
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	print("[MagicProjectile] Signals connected. lifetime=%.2f | direction=%s" % [lifetime, direction])

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
			hitbox.receive_hit(spell_data, direction)
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
	if spell_data.projectile_speed > 0:
		position += direction * spell_data.projectile_speed * delta
	lifetime -= delta
	if lifetime <= 0:
		print("[MagicProjectile] Lifetime expired at position=%s. Freeing." % global_position)
		queue_free()
# ─────────────────────────────────────────
# HIT
# ─────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	print("[MagicProjectile] body_entered: %s | class=%s | groups=%s" % [
		body.name, body.get_class(), body.get_groups()
	])

	if body == source:
		print("[MagicProjectile]   → SKIPPED: body is source (%s)" % source.name)
		return

	if body is TileMapLayer or body.is_in_group("world"):
		_apply_aoe()
		print("[MagicProjectile]   → HIT WORLD/TILE: %s. Spawning impact and freeing." % body.name)
		_spawn_impact_particles()
		queue_free()
		return

	print("[MagicProjectile]   → Non-world body hit: %s" % body.name)

	if spell_data.piercing and body in _hit_bodies:
		print("[MagicProjectile]   → SKIPPED: piercing and already hit this body.")
		return

	_hit_bodies.append(body)
	print("[MagicProjectile]   → Added to _hit_bodies. Total hit: %d" % _hit_bodies.size())

	var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox:
		print("[MagicProjectile]   → HitboxComponent FOUND on %s. Calling receive_hit()." % body.name)
		hitbox.receive_hit(spell_data, direction)
	else:
		print("[MagicProjectile]   → WARNING: No HitboxComponent on %s! Children: %s" % [
			body.name, _get_child_names(body)
		])

	_apply_aoe()

	if not spell_data.piercing:
		print("[MagicProjectile]   → Non-piercing: freeing after hit.")
		_spawn_impact_particles()
		queue_free()
	else:
		print("[MagicProjectile]   → Piercing: continuing through %s." % body.name)
		_spawn_impact_particles()
# ─────────────────────────────────────────
# AOE
# ─────────────────────────────────────────
func _apply_aoe() -> void:
	if spell_data.aoe_spell_radius <= 0.0:
		print("[MagicProjectile] AOE skipped: radius=0.")
		return
	print("[MagicProjectile] AOE triggered at %s with radius=%.1f | mask=%d" % [
		global_position, spell_data.aoe_spell_radius, collision_mask
	])
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = spell_data.aoe_spell_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = collision_mask
	var results := space.intersect_shape(query)
	print("[MagicProjectile] AOE shape query returned %d result(s)." % results.size())
	for result in results:
		var body := result.collider as Node2D
		if body == null or body == self or body == source or body in _hit_bodies:
			print("[MagicProjectile]   AOE SKIPPED: %s" % (body.name if body else "null"))
			continue
		print("[MagicProjectile]   AOE HIT: %s | groups=%s" % [body.name, body.get_groups()])
		_hit_bodies.append(body)
		var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox:
			print("[MagicProjectile]   AOE → HitboxComponent found, calling receive_hit().")
			hitbox.receive_hit(spell_data, direction)
		else:
			print("[MagicProjectile]   AOE → WARNING: No HitboxComponent on %s. Children: %s" % [
				body.name, _get_child_names(body)
			])
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
