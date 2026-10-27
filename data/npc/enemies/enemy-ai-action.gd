class_name EnemyAIAction extends Resource
enum Kind { IDLE, PATROL, INVESTIGATE, CHASE, RETREAT, MAINTAIN_RANGE, MELEE, RANGED, CAST, DEFEND, REPOSITION, RECOVER, FLEE, SUMMON }
@export var action_id: StringName = &"":
	get:
		if action_id != &"": return action_id
		return StringName(Kind.keys()[kind].to_lower()) if kind >= 0 and kind < Kind.size() else &""
@export var kind: Kind = Kind.IDLE
@export var utility: float = 1
@export var max_health_ratio: float = 1
@export var max_mana_ratio: float = 1
@export var low_health_weight: float = 0
@export var low_mana_weight: float = 0
@export var threat_weight: float = 0
@export var ability_id: StringName = &""
@export var cooldown: float = 0
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if action_id == &"" or kind < 0 or kind >= Kind.size(): errors.append("Invalid AI action")
	for key in ["utility", "low_health_weight", "low_mana_weight", "threat_weight", "cooldown"]:
		var value := float(get(key))
		if not is_finite(value) or value < 0: errors.append("Invalid consideration: " + key)
	if not is_finite(max_health_ratio) or max_health_ratio < 0 or max_health_ratio > 1 or not is_finite(max_mana_ratio) or max_mana_ratio < 0 or max_mana_ratio > 1: errors.append("Invalid consideration threshold")
	return errors
