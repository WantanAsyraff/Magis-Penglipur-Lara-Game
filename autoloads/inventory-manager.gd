extends Node
enum SlotType { WEAPON, OFFHAND, ROBE, ACCESSORY_1, ACCESSORY_2 }
signal inventory_changed(item: ItemData, new_quantity: int)
signal equipment_changed(slot: SlotType, item: ItemData)
var inventory: Dictionary = {}
var equipped: Dictionary = {}
var acquisition_receipts: Dictionary = {}
var max_slots: int = 64
func _ready() -> void:
	for slot in SlotType.values(): equipped[slot] = null
func snapshot() -> Dictionary:
	var result := {}
	for id in inventory: result[id] = {"data": inventory[id].data, "quantity": inventory[id].quantity}
	return result
func valid_item(item: ItemData) -> bool:
	return item != null and not item.item_id.is_empty() and item.max_stack > 0
func can_add_item(item: ItemData, qty: int = 1) -> bool:
	return valid_item(item) and qty > 0 and (inventory.has(item.item_id) or inventory.size() < max_slots) and get_item_quantity(item.item_id) + qty <= (item.max_stack if item.is_stackable else 1)
func add_item(item: ItemData, qty: int = 1, receipt: String = "", owner: String = "") -> int:
	if QuestManager._restoring: return 0
	if not SpellExecutor.is_authoritative(self) or not valid_item(item) or qty <= 0: return 0
	if owner.is_empty(): owner = QuestManager.active_owner_id
	if owner != QuestManager.active_owner_id or (not receipt.is_empty() and acquisition_receipts.has(receipt)): return 0
	if not inventory.has(item.item_id) and inventory.size() >= max_slots: return 0
	var accepted := mini(qty, (item.max_stack if item.is_stackable else 1) - get_item_quantity(item.item_id))
	if accepted <= 0: return 0
	var event := GameplayEvent.new(GameplayEvent.Type.ITEM_COLLECTED, item.item_id, accepted, owner, receipt)
	inventory[item.item_id] = {"data": item, "quantity": get_item_quantity(item.item_id) + accepted}
	acquisition_receipts[event.event_id] = accepted
	inventory_changed.emit(item, get_item_quantity(item.item_id))
	event.tags = item.tags.duplicate()
	QuestManager.publish(event)
	return accepted
func pickup(item: ItemData, qty: int = 1, receipt: String = "", owner: String = "") -> int:
	var accepted := add_item(item, qty, receipt, owner)
	if accepted <= 0: return 0
	if item.health_restore > 0: Player_Global_Data.restore_health(item.health_restore * accepted)
	if item.mana_restore > 0: Player_Global_Data.restore_mana(item.mana_restore * accepted)
	if item.exp_reward > 0: Player_Global_Data.player_exp += item.exp_reward * accepted
	if item.spell_to_unlock: Player_Global_Data.add_spell(item.spell_to_unlock)
	QuestManager.schedule_save()
	return accepted
func remove_item(item: ItemData, qty: int = 1) -> bool:
	if not SpellExecutor.is_authoritative(self) or not valid_item(item) or qty <= 0 or not has_item(item.item_id, qty): return false
	var before := snapshot()
	inventory[item.item_id].quantity -= qty
	if inventory[item.item_id].quantity <= 0: inventory.erase(item.item_id)
	emit_changes(before)
	return true
func get_item_quantity(id: String) -> int:
	return int(inventory.get(id, {}).get("quantity", 0))
func has_item(id: String, qty: int = 1) -> bool:
	return qty > 0 and get_item_quantity(id) >= qty
func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for entry in inventory.values(): result.append(entry.data)
	return result
## Pure atomic preflight used by rewards, delivery, crafting and equipment swaps.
func plan_transaction(removals: Dictionary, additions: Array) -> Dictionary:
	var planned := snapshot()
	for id in removals:
		var qty := int(removals[id])
		if qty <= 0 or int(planned.get(id, {}).get("quantity", 0)) < qty: return {"ok": false, "error": "Required items are no longer held."}
		planned[id].quantity -= qty
		if planned[id].quantity == 0: planned.erase(id)
	for entry in additions:
		var item: ItemData = entry.item
		var qty := int(entry.quantity)
		if not valid_item(item) or qty <= 0: return {"ok": false, "error": "Invalid inventory transaction."}
		var total := int(planned.get(item.item_id, {}).get("quantity", 0)) + qty
		if total > (item.max_stack if item.is_stackable else 1) or (not planned.has(item.item_id) and planned.size() >= max_slots): return {"ok": false, "error": "Inventory full. Make room and claim again."}
		planned[item.item_id] = {"data": item, "quantity": total}
	return {"ok": true, "inventory": planned}
func emit_changes(before: Dictionary, receipt_prefix: String = "") -> void:
	var ids: Array = before.keys()
	for id in inventory:
		if id not in ids: ids.append(id)
	for id in ids:
		var old := int(before.get(id, {}).get("quantity", 0))
		var current := get_item_quantity(id)
		if current == old: continue
		var item: ItemData = inventory.get(id, before.get(id, {})).data
		inventory_changed.emit(item, current)
		var event := GameplayEvent.new(GameplayEvent.Type.ITEM_COLLECTED if current > old else GameplayEvent.Type.ITEM_REMOVED, id, absi(current - old), QuestManager.active_owner_id, receipt_prefix + ":" + id if not receipt_prefix.is_empty() else "")
		event.tags = item.tags.duplicate()
		QuestManager.publish(event)
func equip_item(item: ItemData, slot: SlotType) -> void:
	if not SpellExecutor.is_authoritative(self) or not valid_item(item) or not equipped.has(slot): return
	var additions: Array = []
	if equipped[slot]: additions.append({"item": equipped[slot], "quantity": 1})
	var plan := plan_transaction({item.item_id: 1}, additions)
	if not plan.ok: return
	var before := snapshot()
	inventory = plan.inventory
	equipped[slot] = item
	emit_changes(before)
	equipment_changed.emit(slot, item)
func unequip_item(slot: SlotType) -> void:
	if not SpellExecutor.is_authoritative(self) or not equipped.has(slot) or equipped[slot] == null: return
	var item: ItemData = equipped[slot]
	if not can_add_item(item): return
	equipped[slot] = null
	add_item(item)
	equipment_changed.emit(slot, null)
func get_equipped(slot: SlotType) -> ItemData:
	return equipped.get(slot)
func is_slot_empty(slot: SlotType) -> bool:
	return equipped.get(slot) == null
func reset() -> void:
	inventory.clear()
	acquisition_receipts.clear()
	for slot in SlotType.values(): equipped[slot] = null
