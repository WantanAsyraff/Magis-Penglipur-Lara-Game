class_name IngredientSlot
extends Panel

var recipe: ItemData

func setup(item: ItemData, qty: int) -> void:
	if item == null:
		hide()
		return
	show()
	var icon := find_child("TextureRect") as TextureRect
	var label := find_child("ItemLabel") as Label
	print("[IngredientSlot] icon found: ", icon)
	print("[IngredientSlot] label found: ", label)
	if icon:
		icon.texture = item.item_icon
	if label:
		label.text = "x%d" % qty
	_refresh_tint(item, qty)

func _refresh_tint(item: ItemData, qty: int) -> void:
	var inv: Node = get_node_or_null("/root/Inventory_Manager")
	if inv == null:
		push_error("[IngredientSlot] Inventory_Manager not found!")
		return
	var has_enough: bool = inv.has_item(item.item_id, qty)
	var icon := find_child("TextureRect") as TextureRect
	if icon:
		icon.modulate = Color.WHITE if has_enough else Color(1, 0.3, 0.3)
