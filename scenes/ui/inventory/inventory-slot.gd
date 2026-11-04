# inventory-slot.gd
class_name InventorySlot
extends PanelContainer

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var quantity_label: Label = $MarginContainer/VBoxContainer/Quantity

signal item_selected(item: ItemData)
var _item_data: ItemData
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for control in find_children("*", "Control"): control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_entered.connect(queue_redraw); focus_exited.connect(queue_redraw)
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		grab_focus(); item_selected.emit(_item_data); accept_event()
func _draw() -> void:
	if has_focus(): draw_style_box(get_theme_stylebox("focus", "Button"), Rect2(Vector2.ZERO, size))


func setup(item: ItemData, qty: int) -> void:
	_item_data = item
	icon.texture = item.item_icon
	quantity_label.text = str(qty) if item.is_stackable else ""
	tooltip_text = "%s\n%s" % [item.item_name, item.description]
