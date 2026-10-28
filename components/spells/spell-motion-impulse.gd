class_name SpellMotionImpulse extends Node
## Additive motion survives actor controllers replacing their ordinary velocity.
var impulse: Vector2 = Vector2.ZERO
var remaining: float = 0.25
func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or not SpellExecutor.is_authoritative(body): queue_free(); return
	var motion := impulse * minf(delta, remaining)
	# A downward component must slide along the floor instead of swallowing the shove.
	for i in 3:
		if motion.is_zero_approx(): break
		var collision := body.move_and_collide(motion)
		if collision == null: break
		motion = collision.get_remainder().slide(collision.get_normal())
	remaining -= delta
	impulse = impulse.move_toward(Vector2.ZERO, 1200 * delta)
	if remaining <= 0: queue_free()
