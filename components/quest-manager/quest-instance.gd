class_name QuestInstance extends RefCounted
enum Status { AVAILABLE, ACTIVE, COMPLETE, HANDED_OFF, EXPIRED, CANCELLED }
var instance_id: String = ""
var quest_data: QuestData
var owner_id: String = "local"
var status: Status = Status.AVAILABLE
var objective_progress: Dictionary = {}
var assigned_npc_id: String = ""
var accepted_at: float = 0
var completed_at: float = 0
var reward_claimed: bool = false
var pending_claim: String = ""
var selected_branch: String = ""
var accepted_prerequisites: Array[String] = []
var _despawn_time: float = -1
func _init(data: QuestData, npc_id: String = "", despawn_after: float = -1, owner: String = "local") -> void:
	quest_data = data
	assigned_npc_id = npc_id
	owner_id = owner
	instance_id = data.quest_id + ":" + Crypto.new().generate_random_bytes(16).hex_encode()
	for obj in data.objectives: objective_progress[obj.objective_id] = 0
	if despawn_after > 0: _despawn_time = Time.get_unix_time_from_system() + despawn_after
func objective(id: String) -> QuestObjectiveData:
	for obj in quest_data.objectives:
		if obj.objective_id == id: return obj
	return null
func done(id: String) -> bool:
	var obj := objective(id)
	return obj != null and int(objective_progress.get(id, 0)) >= obj.required_amount
func eligible(obj: QuestObjectiveData) -> bool:
	for id in obj.requires_objectives:
		if not done(id): return false
	return true
func update_objective(id: String, amount: int = 1) -> void:
	var obj := objective(id)
	if status != Status.ACTIVE or obj == null or not eligible(obj) or amount <= 0: return
	objective_progress[id] = mini(obj.required_amount, int(objective_progress.get(id, 0)) + amount)
	reconcile()
func reconcile() -> void:
	if status not in [Status.ACTIVE, Status.COMPLETE]: return
	if is_objectives_met():
		if status == Status.ACTIVE: completed_at = Time.get_unix_time_from_system()
		status = Status.COMPLETE
	else: status = Status.ACTIVE
func is_objectives_met() -> bool:
	for obj in quest_data.objectives:
		if not obj.is_optional and obj.group_id == &"" and not done(obj.objective_id): return false
	for group in quest_data.objective_groups:
		if group.is_optional: continue
		var count := 0
		var needed := 0
		for obj in quest_data.objectives:
			if obj.group_id != group.group_id or obj.is_optional: continue
			needed += 1
			if done(obj.objective_id): count += 1
		if count < (needed if group.policy == QuestObjectiveGroup.Policy.ALL else group.minimum_completed): return false
	return true
func get_despawn_seconds_remaining() -> float:
	return _despawn_time - Time.get_unix_time_from_system() if _despawn_time > 0 else -1
func to_dict() -> Dictionary:
	return {"instance_id": instance_id, "quest_id": quest_data.quest_id, "owner_id": owner_id, "status": status, "objective_progress": objective_progress.duplicate(), "assigned_npc_id": assigned_npc_id, "accepted_at": accepted_at, "completed_at": completed_at, "reward_claimed": reward_claimed, "pending_claim": pending_claim, "selected_branch": selected_branch, "accepted_prerequisites": accepted_prerequisites.duplicate(), "despawn_time": _despawn_time}
