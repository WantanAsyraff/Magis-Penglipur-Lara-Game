class_name CombatRequest extends RefCounted
static func apply(source: Node2D, target: Node2D, effects: Array[SpellEffectDefinition], direction: Vector2 = Vector2.RIGHT) -> bool:
	if not SpellExecutor.is_authoritative(source) or not is_instance_valid(target) or CombatFactions.relation(source, target) >= 0: return false
	var context := SpellCastContext.new(source)
	context.direction = direction.normalized()
	var h := source.get_node_or_null("HitboxComponent") as HitboxComponent
	if h: context.modifiers.damage = h.effects.magnitude("buff_damage")
	return SpellExecutor.execute_effects(context, target, effects)
static func strike(source: Node2D, target: Node2D, damage: float, knockback: float = 0) -> bool:
	var hit := DamageEffect.new()
	hit.amount = damage
	var impulse := KnockbackEffect.new()
	impulse.force = knockback
	return apply(source, target, [hit, impulse], target.global_position - source.global_position)
