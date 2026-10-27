class_name QuestObjectiveEvaluator extends RefCounted
const EVENT_TYPES = {
	QuestObjectiveData.ObjectiveType.TALK_TO_NPC: GameplayEvent.Type.NPC_INTERACTED,
	QuestObjectiveData.ObjectiveType.COLLECT_ITEM: GameplayEvent.Type.ITEM_COLLECTED,
	QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY: GameplayEvent.Type.ENEMY_DEFEATED,
	QuestObjectiveData.ObjectiveType.REACH_LOCATION: GameplayEvent.Type.LOCATION_REACHED,
	QuestObjectiveData.ObjectiveType.SPELL_CAST: GameplayEvent.Type.SPELL_CAST,
	QuestObjectiveData.ObjectiveType.SPELL_HIT: GameplayEvent.Type.SPELL_HIT,
	QuestObjectiveData.ObjectiveType.STATUS_APPLIED: GameplayEvent.Type.STATUS_APPLIED,
	QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED: GameplayEvent.Type.OBJECT_INTERACTED,
	QuestObjectiveData.ObjectiveType.QUEST_COMPLETED: GameplayEvent.Type.QUEST_COMPLETED,
	QuestObjectiveData.ObjectiveType.WORLD_FLAG_CHANGED: GameplayEvent.Type.WORLD_FLAG_CHANGED,
	QuestObjectiveData.ObjectiveType.DIALOGUE_COMPLETED: GameplayEvent.Type.DIALOGUE_COMPLETED,
}
static func matches(obj: QuestObjectiveData, event: GameplayEvent) -> bool:
	if EVENT_TYPES.get(obj.type, -1) != event.type: return false
	var target_match := event.target_id in obj.targets()
	for tag in obj.target_tags:
		if tag in event.tags: target_match = true
	if event.metadata.get("legacy_objective_id", "") == obj.objective_id: target_match = true
	if not target_match: return false
	for key in obj.match_metadata:
		if event.metadata.get(key) != obj.match_metadata[key]: return false
	return true
static func evaluate(instance: QuestInstance, event: GameplayEvent) -> Array[String]:
	var changed: Array[String] = []
	if instance.owner_id != event.owner_id or instance.status not in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: return changed
	# Snapshot eligibility prevents one event satisfying successive ordered objectives.
	var eligible: Array[QuestObjectiveData] = []
	for obj in instance.quest_data.objectives:
		if instance.eligible(obj): eligible.append(obj)
	for obj in eligible:
		if obj.type == QuestObjectiveData.ObjectiveType.COLLECT_ITEM and obj.collection_mode != QuestObjectiveData.CollectionMode.CUMULATIVE: continue
		if instance.status == QuestInstance.Status.COMPLETE and not obj.is_optional: continue
		if matches(obj, event):
			var before := int(instance.objective_progress.get(obj.objective_id, 0))
			instance.objective_progress[obj.objective_id] = mini(obj.required_amount, before + event.quantity)
			if instance.objective_progress[obj.objective_id] != before: changed.append(obj.objective_id)
	instance.reconcile()
	return changed
static func reconcile_inventory(instance: QuestInstance, inventory: Dictionary) -> Array[String]:
	var changed: Array[String] = []
	if instance.status not in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]: return changed
	for obj in instance.quest_data.objectives:
		if obj.type != QuestObjectiveData.ObjectiveType.COLLECT_ITEM or obj.collection_mode == QuestObjectiveData.CollectionMode.CUMULATIVE: continue
		var quantity := 0
		if instance.eligible(obj):
			for id in obj.targets(): quantity += int(inventory.get(id, {}).get("quantity", 0))
		quantity = mini(quantity, obj.required_amount)
		if instance.objective_progress.get(obj.objective_id, 0) != quantity:
			instance.objective_progress[obj.objective_id] = quantity
			changed.append(obj.objective_id)
	instance.reconcile()
	return changed
