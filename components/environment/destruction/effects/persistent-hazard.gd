class_name DestructionHazard extends Node2D
var context: DestructionContext
var definition: PersistentHazardBehavior
var elapsed := 0.0
var next_tick_at := 0.0
var affected: Dictionary = {}
var ticks := 0
func _ready() -> void:
	add_to_group("destruction_hazard")
	if definition.hazard_particles:
		var particles := definition.hazard_particles.instantiate()
		if particles is Node2D: add_child(particles)
		else: particles.free()
	if definition.hazard_sound:
		var audio := AudioStreamPlayer2D.new(); audio.stream = definition.hazard_sound; add_child(audio); audio.play()
func _physics_process(delta: float) -> void:
	if context == null or not context.valid(): queue_free(); return
	elapsed += delta
	var work := 0
	while next_tick_at < definition.duration and next_tick_at <= minf(elapsed, definition.duration) and work < 8:
		next_tick_at += definition.tick_interval; work += 1; tick()
	if elapsed >= definition.duration + definition.fade_out_duration: queue_free(); return
	var alpha := minf(1.0, elapsed / maxf(0.01, definition.fade_in_duration))
	if elapsed > definition.duration: alpha *= maxf(0, 1 - (elapsed - definition.duration) / maxf(0.01, definition.fade_out_duration))
	modulate.a = alpha
	queue_redraw()
func tick() -> void:
	if not context.valid(): return
	ticks += 1
	for target in DestructionCombat.candidates(context, global_position, definition.radius, definition.targets):
		var id := target.get_instance_id()
		if definition.damage_per_tick > 0: DestructionCombat.hit(context, target, definition.damage_per_tick, definition.damage_kind)
		if definition.status_effect == null or target.get_meta("combat_dead", false): continue
		if definition.reentry_policy == PersistentHazardBehavior.ReentryPolicy.ONCE_PER_ACTOR and affected.has(id): continue
		var hitbox := target.get_node_or_null("HitboxComponent") as HitboxComponent
		var status := definition.status_effect
		if hitbox and hitbox.apply_status(status.status, status.duration, {"amount":status.magnitude,"factor":clampf(status.magnitude,0,1),"interval":status.tick_interval}, context.event_id, status.stacking, 1): affected[id] = true
func _draw() -> void:
	if definition == null: return
	draw_circle(Vector2.ZERO, definition.radius, Color(definition.color, 0.12))
	draw_arc(Vector2.ZERO, definition.radius, 0, TAU, 64, Color(definition.color, 0.45), 2)
	for i in 12:
		var angle := i * TAU / 12 + elapsed * 0.3
		draw_circle(Vector2.from_angle(angle) * definition.radius * 0.55, 18 + sin(elapsed * 2 + i) * 6, Color(definition.color, 0.16))
