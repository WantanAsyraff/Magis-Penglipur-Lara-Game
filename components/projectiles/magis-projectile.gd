class_name MagicProjectile extends Area2D
# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var spell_data: SpellData = null
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 5.0
var source: Node = null
var _hit_bodies: Array = []
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
	if body == source:
		return
	if body is TileMapLayer or (body.collision_layer & (1 << 4)):
		_spawn_impact_particles()
		queue_free()
		return
	if spell_data.piercing and body in _hit_bodies:
		return
	_hit_bodies.append(body)
	var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox:
		hitbox.receive_hit(spell_data, direction)
	_apply_aoe()
	_spawn_impact_particles()
	if not spell_data.piercing:
		queue_free()
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
		if body == null or body == self or body == source or body in _hit_bodies:
			continue
		_hit_bodies.append(body)
		var hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox:
			hitbox.receive_hit(spell_data, direction)
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
