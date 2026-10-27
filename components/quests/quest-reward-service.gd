class_name QuestRewardService extends RefCounted
static func claim(manager: Node, instance: QuestInstance, npc_id: String) -> bool:
	if instance.owner_id != manager.active_owner_id or instance.status != QuestInstance.Status.COMPLETE or instance.reward_claimed or manager.reward_claims.has(instance.instance_id): return false
	var required_npc := instance.quest_data.hand_in_npc_id if not instance.quest_data.hand_in_npc_id.is_empty() else instance.assigned_npc_id
	if not required_npc.is_empty() and npc_id != required_npc: return false
	QuestObjectiveEvaluator.reconcile_inventory(instance, Inventory_Manager.inventory)
	if not instance.is_objectives_met(): return false
	var removals := delivery_plan(instance)
	if removals.has("__error"): instance.pending_claim = String(removals.__error); return false
	var additions: Array = []
	for reward in instance.quest_data.reward_items: additions.append({"item": reward.item, "quantity": reward.min_quantity})
	var plan: Dictionary = Inventory_Manager.plan_transaction(removals, additions)
	if not plan.ok: instance.pending_claim = plan.error; manager.changed(instance); return false
	# Stage all value and claim mutations in one durable snapshot. No signals until commit.
	var before_pending: Array[Dictionary] = manager.pending_events.duplicate(true)
	var before_receipts: Dictionary = Inventory_Manager.acquisition_receipts.duplicate()
	var before_inventory := Inventory_Manager.snapshot()
	var before_xp: float = Player_Global_Data.player_exp
	var before_currency: float = Player_Global_Data.p_curr_ringgit
	var before_completed: Array[String] = Player_Global_Data.completed_quests.duplicate()
	var before_flags: Dictionary = manager.world_flags.duplicate()
	var before_learned: Array[SpellData] = Player_Global_Data.learned_spells.duplicate()
	Inventory_Manager.inventory = plan.inventory
	Player_Global_Data.player_exp += instance.quest_data.reward_xp
	Player_Global_Data.p_curr_ringgit += instance.quest_data.reward_currency
	if instance.quest_data.quest_id not in Player_Global_Data.completed_quests: Player_Global_Data.completed_quests.append(instance.quest_data.quest_id)
	for spell in instance.quest_data.reward_spells:
		if spell not in Player_Global_Data.learned_spells: Player_Global_Data.learned_spells.append(spell)
	for flag in instance.quest_data.reward_flags: manager.world_flags[String(flag)] = instance.quest_data.reward_flags[flag]
	instance.reward_claimed = true
	instance.status = QuestInstance.Status.HANDED_OFF
	instance.pending_claim = ""
	manager.reward_claims[instance.instance_id] = {"owner_id": instance.owner_id, "quest_id": instance.quest_data.quest_id}
	var ids: Array = before_inventory.keys()
	for id in Inventory_Manager.inventory:
		if id not in ids: ids.append(id)
	for id in ids:
		var delta := Inventory_Manager.get_item_quantity(id) - int(before_inventory.get(id, {}).get("quantity", 0))
		if delta == 0: continue
		var event := GameplayEvent.new(GameplayEvent.Type.ITEM_COLLECTED if delta > 0 else GameplayEvent.Type.ITEM_REMOVED, id, absi(delta), instance.owner_id, "reward:" + instance.instance_id + ":" + id)
		manager.pending_events.append(event.to_dict())
		if delta > 0: Inventory_Manager.acquisition_receipts[event.event_id] = delta
	manager.pending_events.append(GameplayEvent.new(GameplayEvent.Type.QUEST_COMPLETED, instance.quest_data.quest_id, 1, instance.owner_id, "quest:" + instance.instance_id).to_dict())
	for flag in instance.quest_data.reward_flags:
		var event := GameplayEvent.new(GameplayEvent.Type.WORLD_FLAG_CHANGED, String(flag), 1, instance.owner_id, "reward_flag:" + instance.instance_id + ":" + String(flag))
		event.metadata.value = instance.quest_data.reward_flags[flag]
		manager.pending_events.append(event.to_dict())
	if manager.persistence_enabled and not manager.save_game():
		manager.pending_events = before_pending
		Inventory_Manager.acquisition_receipts = before_receipts
		Inventory_Manager.inventory = before_inventory
		Player_Global_Data.player_exp = before_xp
		Player_Global_Data.p_curr_ringgit = before_currency
		Player_Global_Data.completed_quests = before_completed
		Player_Global_Data.learned_spells = before_learned
		manager.world_flags = before_flags
		manager.reward_claims.erase(instance.instance_id)
		instance.reward_claimed = false
		instance.status = QuestInstance.Status.COMPLETE
		instance.pending_claim = "Could not save rewards. Retry after checking storage."
		manager.changed(instance)
		return false
	Inventory_Manager.emit_changes(before_inventory, "reward:" + instance.instance_id)
	Player_Global_Data.spells_updated.emit()
	manager.quest_handed_off.emit(instance)
	manager.drain_outbox()
	manager.changed(instance)
	return true
static func delivery_plan(instance: QuestInstance) -> Dictionary:
	var objectives: Array[QuestObjectiveData] = []
	for obj in instance.quest_data.objectives:
		if obj.type == QuestObjectiveData.ObjectiveType.COLLECT_ITEM and obj.collection_mode == QuestObjectiveData.CollectionMode.DELIVERY and not obj.is_optional: objectives.append(obj)
	objectives.sort_custom(func(a, b): return a.targets().size() < b.targets().size())
	var available := {}
	for id in Inventory_Manager.inventory: available[id] = Inventory_Manager.get_item_quantity(id)
	var removals := {}
	for obj in objectives:
		var remaining := obj.required_amount
		for id in obj.targets():
			var take := mini(remaining, int(available.get(id, 0)))
			if take > 0:
				removals[id] = int(removals.get(id, 0)) + take
				available[id] -= take
				remaining -= take
		if remaining > 0: return {"__error": "Delivery requirements overlap or items are missing."}
	return removals
