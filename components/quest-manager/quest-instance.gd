class_name QuestInstance
extends RefCounted

enum Status { AVAILABLE, ACTIVE, COMPLETE, HANDED_OFF, EXPIRED }

var instance_id: String = ""
var quest_data: QuestData
var status: Status = Status.AVAILABLE
var objective_progress: Dictionary = {}
var assigned_npc_id: String = ""
var _despawn_time: float = -1.0

func _init(data: QuestData, npc_id: String, despawn_after: float = -1.0) -> void:
	quest_data = data
	assigned_npc_id = npc_id
	instance_id = "%s_%s_%d" % [data.quest_id, npc_id, Time.get_ticks_msec()]
	for obj in data.objectives:
		objective_progress[obj.objective_id] = 0
	if despawn_after > 0.0:
		_despawn_time = Time.get_unix_time_from_system() + despawn_after
	print("[QuestInstance] Created instance_id='%s' | quest='%s' | npc='%s' | despawn_after=%.1f" % [
		instance_id, data.quest_id, npc_id, despawn_after
	])

# -------------------------
# PROGRESS
# -------------------------
func update_objective(objective_id: String, amount: int = 1) -> void:
	if not objective_progress.has(objective_id):
		print("[QuestInstance] WARNING: objective_id '%s' not found in instance '%s'" % [objective_id, instance_id])
		return
	var required := _get_required(objective_id)
	var before = objective_progress[objective_id]
	objective_progress[objective_id] = min(before + amount, required)
	print("[QuestInstance] '%s' objective '%s': %d → %d / %d" % [
		instance_id, objective_id, before, objective_progress[objective_id], required
	])
	if is_objectives_met() and status == Status.ACTIVE:
		status = Status.COMPLETE
		print("[QuestInstance] '%s' all objectives met — status → COMPLETE" % instance_id)

func is_objectives_met() -> bool:
	for obj in quest_data.objectives:
		if objective_progress.get(obj.objective_id, 0) < _get_required(obj.objective_id):
			return false
	return true

func _get_required(objective_id: String) -> int:
	for obj in quest_data.objectives:
		if obj.objective_id == objective_id:
			var total := 0
			for amount in obj.required_amounts:
				total += amount
			return total
	return 1

# -------------------------
# DESPAWN TIMER
# -------------------------
func get_despawn_seconds_remaining() -> float:
	if _despawn_time < 0.0:
		return -1.0
	return _despawn_time - Time.get_unix_time_from_system()

# -------------------------
# SERIALISE
# -------------------------
func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"quest_id": quest_data.quest_id,
		"assigned_npc_id": assigned_npc_id,
		"status": status,
		"objective_progress": objective_progress.duplicate(),
		"despawn_time": _despawn_time,
	}
