extends Node
var ui: InventoryUI
var layer: CanvasLayer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func reason() -> String:
	if is_instance_valid(ui): return "Inventory is already open."
	if get_tree().paused or is_instance_valid(ModalService.holder) or get_viewport().gui_get_focus_owner() is LineEdit: return "Close the current menu first."
	if not Inventory_Manager.action_context().is_empty(): return Inventory_Manager.action_context()
	if not Player_Global_Data.p_moveable: return "Player control is currently reserved by the story."
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return "Close the phone first."
	for dialog in get_tree().get_nodes_in_group("exclusive_ui"):
		if dialog.is_visible_in_tree(): return "Close the current dialog first."
	if not is_instance_valid(Player_Manager.get_local_player()): return "Open inventory in an active game world."
	return ""
func open() -> bool:
	if not reason().is_empty(): return false
	CutsceneFlow.dismiss_recap()
	layer = CanvasLayer.new(); layer.layer = 100; add_child(layer)
	ui = load("res://scenes/ui/inventory/inventory-ui.tscn").instantiate()
	if not ModalService.acquire(ui): layer.queue_free(); ui.free(); ui = null; return false
	layer.add_child(ui); ui.closed.connect(close); return true
func close() -> void:
	if not is_instance_valid(ui): return
	ModalService.release(ui); ui.queue_free(); ui = null
	if is_instance_valid(layer): layer.queue_free()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle") and not event.is_echo():
		if is_instance_valid(ui):
			if ui.search.has_focus() and event is InputEventKey: return
			close(); get_viewport().set_input_as_handled()
		elif open(): get_viewport().set_input_as_handled()
