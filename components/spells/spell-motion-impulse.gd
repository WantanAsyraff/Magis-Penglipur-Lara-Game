class_name SpellMotionImpulse extends Node
## Additive motion survives actor controllers replacing their ordinary velocity.
var impulse: Vector2 = Vector2.ZERO
var remaining: float = 0.25
func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or not SpellExecutor.is_authoritative(body): queue_free(); return
	body.move_and_collide(impulse * minf(delta, remaining))
	remaining -= delta
	impulse = impulse.move_toward(Vector2.ZERO, 1200 * delta)
	if remaining <= 0: queue_free()
