class_name DestructibleConfig extends Resource
@export_group("Identity")
@export var destructible_id := "destructible"
@export var display_name := "Destructible"
@export var enabled := true
@export_group("Durability")
@export_range(1, 100000) var max_health := 30.0
@export var starts_damaged := false
@export_range(0.01, 1) var initial_health_ratio := 0.6
@export var invulnerable := false
@export_range(0, 100) var damage_multiplier := 1.0
@export_group("Lifecycle")
@export var destroy_on_zero_health := true
@export var collision_disabled_on_destroy := true
@export var remove_after_destroy := false
@export_range(0.05, 10) var destruction_seconds := 0.4
@export_group("Material and damage states")
@export var material: DestructibleMaterialDefinition
@export var states: Array[DestructibleStateDefinition] = []
@export_group("Destruction behaviors")
@export var behaviors: Array[DestructionBehavior] = []
@export_group("Persistence")
@export var persistent := false
## Globally unique, stable campaign identity. Override on EACH placed instance.
@export var persistence_id := ""
@export var persist_health := true
@export var respawn_on_scene_reload := false
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if destructible_id.is_empty() or not is_finite(max_health) or max_health < 1 or max_health > 100000: errors.append("Invalid identity or maximum health")
	if not is_finite(damage_multiplier) or damage_multiplier < 0 or damage_multiplier > 100: errors.append("Invalid damage multiplier")
	if not is_finite(initial_health_ratio) or initial_health_ratio <= 0 or initial_health_ratio > 1: errors.append("Initial health ratio must be in (0,1]")
	if not is_finite(destruction_seconds) or destruction_seconds < 0.05 or destruction_seconds > 10: errors.append("Destruction duration must be 0.05–10 seconds")
	if persistent and not respawn_on_scene_reload and (persistence_id.is_empty() or persistence_id.length() > 128): errors.append("Persistent objects require a unique ID of 1–128 characters")
	if material: errors.append_array(material.validate())
	var thresholds := {}; var ids := {}
	for state in states:
		if state == null: errors.append("Null damage state"); continue
		errors.append_array(state.validate())
		if ids.has(state.state_id) or thresholds.has(state.health_threshold_ratio): errors.append("Duplicate state ID or health threshold")
		ids[state.state_id] = true; thresholds[state.health_threshold_ratio] = true
	if not states.is_empty() and not thresholds.has(1.0): errors.append("Damage states need an intact threshold of 1.0")
	if behaviors.size() > 16: errors.append("At most sixteen behaviors per object")
	for behavior in behaviors:
		if behavior: errors.append_array(behavior.validate())
		else: errors.append("Null destruction behavior")
	return errors
