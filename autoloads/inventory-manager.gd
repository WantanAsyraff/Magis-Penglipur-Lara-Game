# inventory_manager.gd
extends Node

# -------------------------
# ENUMS
# -------------------------
enum SlotType { WEAPON, OFFHAND, ROBE, ACCESSORY_1, ACCESSORY_2 }

# -------------------------
# SIGNALS
# -------------------------
signal inventory_changed(item: ItemData, new_quantity: int)
signal equipment_changed(slot: SlotType, item: ItemData)

# -------------------------
# STATE
# -------------------------
# item_id -> { "data": ItemData, "quantity": int }
var inventory: Dictionary = {}
# SlotType -> ItemData (null = empty)
var equipped: Dictionary = {}

func _ready() -> void:
	for slot in SlotType.values():
		equipped[slot] = null

# -------------------------
# BAG
# -------------------------
func add_item(item: ItemData, qty: int = 1) -> void:
	if inventory.has(item.item_id):
		var current: int = inventory[item.item_id]["quantity"]
		var space: int = item.max_stack - current
		inventory[item.item_id]["quantity"] += mini(qty, space)
	else:
		inventory[item.item_id] = { "data": item, "quantity": mini(qty, item.max_stack) }
	inventory_changed.emit(item, inventory[item.item_id]["quantity"])

func remove_item(item: ItemData, qty: int = 1) -> bool:
	if not has_item(item.item_id, qty):
		return false
	inventory[item.item_id]["quantity"] -= qty
	if inventory[item.item_id]["quantity"] <= 0:
		inventory.erase(item.item_id)
		inventory_changed.emit(item, 0)
	else:
		inventory_changed.emit(item, inventory[item.item_id]["quantity"])
	return true

func get_item_quantity(item_id: String) -> int:
	return inventory[item_id]["quantity"] if inventory.has(item_id) else 0

func has_item(item_id: String, qty: int = 1) -> bool:
	return get_item_quantity(item_id) >= qty

func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for entry in inventory.values():
		result.append(entry["data"])
	return result

# -------------------------
# EQUIPMENT
# -------------------------
func equip_item(item: ItemData, slot: SlotType) -> void:
	var current: ItemData = equipped[slot]
	if current != null:
		add_item(current)
	if not remove_item(item):
		push_error("InventoryManager: tried to equip item not in inventory: " + item.item_id)
		return
	equipped[slot] = item
	equipment_changed.emit(slot, item)

func unequip_item(slot: SlotType) -> void:
	var item: ItemData = equipped[slot]
	if item == null:
		return
	add_item(item)
	equipped[slot] = null
	equipment_changed.emit(slot, null)

func get_equipped(slot: SlotType) -> ItemData:
	return equipped[slot]

func is_slot_empty(slot: SlotType) -> bool:
	return equipped[slot] == null

# -------------------------
# QUEST HOOK
# -------------------------
func pickup(item: ItemData, qty: int = 1) -> void:
	add_item(item, qty)
	for obj_id in item.quest_objective_ids:
		if obj_id != "":
			QuestManager.notify_item_collected(obj_id, qty)

# -------------------------
# RESET
# -------------------------
func reset() -> void:
	inventory.clear()
	for slot in SlotType.values():
		equipped[slot] = null
