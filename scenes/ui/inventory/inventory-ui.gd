# inventory-ui.gd
class_name InventoryUI
extends Control

const SLOT_SCENE = preload("res://scenes/ui/inventory/inventory-slot.tscn") # fix path if different

@onready var invent_con: GridContainer = %InventoryContainer

func _ready() -> void:
	Inventory_Manager.inventory_changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh()

func _refresh() -> void:
	for child in invent_con.get_children():
		child.queue_free()

	for item_data in Inventory_Manager.get_all_items():
		var qty := Inventory_Manager.get_item_quantity(item_data.item_id)
		var slot = SLOT_SCENE.instantiate()
		invent_con.add_child(slot)
		slot.setup(item_data, qty)

func _on_back_button_pressed() -> void:
	print("Current scene, ", Player_Global_Data.current_scene)
	print("Previous scene, ", Player_Global_Data.previous_scene)
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	print("Position, ", Player_Global_Data.previous_position)
	print("Position, ", Player_Global_Data.previous_position)
	Player_Global_Data.p_moveable = true
