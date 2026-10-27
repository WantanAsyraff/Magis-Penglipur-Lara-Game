class_name ChainEffect extends SpellEffectDefinition
@export var radius: float = 180.0
@export_range(1, 8) var hops: int = 3
@export var amount: float = 10.0
@export var preferred_status: String = "charged"
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var visited: Array[Node2D] = [target]
	var current := target
	for hop in hops:
		var best: Node2D
		var best_score := INF
		for node in target.get_tree().get_nodes_in_group("hitbox"):
			var candidate := node.get_parent() as Node2D
			if candidate == null or candidate in visited or not SpellDelivery.can_target(context, candidate): continue
			var distance := current.global_position.distance_to(candidate.global_position)
			var h := node as HitboxComponent
			var score := distance * (0.5 if h.effects.has(preferred_status) else 1.0)
			if distance <= radius and score < best_score:
				best = candidate; best_score = score
		if best == null: break
		visited.append(best)
		var damage := DamageEffect.new()
		damage.amount = amount * pow(0.75, hop)
		SpellExecutor.execute_effects(context, best, [damage])
		SpellFeedback.flash(best, context.spell.spell_colour)
		current = best
	return true
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid chain"]) if radius <= 0 or not is_finite(radius) or hops < 1 or hops > 8 or amount < 0 or not is_finite(amount) else PackedStringArray()
