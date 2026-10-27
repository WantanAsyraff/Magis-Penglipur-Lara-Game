extends Node
signal quest_started(instance: QuestInstance)
signal quest_objective_updated(instance: QuestInstance, objective_id: String)
signal quest_completed(instance: QuestInstance)
signal quest_handed_off(instance: QuestInstance)
signal quest_changed(instance: QuestInstance)
signal quests_changed
signal save_finished(success: bool)
var registry: QuestRegistry
var database: QuestDatabase
var active_owner_id: String = "local"
var _active_instances: Dictionary = {}
var _npc_instance_map: Dictionary = {}
var _quest_active_count: Dictionary = {}
var reward_claims: Dictionary = {}
var seen_events: Dictionary = {}
var world_flags: Dictionary = {}
var pending_events: Array[Dictionary] = []
var selected_instance_id: String = ""
var persistence_enabled: bool = true
var save_path: String = "user://quest-progress-v2.json"
var last_error: String = ""
var _save_timer: Timer
var _claiming: bool = false
var _restoring: bool = false
var _quest_goal_lines: Array[String] = []
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persistence_enabled = "--quest-test-mode" not in OS.get_cmdline_user_args()
	registry = QuestRegistry.new()
	database = QuestDatabase.new()
	database.quests.assign(registry.quests.values())
	if not registry.errors.is_empty(): push_error("Quest registry: " + str(registry.errors))
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = .25
	add_child(_save_timer)
	_save_timer.timeout.connect(save_game)
	_bootstrap.call_deferred()
func _bootstrap() -> void:
	if persistence_enabled and FileAccess.file_exists(save_path): load_game()
func authoritative() -> bool:
	return SpellExecutor.is_authoritative(self)
func _process(_delta: float) -> void:
	if not authoritative(): return
	var now := Time.get_unix_time_from_system()
	for instance in _active_instances.values():
		if instance.status == QuestInstance.Status.ACTIVE and instance.quest_data.expires_after_seconds > 0 and now >= instance.accepted_at + instance.quest_data.expires_after_seconds:
			instance.status = QuestInstance.Status.EXPIRED
			changed(instance)
func offer_quest(quest_id: String, npc_id: String = "", owner: String = "") -> QuestInstance:
	if not authoritative() or not registry.quests.has(quest_id): return null
	if owner.is_empty(): owner = active_owner_id
	var data: QuestData = registry.quests[quest_id]
	if not _prerequisites_met(data, owner) or (not data.repeatable and is_quest_complete(quest_id, owner)): return null
	for instance in _active_instances.values():
		if instance.owner_id == owner and instance.quest_data.quest_id == quest_id and instance.status in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: return instance
	var instance := QuestInstance.new(data, npc_id, data.despawn_after_seconds, owner)
	_active_instances[instance.instance_id] = instance
	_npc_instance_map[owner + "|" + npc_id] = instance.instance_id
	_quest_active_count[quest_id] = int(_quest_active_count.get(quest_id, 0)) + 1
	changed(instance)
	return instance
func request_quest_for_npc(faculty: QuestData.Faculty, npc_id: String) -> QuestInstance:
	if not authoritative(): return null
	var existing := get_instance_for_npc(npc_id)
	if existing: return existing
	for data in _get_quests_for_faculty(faculty):
		var instance := offer_quest(data.quest_id, npc_id)
		if instance: return instance
	return null
func accept_quest(id: String, owner: String = "") -> bool:
	if not authoritative(): return false
	if owner.is_empty(): owner = active_owner_id
	var instance := get_instance(id)
	if instance == null or instance.owner_id != owner or instance.status != QuestInstance.Status.AVAILABLE or not _prerequisites_met(instance.quest_data, owner): return false
	instance.status = QuestInstance.Status.ACTIVE
	instance.accepted_at = Time.get_unix_time_from_system()
	instance.accepted_prerequisites = instance.quest_data.prerequisite_quest_ids.duplicate()
	if selected_instance_id.is_empty(): selected_instance_id = id
	QuestObjectiveEvaluator.reconcile_inventory(instance, Inventory_Manager.inventory)
	for obj in instance.quest_data.objectives:
		if obj.type == QuestObjectiveData.ObjectiveType.QUEST_COMPLETED:
			for target in obj.targets():
				if is_quest_complete(target, owner): instance.update_objective(obj.objective_id)
	quest_started.emit(instance)
	if instance.status == QuestInstance.Status.COMPLETE: quest_completed.emit(instance)
	changed(instance)
	return true
func publish(event: GameplayEvent) -> bool:
	if not authoritative() or event == null or not event.valid(): return false
	var key := event.owner_id + "|" + event.event_id
	if seen_events.has(key): return false
	seen_events[key] = true
	for instance in _active_instances.values():
		if instance.owner_id != event.owner_id: continue
		var before: int = instance.status
		var changed_ids := QuestObjectiveEvaluator.evaluate(instance, event)
		if event.type in [GameplayEvent.Type.ITEM_COLLECTED, GameplayEvent.Type.ITEM_REMOVED] and instance.owner_id == active_owner_id:
			changed_ids.append_array(QuestObjectiveEvaluator.reconcile_inventory(instance, Inventory_Manager.inventory))
		for id in changed_ids: quest_objective_updated.emit(instance, id)
		if before != QuestInstance.Status.COMPLETE and instance.status == QuestInstance.Status.COMPLETE: quest_completed.emit(instance)
		if not changed_ids.is_empty(): quest_changed.emit(instance)
	_update_goals()
	quests_changed.emit()
	schedule_save()
	return true
## Compatibility for trusted legacy callers; normal pickups publish actual acquired IDs.
func notify_item_collected(id: String, quantity: int, receipt: String = "") -> void:
	var event := GameplayEvent.new(GameplayEvent.Type.ITEM_COLLECTED, id, quantity, active_owner_id, receipt)
	if not registry.items.has(id): event.metadata.legacy_objective_id = id
	publish(event)
func update_objective(id: String, objective: String, amount: int = 1) -> void:
	if not authoritative(): return
	var instance := get_instance(id)
	if instance == null or instance.owner_id != active_owner_id: return
	var before: int = instance.status
	instance.update_objective(objective, amount)
	quest_objective_updated.emit(instance, objective)
	if before != QuestInstance.Status.COMPLETE and instance.status == QuestInstance.Status.COMPLETE: quest_completed.emit(instance)
	changed(instance)
func update_objective_by_quest(quest_id: String, objective: String, amount: int = 1) -> void:
	for instance in get_all_active():
		if instance.quest_data.quest_id == quest_id: update_objective(instance.instance_id, objective, amount)
func try_hand_off(id: String, npc_id: String = "") -> bool:
	if not authoritative() or _claiming: return false
	var instance := get_instance(id)
	if instance == null: return false
	# Old callers pass only instance_id; it still identifies the associated hand-in.
	if npc_id.is_empty(): npc_id = instance.assigned_npc_id
	_claiming = true
	var success := QuestRewardService.claim(self, instance, npc_id)
	_claiming = false
	if success and not instance.quest_data.next_quest_id.is_empty():
		var next := offer_quest(instance.quest_data.next_quest_id, npc_id, instance.owner_id)
		if next and instance.quest_data.auto_accept_next: accept_quest(next.instance_id, instance.owner_id)
	return success
func cancel_quest(id: String) -> bool:
	var instance := get_instance(id)
	if not authoritative() or instance == null or instance.owner_id != active_owner_id or instance.status not in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: return false
	instance.status = QuestInstance.Status.CANCELLED
	changed(instance)
	return true
func release_npc(npc_id: String) -> void:
	if not authoritative(): return
	for instance in _active_instances.values():
		if instance.owner_id == active_owner_id and instance.assigned_npc_id == npc_id and instance.status == QuestInstance.Status.AVAILABLE:
			instance.status = QuestInstance.Status.EXPIRED
	_npc_instance_map.erase(active_owner_id + "|" + npc_id)
	changed()
func notify_npc_despawned(id: String) -> void:
	var instance := get_instance(id)
	if instance: release_npc(instance.assigned_npc_id)
func get_instance(id: String) -> QuestInstance:
	return _active_instances.get(id)
func _get_instance(id: String) -> QuestInstance:
	return get_instance(id)
func get_instance_for_npc(npc_id: String) -> QuestInstance:
	var result: QuestInstance
	for instance in _active_instances.values():
		if instance.owner_id != active_owner_id or instance.assigned_npc_id != npc_id or instance.status not in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: continue
		if result == null or instance.status > result.status: result = instance
	return result
func get_all_active() -> Array:
	return _active_instances.values().filter(func(i): return i.owner_id == active_owner_id and i.status in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE])
func is_quest_complete(id: String, owner: String = "") -> bool:
	if owner.is_empty() or owner == active_owner_id: return id in Player_Global_Data.completed_quests
	for instance in _active_instances.values():
		if instance.owner_id == owner and instance.quest_data.quest_id == id and instance.status == QuestInstance.Status.HANDED_OFF: return true
	return false
func _get_quest(id: String) -> QuestData:
	return registry.quests.get(id)
func _get_quests_for_faculty(faculty: QuestData.Faculty) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for data in registry.quests.values():
		if data.faculty == faculty: result.append(data)
	return result
func _prerequisites_met(data: QuestData, owner: String = "") -> bool:
	for id in data.prerequisite_quest_ids:
		if not is_quest_complete(id, owner): return false
	return true
func select_quest(id: String) -> bool:
	var instance := get_instance(id)
	if instance == null or instance.owner_id != active_owner_id: return false
	selected_instance_id = id
	changed(instance)
	return true
func changed(instance: QuestInstance = null) -> void:
	if instance: quest_changed.emit(instance)
	_update_goals()
	quests_changed.emit()
	schedule_save()
func _update_goals_from_instance(_instance: QuestInstance) -> void:
	_update_goals()
func _update_goals() -> void:
	var keep: Array[String] = []
	for line in Player_Global_Data.active_goals:
		if line not in _quest_goal_lines: keep.append(line)
	_quest_goal_lines.clear()
	for instance in get_all_active():
		if instance.status not in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: continue
		if not selected_instance_id.is_empty() and instance.instance_id != selected_instance_id: continue
		_quest_goal_lines.append(instance.quest_data.title + (" — Ready for hand-in" if instance.status == QuestInstance.Status.COMPLETE else ""))
		for obj in instance.quest_data.objectives:
			_quest_goal_lines.append("%s: %d / %d%s" % [obj.description, instance.objective_progress.get(obj.objective_id, 0), obj.required_amount, " (optional)" if obj.is_optional else ""])
	Player_Global_Data.active_goals = keep + _quest_goal_lines
func schedule_save() -> void:
	if persistence_enabled and not _restoring and authoritative() and _save_timer and _save_timer.is_stopped(): _save_timer.start()
func save_game(path: String = "") -> bool:
	if not authoritative(): return false
	if path.is_empty(): path = save_path
	var payload := QuestSaveService.encode(self)
	var success := QuestSaveService.write_atomic(path, payload)
	last_error = "" if success else "Could not save quest and inventory state."
	save_finished.emit(success)
	return success
func load_game(path: String = "") -> bool:
	if not authoritative() or _claiming: return false
	if path.is_empty(): path = save_path
	if not path.begins_with("user://") or path.contains("..") or not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 32000000: return false
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not value is Dictionary: return false
	var staged := QuestSaveService.stage(self, value)
	if staged.is_empty(): return false
	_restoring = true
	_save_timer.stop()
	_active_instances = staged.instances
	_npc_instance_map.clear()
	_quest_active_count.clear()
	Inventory_Manager.inventory = staged.inventory
	Inventory_Manager.equipped = staged.equipment
	Inventory_Manager.acquisition_receipts = value.acquisition_receipts.duplicate()
	Inventory_Manager.max_slots = int(value.max_slots)
	Player_Global_Data.player_exp = value.player_xp
	Player_Global_Data.p_curr_ringgit = value.currency
	Player_Global_Data.completed_quests.assign(value.completed_quests)
	Player_Global_Data.learned_spells = staged.learned
	reward_claims = value.claims.duplicate(true)
	seen_events = value.seen_events.duplicate()
	world_flags = value.world_flags.duplicate()
	pending_events.assign(value.get("pending_events", []))
	selected_instance_id = String(value.get("selected_quest", ""))
	for instance in _active_instances.values():
		if instance.status in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: QuestObjectiveEvaluator.reconcile_inventory(instance, Inventory_Manager.inventory)
	_restoring = false
	drain_outbox()
	changed()
	Player_Global_Data.spells_updated.emit()
	return true
func publish_flag_event(id: String, value: bool, receipt: String = "") -> void:
	var event := GameplayEvent.new(GameplayEvent.Type.WORLD_FLAG_CHANGED, id, 1, active_owner_id, receipt)
	event.metadata.value = value
	publish(event)
func set_world_flag(id: String, value: bool) -> bool:
	if not authoritative() or id.is_empty(): return false
	if world_flags.get(id) == value: return false
	world_flags[id] = value
	publish_flag_event(id, value)
	return true
func drain_outbox() -> void:
	while not pending_events.is_empty():
		var row: Dictionary = pending_events.pop_front()
		var event := GameplayEvent.from_dict(row)
		if event: publish(event)
