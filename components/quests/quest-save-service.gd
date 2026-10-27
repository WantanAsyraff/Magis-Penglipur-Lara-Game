class_name QuestSaveService extends RefCounted
const VERSION = 2
static func encode(manager: Node) -> Dictionary:
	var inventory: Array = []
	for id in Inventory_Manager.inventory:
		if not manager.registry.items.has(id): return {}
		inventory.append({"item_id": id, "quantity": Inventory_Manager.get_item_quantity(id)})
	var equipment := {}
	for slot in Inventory_Manager.equipped:
		var item: ItemData = Inventory_Manager.equipped[slot]
		if item and not manager.registry.items.has(item.item_id): return {}
		equipment[str(slot)] = item.item_id if item else ""
	var instances: Array = []
	for instance in manager._active_instances.values():
		if instance.owner_id == manager.active_owner_id and manager.registry.quests.has(instance.quest_data.quest_id): instances.append(instance.to_dict())
	var learned: Array[String] = []
	for spell in Player_Global_Data.learned_spells:
		if GameplayEvent.service("Spell_Library").call("get_spell_by_id", spell.spell_id): learned.append(spell.spell_id)
	return {"version": VERSION, "owner_id": manager.active_owner_id, "instances": instances, "completed_quests": Player_Global_Data.completed_quests.duplicate(), "claims": manager.reward_claims.duplicate(true), "seen_events": manager.seen_events.duplicate(), "selected_quest": manager.selected_instance_id, "world_flags": manager.world_flags.duplicate(), "pending_events": manager.pending_events.duplicate(true), "inventory": inventory, "equipment": equipment, "acquisition_receipts": Inventory_Manager.acquisition_receipts.duplicate(), "max_slots": Inventory_Manager.max_slots, "player_xp": Player_Global_Data.player_exp, "currency": Player_Global_Data.p_curr_ringgit, "learned_spells": learned}
static func stage(manager: Node, data: Dictionary) -> Dictionary:
	if data.get("version", 0) != VERSION or data.get("owner_id", "") != manager.active_owner_id: return {}
	for key in ["instances", "inventory", "completed_quests", "learned_spells"]:
		if not data.get(key) is Array: return {}
	for key in ["claims", "seen_events", "world_flags", "acquisition_receipts", "equipment"]:
		if not data.get(key) is Dictionary: return {}
	for key in ["player_xp", "currency"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(float(data[key])) or float(data[key]) < 0: return {}
	var staged_inventory := {}
	var max_slots := int(data.get("max_slots", 64))
	if max_slots < 1 or max_slots > 10000: return {}
	for entry in data.inventory:
		if not entry is Dictionary: return {}
		var id := String(entry.get("item_id", ""))
		var qty := int(entry.get("quantity", 0))
		if not manager.registry.items.has(id) or staged_inventory.has(id): return {}
		var item: ItemData = manager.registry.items[id]
		if qty < 1 or qty > (item.max_stack if item.is_stackable else 1): return {}
		staged_inventory[id] = {"data": item, "quantity": qty}
	if staged_inventory.size() > max_slots: return {}
	if not data.get("pending_events", []) is Array: return {}
	for row in data.get("pending_events", []):
		if not row is Dictionary or GameplayEvent.from_dict(row) == null: return {}
	var instances := {}
	for row in data.instances:
		if not row is Dictionary: return {}
		var quest_id := String(row.get("quest_id", ""))
		if not manager.registry.quests.has(quest_id) or row.get("owner_id", "") != manager.active_owner_id: return {}
		var quest: QuestData = manager.registry.quests[quest_id]
		var instance := QuestInstance.new(quest, String(row.get("assigned_npc_id", "")), -1, manager.active_owner_id)
		instance.instance_id = String(row.get("instance_id", ""))
		if instance.instance_id.is_empty() or instances.has(instance.instance_id): return {}
		var state := int(row.get("status", -1))
		if state < 0 or state >= QuestInstance.Status.size() or not row.get("objective_progress") is Dictionary: return {}
		instance.status = state as QuestInstance.Status
		for obj in quest.objectives:
			var progress := int(row.objective_progress.get(obj.objective_id, 0))
			if progress < 0 or progress > obj.required_amount: return {}
			instance.objective_progress[obj.objective_id] = progress
		instance.reward_claimed = bool(row.get("reward_claimed", false))
		if (state == QuestInstance.Status.HANDED_OFF) != instance.reward_claimed: return {}
		if instance.reward_claimed and not data.claims.has(instance.instance_id): return {}
		instance.accepted_at = float(row.get("accepted_at", 0))
		instance.completed_at = float(row.get("completed_at", 0))
		instance.pending_claim = String(row.get("pending_claim", ""))
		instance.selected_branch = String(row.get("selected_branch", ""))
		instance.accepted_prerequisites.assign(row.get("accepted_prerequisites", []))
		instance._despawn_time = float(row.get("despawn_time", -1))
		instances[instance.instance_id] = instance
	var equipment := {}
	for slot in Inventory_Manager.SlotType.values():
		var id := String(data.equipment.get(str(slot), ""))
		if not id.is_empty() and not manager.registry.items.has(id): return {}
		equipment[slot] = manager.registry.items.get(id)
	var learned: Array[SpellData] = []
	for id in data.learned_spells:
		var spell: SpellData = GameplayEvent.service("Spell_Library").call("get_spell_by_id", String(id))
		if spell == null: return {}
		learned.append(spell)
	return {"instances": instances, "inventory": staged_inventory, "equipment": equipment, "learned": learned, "data": data}
static func write_atomic(path: String, data: Dictionary) -> bool:
	if data.is_empty() or not path.begins_with("user://") or path.contains("..") or path.length() > 512: return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK
