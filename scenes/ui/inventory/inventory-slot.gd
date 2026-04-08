# inventory-slot.gd
class_name InventorySlot
extends PanelContainer

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var quantity_label: Label = $MarginContainer/VBoxContainer/Quantity

var _item_data: ItemData

func setup(item: ItemData, qty: int) -> void:
	_item_data = item
	icon.texture = item.item_icon
	quantity_label.text = str(qty) if item.is_stackable else ""
	tooltip_text = "%s\n%s" % [item.item_name, item.description]
