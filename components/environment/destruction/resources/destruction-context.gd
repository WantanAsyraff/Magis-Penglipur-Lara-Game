class_name DestructionContext extends RefCounted
## Per-event snapshots. Behaviors must treat these values as read-only; only budget is shared.
var source: WeakRef
var source_id := ""
var generation := 0
var instigator: Node2D
var credit_owner := ""
var faction: StringName = &"neutral"
var position := Vector2.ZERO
var damage: EnvironmentalDamage
var material: DestructibleMaterialDefinition
var event_id := ""
var depth := 0
var budget: DestructionBudget
var runtime: DestructionRuntime
var authoritative := false
var spell: SpellData
var rng := RandomNumberGenerator.new()
func source_object() -> Node2D:
	return source.get_ref() as Node2D if source else null
func valid() -> bool:
	return authoritative and is_instance_valid(runtime) and runtime.is_inside_tree() and not runtime.is_queued_for_deletion() and SpellExecutor.is_authoritative(runtime)
func effects_valid() -> bool:
	var node := source_object()
	if not valid() or not is_instance_valid(node) or node.is_queued_for_deletion(): return false
	var component := node.get_node_or_null("DestructibleComponent") as DestructibleComponent
	return component != null and component.generation == generation and component.is_destroyed()
func owner_id() -> String:
	return GameplayEvent.owner_for(instigator)
