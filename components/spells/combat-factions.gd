class_name CombatFactions extends RefCounted
static func faction(actor: Node) -> StringName:
	return actor.get_meta("faction_id", actor.get_meta("spell_team", &"player" if actor.is_in_group("player") else &"enemy"))
static func relation(source: Variant, target: Variant) -> int:
	if not is_instance_valid(source) or not is_instance_valid(target): return 0
	var a := faction(source)
	var b := faction(target)
	if a == b: return 1
	var overrides: Dictionary = source.get_meta("faction_relations", {})
	if overrides.has(b): return clampi(int(overrides[b]), -1, 1)
	if a == &"neutral" or b == &"neutral": return 0
	return -1

static func projectile_mask(team: StringName) -> int:
	return 18 if team == &"player" else 17 if team == &"enemy" else 19
