class_name EnemyStatsData extends Resource
@export var max_health: float = 100
@export var max_mana: float = 400
@export var health_regen: float = 0
@export var mana_regen: float = 0
@export var regen_delay: float = 2
@export var move_speed: float = 80
@export var chase_speed: float = 140
@export var defense: float = 0
@export var incoming_multiplier: float = 1
@export var outgoing_multiplier: float = 1
@export_range(0, 1) var knockback_resistance: float = 0
@export var status_resistances: Dictionary[String, float] = {}
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for key in ["max_health", "max_mana", "health_regen", "mana_regen", "regen_delay", "move_speed", "chase_speed", "defense", "incoming_multiplier", "outgoing_multiplier"]:
		var value := float(get(key))
		if not is_finite(value) or value < 0: errors.append("Invalid stat: " + key)
	if max_health <= 0: errors.append("Maximum health must be positive")
	if not is_finite(knockback_resistance) or knockback_resistance < 0 or knockback_resistance > 1: errors.append("Invalid knockback resistance")
	for key in status_resistances:
		var value := status_resistances[key]
		if not is_finite(value) or value < 0 or value > 1: errors.append("Invalid resistance: " + key)
	return errors
