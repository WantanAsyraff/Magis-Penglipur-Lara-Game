class_name EnemyPerceptionData extends Resource
@export var detection_range: float = 620
@export var sight_memory: float = 2.5
@export var scan_interval: float = 0.2
@export_range(1, 64) var max_candidates: int = 16
@export_flags_2d_physics var terrain_mask: int = 16
@export var target_groups: Array[StringName] = [&"player", &"combat_target"]
## -1 hostile, 0 neutral, 1 allied. Same faction is always allied.
@export var relations: Dictionary[StringName, int] = {&"neutral": 0}
@export var threat_decay: float = 2
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(detection_range) or detection_range <= 0 or detection_range > 10000 or not is_finite(sight_memory) or sight_memory < 0 or not is_finite(scan_interval) or scan_interval < 0.05 or max_candidates < 1 or max_candidates > 64 or not is_finite(threat_decay) or threat_decay < 0: errors.append("Invalid perception configuration")
	for value in relations.values():
		if value < -1 or value > 1: errors.append("Invalid faction relation")
	return errors
