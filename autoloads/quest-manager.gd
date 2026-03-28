extends Node

# -------------------------
# SIGNALS
# -------------------------
signal quest_started(instance: QuestInstance)
signal quest_objective_updated(instance: QuestInstance, objective_id: String)
signal quest_completed(instance: QuestInstance)
signal quest_handed_off(instance: QuestInstance)

# -------------------------
# STATE
# -------------------------
var database: QuestDatabase
var _active_instances: Dictionary = {}
var _npc_instance_map: Dictionary = {}
var _quest_active_count: Dictionary = {}

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	print("[QuestManager] Loading quest database...")
	database = load("res://data/quests/flac-database.tres")
	if database:
		print("[QuestManager] Database loaded — %d quest(s)" % database.quests.size())
	else:
		push_error("[QuestManager] Failed to load quest-database.tres")

# -------------------------
# NPC INTERFACE
# -------------------------
func request_quest_for_npc(faculty: QuestData.Faculty, npc_id: String) -> QuestInstance:
	print("[QuestManager] request_quest_for_npc | faculty=%d | npc_id='%s'" % [faculty, npc_id])
	if not database:
		push_error("[QuestManager] database is null")
		return null
	if _npc_instance_map.has(npc_id):
		print("[QuestManager] '%s' already has an instance — returning existing" % npc_id)
		return _active_instances.get(_npc_instance_map[npc_id], null)
	var candidates := _get_quests_for_faculty(faculty)
	print("[QuestManager] %d candidate quest(s) for faculty=%d" % [candidates.size(), faculty])
	for data in candidates:
		if not _prerequisites_met(data):
			print("[QuestManager] Skipping '%s' — prerequisites not met" % data.quest_id)
			continue
		var active_count: int = _quest_active_count.get(data.quest_id, 0)
		if active_count >= data.max_concurrent:
			print("[QuestManager] Skipping '%s' — at concurrent cap (%d)" % [data.quest_id, data.max_concurrent])
			continue
		if Player_Global_Data.completed_quests.has(data.quest_id):
			print("[QuestManager] Skipping '%s' — already completed" % data.quest_id)
			continue
		var instance := QuestInstance.new(data, npc_id, data.despawn_after_seconds)
		_active_instances[instance.instance_id] = instance
		_npc_instance_map[npc_id] = instance.instance_id
		_quest_active_count[data.quest_id] = active_count + 1
		print("[QuestManager] Assigned instance '%s' to npc '%s'" % [instance.instance_id, npc_id])
		return instance
	print("[QuestManager] No suitable quest found for npc '%s'" % npc_id)
	return null

func accept_quest(instance_id: String) -> void:
	print("[QuestManager] accept_quest | instance_id='%s'" % instance_id)
	var instance := _get_instance(instance_id)
	if not instance:
		return
	if instance.status != QuestInstance.Status.AVAILABLE:
		print("[QuestManager] WARNING: accept_quest called on non-AVAILABLE instance '%s'" % instance_id)
		return
	instance.status = QuestInstance.Status.ACTIVE
	print("[QuestManager] Instance '%s' status → ACTIVE" % instance_id)
	quest_started.emit(instance)
	_update_goals_from_instance(instance)

func update_objective(instance_id: String, objective_id: String, amount: int = 1) -> void:
	print("[QuestManager] update_objective | instance='%s' | objective='%s' | amount=%d" % [instance_id, objective_id, amount])
	var instance := _get_instance(instance_id)
	if not instance:
		return
	if instance.status != QuestInstance.Status.ACTIVE:
		print("[QuestManager] WARNING: update_objective on non-ACTIVE instance '%s'" % instance_id)
		return
	instance.update_objective(objective_id, amount)
	quest_objective_updated.emit(instance, objective_id)
	if instance.status == QuestInstance.Status.COMPLETE:
		quest_completed.emit(instance)
	_update_goals_from_instance(instance)

func _update_goals_from_instance(instance: QuestInstance) -> void:
	print("[QuestManager] updating goals — %d objective(s)" % instance.quest_data.objectives.size())
	var goals: Array[String] = []
	for obj in instance.quest_data.objectives:
		var progress: int = instance.objective_progress.get(obj.objective_id, 0)
		var required := 0
		for amount in obj.required_amounts:
			required += amount
		goals.append("%s (%d/%d)" % [obj.description, progress, required])
	print("[QuestManager] goals array: %s" % str(goals))
	Player_Global_Data.active_goals = goals

func update_objective_by_quest(quest_id: String, objective_id: String, amount: int = 1) -> void:
	print("[QuestManager] update_objective_by_quest | quest='%s' | objective='%s'" % [quest_id, objective_id])
	for instance_id in _active_instances:
		var instance: QuestInstance = _active_instances[instance_id]
		if instance.quest_data.quest_id == quest_id and instance.status == QuestInstance.Status.ACTIVE:
			update_objective(instance_id, objective_id, amount)

func try_hand_off(instance_id: String) -> bool:
	print("[QuestManager] try_hand_off | instance_id='%s'" % instance_id)
	var instance := _get_instance(instance_id)
	if not instance:
		return false
	if instance.status != QuestInstance.Status.COMPLETE:
		print("[QuestManager] try_hand_off failed — status is '%s', not COMPLETE" % str(instance.status))
		return false
	instance.status = QuestInstance.Status.HANDED_OFF
	print("[QuestManager] Instance '%s' status → HANDED_OFF" % instance_id)
	Player_Global_Data.completed_quests.append(instance.quest_data.quest_id)
	print("[QuestManager] '%s' added to completed_quests" % instance.quest_data.quest_id)
	Player_Global_Data.clear_goals()
	quest_handed_off.emit(instance)
	if instance.quest_data.next_quest_id != "":
		print("[QuestManager] Chaining to next_quest_id='%s'" % instance.quest_data.next_quest_id)
	return true

func notify_npc_despawned(instance_id: String) -> void:
	print("[QuestManager] notify_npc_despawned | instance_id='%s'" % instance_id)
	if instance_id.is_empty():
		return
	var instance := _get_instance(instance_id)
	if not instance:
		return
	if instance.status == QuestInstance.Status.AVAILABLE or instance.status == QuestInstance.Status.ACTIVE:
		instance.status = QuestInstance.Status.EXPIRED
		print("[QuestManager] Instance '%s' status → EXPIRED" % instance_id)
	var quest_id := instance.quest_data.quest_id
	if _quest_active_count.has(quest_id):
		_quest_active_count[quest_id] = max(0, _quest_active_count[quest_id] - 1)
		print("[QuestManager] '%s' concurrent count → %d" % [quest_id, _quest_active_count[quest_id]])
	_npc_instance_map.erase(instance.assigned_npc_id)
	_active_instances.erase(instance_id)
	print("[QuestManager] Instance '%s' removed from active pool" % instance_id)

# -------------------------
# QUERIES
# -------------------------
func is_quest_complete(quest_id: String) -> bool:
	var result := Player_Global_Data.completed_quests.has(quest_id)
	print("[QuestManager] is_quest_complete '%s': %s" % [quest_id, result])
	return result

func get_instance(instance_id: String) -> QuestInstance:
	return _active_instances.get(instance_id, null)

func get_instance_for_npc(npc_id: String) -> QuestInstance:
	var instance_id: String = _npc_instance_map.get(npc_id, "")
	if instance_id.is_empty():
		return null
	return _active_instances.get(instance_id, null)

func get_all_active() -> Array:
	return _active_instances.values()

# -------------------------
# INTERNAL
# -------------------------
func _get_instance(instance_id: String) -> QuestInstance:
	var instance: QuestInstance = _active_instances.get(instance_id, null)
	if not instance:
		print("[QuestManager] WARNING: instance_id '%s' not found in active pool" % instance_id)
	return instance

func _get_quest(quest_id: String) -> QuestData:
	for q in database.quests:
		if q.quest_id == quest_id:
			return q
	return null

func _get_quests_for_faculty(faculty: QuestData.Faculty) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for q in database.quests:
		if q.faculty == faculty:
			result.append(q)
	return result

func _prerequisites_met(data: QuestData) -> bool:
	for req_id in data.prerequisite_quest_ids:
		if not Player_Global_Data.completed_quests.has(req_id):
			print("[QuestManager] Prerequisite '%s' not met for '%s'" % [req_id, data.quest_id])
			return false
	return true
