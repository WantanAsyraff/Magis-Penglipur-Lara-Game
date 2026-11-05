class_name DestructionExplosion extends Node2D
var context: DestructionContext
var definition: AreaExplosionBehavior
var detonated := false
var elapsed := 0.0
func _ready() -> void:
	add_to_group("destruction_explosion")
func _physics_process(delta: float) -> void:
	if context == null or not context.valid(): queue_free(); return
	if not detonated: detonate()
	elapsed += delta
	if elapsed >= 0.55: queue_free()
	queue_redraw()
func detonate() -> void:
	if detonated or not context.valid(): return
	detonated = true
	for target in DestructionCombat.candidates(context, global_position, definition.explosion_radius, definition.targets):
		var distance := SpellDelivery.target_distance(global_position, target) / definition.explosion_radius
		var falloff := clampf(definition.damage_falloff.sample_baked(distance), 0, 1) if definition.damage_falloff else 1.0 - distance * 0.75
		var amount := definition.base_damage * falloff
		if target.is_in_group("destructible"): amount *= definition.chain_reaction_multiplier
		DestructionCombat.hit(context, target, amount, definition.damage_kind, definition.knockback_force * falloff, definition.chain_reaction_enabled)
	if definition.explosion_particles:
		var particles := definition.explosion_particles.instantiate()
		if particles is Node2D: context.runtime.spawn_node(particles, context, global_position, 3.0)
		else: particles.free()
	if definition.explosion_sound:
		var audio := AudioStreamPlayer2D.new(); audio.stream = definition.explosion_sound; add_child(audio); audio.play()
	if definition.camera_feedback_enabled:
		var player := Player_Manager.get_local_player() as Player
		if player and player.global_position.distance_to(global_position) < definition.explosion_radius * 3: SpellFeedback.flash(player, Color(definition.color, 0.25), 12)
func _draw() -> void:
	if definition == null: return
	var progress := clampf(elapsed / 0.55, 0, 1)
	draw_circle(Vector2.ZERO, definition.explosion_radius * progress, Color(definition.color, (1 - progress) * 0.18))
	draw_arc(Vector2.ZERO, definition.explosion_radius * progress, 0, TAU, 64, Color(definition.color, 1 - progress), 5 * (1 - progress) + 1)
	for i in 12:
		var direction := Vector2.from_angle(i * TAU / 12)
		draw_line(direction * definition.explosion_radius * progress * 0.6, direction * definition.explosion_radius * progress, Color(definition.color, 1 - progress), 3)
