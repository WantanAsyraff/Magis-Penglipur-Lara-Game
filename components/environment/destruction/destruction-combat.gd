class_name DestructionCombat extends RefCounted
static func candidates(context: DestructionContext, at: Vector2, radius: float, policy: DestructionTargetPolicy) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not context.valid() or policy == null: return result
	for hitbox in context.runtime.get_tree().get_nodes_in_group("hitbox"):
		var target := hitbox.get_parent() as Node2D
		if target == null or not policy.accepts(context, target) or SpellDelivery.target_distance(at, target) > radius: continue
		if policy.require_line_of_sight and not visible_to(context, at, target): continue
		result.append(target)
		if result.size() >= 128: break
	return result
static func visible_to(context: DestructionContext, at: Vector2, target: Node2D) -> bool:
	var exclude: Array[RID] = []
	if target is CollisionObject2D: exclude.append(target.get_rid())
	var source := context.source_object()
	if source is CollisionObject2D: exclude.append(source.get_rid())
	var end := at.clamp(SpellDelivery.target_bounds(target).position, SpellDelivery.target_bounds(target).end)
	var query := PhysicsRayQueryParameters2D.create(at, end, 16, exclude)
	return context.runtime.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
static func hit(context: DestructionContext, target: Node2D, amount: float, kind: EnvironmentalDamage.Kind, force: float = 0.0, chain: bool = true) -> bool:
	if not context.valid() or not SpellExecutor.is_authoritative(target) or target.get_meta("combat_dead", false): return false
	var damage := EnvironmentalDamage.new()
	damage.kind = kind; damage.instigator = context.instigator; damage.destruction_context = context
	var component := target.get_node_or_null("DestructibleComponent") as DestructibleComponent
	if component:
		if not chain: return false
		return component.apply_damage(amount, damage)
	var hitbox := target.get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox == null or hitbox.is_invincible(): return false
	var credit: Node2D = context.instigator if is_instance_valid(context.instigator) else context.runtime
	if credit == context.runtime: context.runtime.set_meta("quest_owner_id", context.credit_owner)
	hitbox.receive_damage(amount, credit)
	if force > 0 and hitbox.receives_knockback and not target.get_meta("combat_dead", false):
		hitbox._apply_knockback((target.global_position - context.position).normalized(), force)
	return true
