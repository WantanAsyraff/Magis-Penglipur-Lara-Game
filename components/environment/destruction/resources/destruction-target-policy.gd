class_name DestructionTargetPolicy extends Resource
@export var affects_player := true
@export var affects_enemies := true
@export var affects_environment := true
@export var friendly_fire := false
@export var require_line_of_sight := true
func accepts(context: DestructionContext, target: Node2D) -> bool:
	if target == context.source_object() or target.is_queued_for_deletion() or target.get_meta("combat_dead", false): return false
	if target.is_in_group("destructible"): return affects_environment
	if target.is_in_group("player"):
		if not affects_player: return false
	elif target.is_in_group("combat_target"):
		if not affects_enemies: return false
	else: return false
	if not friendly_fire and context.faction != &"neutral":
		if is_instance_valid(context.instigator): return CombatFactions.relation(context.instigator, target) < 0
		return CombatFactions.faction(target) != context.faction and CombatFactions.faction(target) != &"neutral"
	return true
