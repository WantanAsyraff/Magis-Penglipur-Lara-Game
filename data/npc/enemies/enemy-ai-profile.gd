class_name EnemyAIProfile extends Resource
@export var profile_id: StringName = &"balanced"
@export var actions: Array[EnemyAIAction] = []
@export var decision_interval: float = 0.2
@export var commitment: float = 0.45
@export var switch_margin: float = 0.2
@export var preferred_range: float = 200
@export var retreat_range: float = 80
@export var range_tolerance: float = 35
@export var flee_health_ratio: float = 0.15
@export var patrol_range: float = 120
@export var wall_jump_velocity: float = -260
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id == &"" or actions.is_empty(): errors.append("Profile requires ID and actions")
	for key in ["decision_interval", "commitment", "switch_margin", "preferred_range", "retreat_range", "range_tolerance", "patrol_range"]:
		var value := float(get(key))
		if not is_finite(value) or value < 0: errors.append("Invalid profile value: " + key)
	if decision_interval < 0.05: errors.append("Decision interval must be at least 0.05 s")
	if not is_finite(wall_jump_velocity) or wall_jump_velocity > 0: errors.append("Invalid wall jump")
	if not is_finite(flee_health_ratio) or flee_health_ratio < 0 or flee_health_ratio > 1: errors.append("Invalid flee ratio")
	var ids := {}
	for action in actions:
		if action == null: errors.append("Missing action"); continue
		errors.append_array(action.validate())
		if ids.has(action.action_id): errors.append("Duplicate action ID")
		ids[action.action_id] = true
	return errors
