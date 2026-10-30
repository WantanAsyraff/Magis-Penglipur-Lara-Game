class_name EquipmentDropTarget extends Button
signal action_result(result: ItemActionResult)
var slot := -1
func valid_drag(data: Variant) -> bool:
	if not data is Dictionary or data.get("type") != "inventory_item" or not data.get("id") is String or not data.get("from_slot") is int: return false
	var item: ItemData = QuestManager.registry.items.get(data.id)
	if slot >= 0: return data.from_slot == -1 and item != null and item.supports_slot(slot) and Inventory_Manager.has_item(data.id)
	var equipped_item := Inventory_Manager.get_equipped(data.from_slot)
	return data.from_slot >= 0 and equipped_item != null and equipped_item.item_id == data.id
func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return valid_drag(data)
func _drop_data(_at: Vector2, data: Variant) -> void:
	if not valid_drag(data): action_result.emit(ItemActionResult.failure("The dragged item is no longer available.")); return
	if slot >= 0: action_result.emit(Inventory_Manager.equip_item(QuestManager.registry.items[data.id],slot))
	else: action_result.emit(Inventory_Manager.unequip_item(data.from_slot))
func _get_drag_data(_at: Vector2) -> Variant:
	if slot < 0: return null
	var item := Inventory_Manager.get_equipped(slot)
	if item == null: return null
	set_drag_preview(InventoryPresentation.preview(item)); return {"type":"inventory_item","id":item.item_id,"from_slot":slot}
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var eligible := valid_drag(get_viewport().gui_get_drag_data())
		add_theme_stylebox_override("normal",InventoryPresentation.style(Color("e9f2ed") if eligible else Color("f5e9e6"),Color("237a72") if eligible else Color("a35c52")))
	elif what == NOTIFICATION_DRAG_END: remove_theme_stylebox_override("normal")
