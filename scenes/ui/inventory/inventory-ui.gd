# inventory-ui.gd
class_name InventoryUI
extends Control

const SLOT_SCENE = preload("res://scenes/ui/inventory/inventory-slot.tscn") # fix path if different

var selected_item: ItemData
var weapon_label: Label
var selection_label: Label
var equipment_status: Label
var equip_button: Button
var unequip_button: Button

@onready var invent_con: GridContainer = %InventoryContainer

func _ready() -> void:
	var sidebar := VBoxContainer.new()
	sidebar.anchor_top = 0.32; sidebar.anchor_right = 0.25; sidebar.anchor_bottom = 1.0
	sidebar.offset_left = 24; sidebar.offset_right = -24; sidebar.offset_bottom = -24
	sidebar.add_theme_constant_override("separation", 14); sidebar.theme = ControlsStyle.theme()
	add_child(sidebar)
	ControlsStyle.label(sidebar, "WEAPON", 22)
	weapon_label = ControlsStyle.label(sidebar, ""); weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_label = ControlsStyle.label(sidebar, "Select an item to inspect."); selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equip_button = ControlsStyle.button(sidebar, "Equip weapon", _equip_weapon)
	unequip_button = ControlsStyle.button(sidebar, "Unequip weapon", _unequip_weapon)
	equipment_status = ControlsStyle.label(sidebar, ""); equipment_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Inventory_Manager.equipment_changed.connect(_equipment_changed)
	Inventory_Manager.inventory_changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(_item: ItemData, _qty: int) -> void:
	_refresh()

func _refresh() -> void:
	for child in invent_con.get_children():
		invent_con.remove_child(child); child.queue_free()

	for item_data in Inventory_Manager.get_all_items():
		var qty := Inventory_Manager.get_item_quantity(item_data.item_id)
		var slot = SLOT_SCENE.instantiate()
		invent_con.add_child(slot)
		slot.setup(item_data, qty)
		slot.item_selected.connect(_select_item)
	_refresh_weapon()

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

func _select_item(item: ItemData) -> void:
	selected_item = item
	selection_label.text = item.item_name + "\n" + item.description
	_refresh_weapon()
func _equipment_changed(_slot: int, _item: ItemData) -> void:
	_refresh_weapon()
func _refresh_weapon() -> void:
	var weapon: ItemData = Inventory_Manager.get_equipped(Inventory_Manager.SlotType.WEAPON)
	weapon_label.text = weapon.item_name if weapon else "Empty slot"
	equip_button.disabled = selected_item == null or selected_item.item_type != ItemData.ItemType.EQUIPMENT or selected_item.weapon_visual == null or not Inventory_Manager.has_item(selected_item.item_id)
	unequip_button.disabled = weapon == null
func _equip_weapon() -> void:
	if equip_button.disabled: return
	Inventory_Manager.equip_item(selected_item, Inventory_Manager.SlotType.WEAPON)
	equipment_status.text = "Equipped " + selected_item.item_name if Inventory_Manager.get_equipped(Inventory_Manager.SlotType.WEAPON) == selected_item else "Could not equip. Make room for the current weapon."
	_refresh_weapon()
	SaveManager.request_autosave()
	if not unequip_button.disabled: unequip_button.grab_focus()
func _unequip_weapon() -> void:
	Inventory_Manager.unequip_item(Inventory_Manager.SlotType.WEAPON)
	equipment_status.text = "Weapon returned to inventory." if Inventory_Manager.is_slot_empty(Inventory_Manager.SlotType.WEAPON) else "Inventory full. Make room before unequipping."
	_refresh_weapon()
	SaveManager.request_autosave()
	if not equip_button.disabled: equip_button.grab_focus()
