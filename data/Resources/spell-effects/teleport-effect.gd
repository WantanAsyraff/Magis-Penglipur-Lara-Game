class_name TeleportEffect extends SpellEffectDefinition
@export var distance: float = 100.0
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid teleport distance"]) if not is_finite(distance) or distance < 0 else PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var destination := target.global_position + context.direction * distance
	if target is PhysicsBody2D:
		if target.test_move(target.global_transform, context.direction * distance):
			return false
	target.global_position = destination
	return true
