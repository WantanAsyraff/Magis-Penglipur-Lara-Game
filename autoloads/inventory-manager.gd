extends Node
enum SlotType { WEAPON, OFFHAND, ROBE, ACCESSORY_1, ACCESSORY_2 }
signal inventory_changed(item: ItemData, new_quantity: int)
signal equipment_changed(slot: SlotType, item: ItemData)
var inventory: Dictionary = {}
var equipped: Dictionary = {}
var acquisition_receipts: Dictionary = {}
var max_slots: int = 64
var favorites: Dictionary = {}
## Pending world drops reserve their original capacity; loading/scene exit returns them.
var drop_escrow: Dictionary = {}
signal preferences_changed
var _acting := false
func _ready() -> void:
	for slot in SlotType.values(): equipped[slot] = null
func snapshot() -> Dictionary:
	var result := {}
	for id in inventory: result[id] = {"data": inventory[id].data, "quantity": inventory[id].quantity}
	return result
func valid_item(item: ItemData) -> bool:
	return item != null and not item.item_id.is_empty() and item.max_stack > 0
func can_add_item(item: ItemData, qty: int = 1) -> bool:
	return valid_item(item) and qty > 0 and (reserved_ids().has(item.item_id) or reserved_ids().size() < max_slots) and get_item_quantity(item.item_id) + reserved_quantity(item.item_id) + qty <= (item.max_stack if item.is_stackable else 1)
func add_item(item: ItemData, qty: int = 1, receipt: String = "", owner: String = "") -> int:
	if QuestManager._restoring: return 0
	if not SpellExecutor.is_authoritative(self) or not valid_item(item) or qty <= 0: return 0
	if owner.is_empty(): owner = QuestManager.active_owner_id
	if owner != QuestManager.active_owner_id or (not receipt.is_empty() and acquisition_receipts.has(receipt)): return 0
	if not reserved_ids().has(item.item_id) and reserved_ids().size() >= max_slots: return 0
	var accepted := mini(qty, (item.max_stack if item.is_stackable else 1) - get_item_quantity(item.item_id) - reserved_quantity(item.item_id))
	if accepted <= 0: return 0
	var event := GameplayEvent.new(GameplayEvent.Type.ITEM_COLLECTED, item.item_id, accepted, owner, receipt)
	inventory[item.item_id] = {"data": item, "quantity": get_item_quantity(item.item_id) + accepted}
	acquisition_receipts[event.event_id] = accepted
	inventory_changed.emit(item, get_item_quantity(item.item_id))
	event.tags = item.tags.duplicate()
	QuestManager.publish(event)
	return accepted
func pickup(item: ItemData, qty: int = 1, receipt: String = "", owner: String = "") -> int:
	if item and item.spell_to_unlock and Spell_Library.get_spell_by_id(item.spell_to_unlock.spell_id) != item.spell_to_unlock: return 0
	var accepted := add_item(item, qty, receipt, owner)
	if accepted <= 0: return 0
	if item.use_behavior == ItemData.UseBehavior.ACQUISITION_REWARD or item.use_behavior == ItemData.UseBehavior.AUTOMATIC_COMPATIBILITY:
		var reward_id := "acquisition-reward:"+item.item_id
		if not acquisition_receipts.has(reward_id):
			acquisition_receipts[reward_id] = 1
			if item.exp_reward > 0: Player_Global_Data.player_exp += item.exp_reward
			if item.spell_to_unlock: Player_Global_Data.add_spell(item.spell_to_unlock)
			if item.use_behavior == ItemData.UseBehavior.ACQUISITION_REWARD:
				if item.health_restore > 0: Player_Global_Data.restore_health(item.health_restore)
				if item.mana_restore > 0: Player_Global_Data.restore_mana(item.mana_restore)
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
		if total+reserved_quantity(item.item_id) > (item.max_stack if item.is_stackable else 1) or (not planned.has(item.item_id) and not reserved_ids(planned).has(item.item_id) and reserved_ids(planned).size() >= max_slots): return {"ok": false, "error": "Inventory full. Make room and claim again."}
		planned[item.item_id] = {"data": item, "quantity": total}
	return {"ok": true, "inventory": planned}
func emit_changes(before: Dictionary, receipt_prefix: String = "", transfer: bool = false) -> void:
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
		event.metadata.inventory_transfer = transfer
		QuestManager.publish(event)
func equip_item(item: ItemData, slot: SlotType) -> ItemActionResult:
	var reason := action_context()
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	if not registered(item) or not item.supports_slot(slot): return ItemActionResult.failure("This item is incompatible with that slot.")
	var additions: Array = []
	if equipped[slot]: additions.append({"item":equipped[slot],"quantity":1})
	var plan := plan_transaction({item.item_id:1},additions)
	if not plan.ok: return ItemActionResult.failure(plan.error)
	_acting = true
	var before := snapshot(); inventory = plan.inventory; equipped[slot] = item
	emit_changes(before,"",true); equipment_changed.emit(slot,item); _acting = false; _request_save()
	return ItemActionResult.success("Equipped "+item.item_name)
func unequip_item(slot: SlotType) -> ItemActionResult:
	var reason := action_context()
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	var item: ItemData = equipped.get(slot)
	if item == null: return ItemActionResult.failure("This slot is empty.")
	var plan := plan_transaction({},[{"item":item,"quantity":1}])
	if not plan.ok: return ItemActionResult.failure(plan.error)
	_acting = true
	var before := snapshot(); inventory = plan.inventory; equipped[slot] = null
	emit_changes(before,"",true); equipment_changed.emit(slot,null); _acting = false; _request_save()
	return ItemActionResult.success("Returned "+item.item_name)
func get_equipped(slot: SlotType) -> ItemData:
	return equipped.get(slot)
func is_slot_empty(slot: SlotType) -> bool:
	return equipped.get(slot) == null
func reset() -> void:
	inventory.clear()
	favorites.clear(); drop_escrow.clear()
	acquisition_receipts.clear()
	for slot in SlotType.values(): equipped[slot] = null
	preferences_changed.emit()

func registered(item: ItemData) -> bool:
	return valid_item(item) and item.validate().is_empty() and QuestManager.registry.items.get(item.item_id) == item and (item.spell_to_unlock == null or Spell_Library.get_spell_by_id(item.spell_to_unlock.spell_id) == item.spell_to_unlock)
func action_context() -> String:
	if _acting or QuestManager._restoring or SaveManager.loading: return "Inventory is restoring or busy."
	if not SpellExecutor.is_authoritative(self): return "Inventory requires local gameplay authority."
	if Dialogic.current_timeline != null or QuestOfferDialog.is_open() or SceneManager.is_transitioning: return "Finish the current story interaction first."
	if is_instance_valid(ModalService.holder) and ModalService.holder != InventoryOverlay.ui: return "Close the current exclusive menu first."
	if not Player_Global_Data.p_moveable and not is_instance_valid(InventoryOverlay.ui): return "Player control is reserved by the story."
	if not Player_Global_Data.is_alive(): return "Items cannot be managed while defeated."
	return ""
func _request_save() -> void:
	QuestManager.schedule_save(); SaveManager.request_autosave()
func use_reason(item: ItemData) -> String:
	if not registered(item) or not item.manual_use(): return "This item cannot be used."
	var meaningful := (item.health_restore > 0 and Player_Global_Data.p_curr_health < Player_Global_Data.p_max_health) or (item.mana_restore > 0 and Player_Global_Data.p_curr_mana < Player_Global_Data.p_max_mana) or (item.exp_reward > 0 and item.use_behavior == ItemData.UseBehavior.MANUAL) or (item.spell_to_unlock != null and not Player_Global_Data.has_spell(item.spell_to_unlock))
	if not meaningful and not item.allow_wasted_use: return "No effect needed: health/mana is full or the spell is already learned."
	if item.health_restore <= 0 and item.mana_restore <= 0 and item.exp_reward <= 0 and item.spell_to_unlock == null: return "This item has no supported use effect."
	return ""
func use_item(id: String) -> ItemActionResult:
	var reason := action_context()
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	var item: ItemData = QuestManager.registry.items.get(id)
	reason = use_reason(item)
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	if not has_item(id): return ItemActionResult.failure("This item is no longer held.")
	_acting = true
	var before := snapshot(); inventory[id].quantity -= 1
	if inventory[id].quantity == 0: inventory.erase(id)
	if item.health_restore > 0: Player_Global_Data.restore_health(item.health_restore)
	if item.mana_restore > 0: Player_Global_Data.restore_mana(item.mana_restore)
	if item.use_behavior == ItemData.UseBehavior.MANUAL and item.exp_reward > 0: Player_Global_Data.player_exp += item.exp_reward
	if item.spell_to_unlock: Player_Global_Data.add_spell(item.spell_to_unlock)
	emit_changes(before); _acting = false; _request_save()
	return ItemActionResult.success("Used "+item.item_name)
func toggle_favorite(id: String) -> bool:
	if not action_context().is_empty() or not QuestManager.registry.items.has(id): return false
	if favorites.has(id): favorites.erase(id)
	else: favorites[id] = true
	preferences_changed.emit(); _request_save(); return true
func reserved_quantity(id: String) -> int:
	var qty := 0
	for row in drop_escrow.values():
		if row.item_id == id: qty += int(row.quantity)
	return qty
func reserved_ids(held: Variant = null) -> Dictionary:
	if held == null: held = inventory
	var ids := {}
	for id in held: ids[id] = true
	for row in drop_escrow.values(): ids[row.item_id] = true
	return ids
func drop_reason(item: ItemData) -> String:
	if not registered(item) or not item.can_drop: return "This item cannot be dropped."
	if item.item_type in [ItemData.ItemType.KEY_ITEM,ItemData.ItemType.QUEST_ITEM]: return "Quest and key items cannot be dropped."
	return ""
func drop_item(id: String, qty: int = 1) -> ItemActionResult:
	var reason := action_context()
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	var item: ItemData = QuestManager.registry.items.get(id)
	reason = drop_reason(item)
	if not reason.is_empty(): return ItemActionResult.failure(reason)
	if qty < 1 or not has_item(id,qty): return ItemActionResult.failure("The requested quantity is no longer held.")
	var player := Player_Manager.get_local_player() as Player
	if player == null or not player.is_inside_tree(): return ItemActionResult.failure("A live world player is required.")
	var safe := Vector2.INF
	for offset in [Vector2(240,-40),Vector2(-240,-40),Vector2(0,-200)]:
		var query := PhysicsShapeQueryParameters2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(114,122)
		query.shape = shape; query.transform = Transform2D(0,player.global_position+offset); query.collision_mask = 16
		var ray := PhysicsRayQueryParameters2D.create(player.global_position,player.global_position+offset,16,[player.get_rid()])
		if player.get_world_2d().direct_space_state.intersect_shape(query).is_empty() and player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): safe = player.global_position+offset; break
	if not safe.is_finite(): return ItemActionResult.failure("No safe space nearby for the dropped item.")
	var packed := load("res://components/loot/dropped-item/dropped-item.tscn") as PackedScene
	if packed == null: return ItemActionResult.failure("World pickup could not be created.")
	var drop := packed.instantiate() as DroppedItem
	if drop == null: return ItemActionResult.failure("World pickup has an invalid root.")
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	drop.loot_data = LootData.new(); drop.loot_data.item = item; drop.quantity = qty; drop.player_drop_id = token; drop.loot_owner_id = QuestManager.active_owner_id
	drop.position = player.get_parent().to_local(safe) if player.get_parent() is Node2D else safe
	_acting = true
	var before := snapshot()
	drop_escrow[token] = {"item_id":id,"quantity":qty}
	inventory[id].quantity -= qty
	if inventory[id].quantity == 0: inventory.erase(id)
	player.get_parent().add_child(drop)
	if not drop.is_inside_tree():
		inventory = before; drop_escrow.erase(token); drop.free(); _acting = false; return ItemActionResult.failure("World pickup spawn failed.")
	emit_changes(before,"",true); _acting = false; _request_save()
	return ItemActionResult.success("Dropped %d × %s. Reserved items return on load or area exit." % [qty,item.item_name],drop)
func reclaim_drop(token: String) -> int:
	if not SpellExecutor.is_authoritative(self) or not drop_escrow.has(token) or QuestManager._restoring or SaveManager.loading: return 0
	var row: Dictionary = drop_escrow[token]; var item: ItemData = QuestManager.registry.items.get(row.item_id)
	if item == null: return 0
	var before := snapshot(); drop_escrow.erase(token)
	inventory[item.item_id] = {"data":item,"quantity":get_item_quantity(item.item_id)+int(row.quantity)}
	emit_changes(before,"",true); _request_save(); return int(row.quantity)
