extends Node2D
var checks := 0
var failures := 0
var player: Player
var capture_mode := false
var folder := ""
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func frames(count: int = 4) -> void:
	for i in count: await get_tree().process_frame
func key(code: int, down: bool = true) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down; get_viewport().push_input(event,true)
func tap(code: int) -> void:
	key(code); key(code,false)
func joy(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true; Input.parse_input_event(event)
	event = event.duplicate(); event.pressed = false; Input.parse_input_event(event)
func mouse(at: Vector2, down: bool = false, moving: bool = false) -> void:
	if moving:
		var event := InputEventMouseMotion.new(); event.position = at; event.global_position = at; event.relative = Vector2(35,10); event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0; get_viewport().push_input(event,true)
	else:
		var event := InputEventMouseButton.new(); event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down; get_viewport().push_input(event,true)
func item(id: String, title: String, kind: ItemData.ItemType) -> ItemData:
	var data := ItemData.new(); data.item_id = "preview_"+id; data.item_name = title; data.item_type = kind; data.description = "An authored interface testing fixture. It is never granted to campaign players."
	QuestManager.registry.items[data.item_id] = data; return data
func stock() -> void:
	Inventory_Manager.reset()
	Inventory_Manager.add_item(QuestManager.registry.items.drop_001,5)
	Inventory_Manager.add_item(QuestManager.registry.items["component_001"] if QuestManager.registry.items.has("component_001") else load("res://data/items/components/mana-vile-low-grade.tres"),3)
	Inventory_Manager.add_item(QuestManager.registry.items.equipment_student_lab_robe)
	var notes := item("notes","Fieldwork notes — a comparative survey of wetland specimens and their Magis responses",ItemData.ItemType.QUEST_ITEM)
	notes.description = "Collected observations from a supervised fieldwork exercise.\n\n"+"Each entry records its habitat, observed behavior and practical relevance. ".repeat(10)
	Inventory_Manager.add_item(notes)
func shot(name_: String) -> void:
	if not capture_mode: return
	await frames(5); await get_tree().create_timer(.16).timeout; await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(folder+name_+".png")
	check(error == OK,"Renderer capture "+name_)
func _ready() -> void:
	await frames()
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): push_error("Run this fixture with --quest-test-mode"); get_tree().quit(2); return
	capture_mode = "--capture-inventory" in OS.get_cmdline_user_args()
	if capture_mode:
		if DisplayServer.get_name() == "headless": get_tree().quit(2); return
		var size_ := Vector2i(1280,720) if "--720" in OS.get_cmdline_user_args() else Vector2i(1920,1080)
		get_window().size = size_; get_window().content_scale_size = size_
		folder = "res://docs/previews/inventory-v2/%dx%d/" % [size_.x,size_.y]; DirAccess.make_dir_recursive_absolute(folder)
	QuestManager.persistence_enabled = false; Inventory_Manager.reset(); Player_Global_Data.p_moveable = true
	var floor_ := StaticBody2D.new(); floor_.collision_layer = 16; floor_.position = Vector2(0,300)
	var shape := CollisionShape2D.new(); shape.shape = RectangleShape2D.new(); shape.shape.size = Vector2(6000,60); floor_.add_child(shape); add_child(floor_)
	player = load("res://components/characters/player/player.tscn").instantiate(); player.position = Vector2(0,160); player.set_meta("quest_owner_id",""); add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	await frames(8)
	tap(KEY_V); await frames()
	check(is_instance_valid(InventoryOverlay.ui) and get_tree().paused,"Physical V opens the paused fullscreen overlay")
	var ui: InventoryUI = InventoryOverlay.ui
	check(ui.empty.visible,"Zero-item state renders with usable focus"); await shot("01-empty")
	stock(); await frames(); ui.select_item("drop_001"); await shot("02-items")
	var robe: ItemData = QuestManager.registry.items.equipment_student_lab_robe
	ui.select_item(robe.item_id); await frames()
	var source: Vector2 = ui.rows[robe.item_id].get_global_rect().get_center()
	mouse(source,false,true); mouse(source,true); await frames(2); mouse(source+Vector2(45,5),true,true); await frames(3)
	check(get_viewport().gui_is_dragging() and ui.tabs.current_tab == 1,"Real mouse motion starts a drag and reveals equipment targets")
	var target: Vector2 = ui.equipment_slots[2].get_global_rect().get_center()
	mouse(target,true,true); await frames(2); mouse(target,false); await frames()
	check(Inventory_Manager.get_equipped(2) == robe,"Real mouse release on a compatible slot equips the item")
	await shot("03-equipment")
	var original := Inventory_Manager.snapshot()
	mouse(target,false,true); mouse(target,true); await frames(2); mouse(target+Vector2(40,5),true,true); await frames(3)
	mouse(Vector2(8,8),true,true); mouse(Vector2(8,8),false); await frames()
	check(Inventory_Manager.snapshot() == original and Inventory_Manager.get_equipped(2) == robe,"Canceling a genuine drag outside valid targets leaves equipment intact")
	var return_at := ui.return_target.get_global_rect().get_center()
	mouse(target,false,true); mouse(target,true); await frames(2); mouse(target+Vector2(40,5),true,true); await frames(2); mouse(return_at,true,true); mouse(return_at,false); await frames()
	check(Inventory_Manager.has_item(robe.item_id) and Inventory_Manager.get_equipped(2) == null,"Real equipped-item drag returns the item to inventory")
	joy(JOY_BUTTON_LEFT_SHOULDER); await frames(); check(ui.tabs.current_tab == 0,"Gamepad shoulder action switches to Inventory")
	ui.rows[robe.item_id].grab_focus(); await frames(); ui.equip_button.grab_focus(); joy(JOY_BUTTON_A); await frames()
	check(ui.slot_dialog.visible and get_viewport().gui_get_focus_owner() is Button,"Gamepad A opens a focused compatible-slot chooser")
	joy(JOY_BUTTON_A); await frames(); check(Inventory_Manager.get_equipped(2) == robe,"Gamepad A confirms the equipment transaction without dragging")
	ui.rows.drop_001.grab_focus(); joy(JOY_BUTTON_Y); await frames()
	check(Inventory_Manager.favorites.has("drop_001"),"Gamepad Y toggles the selected item's favorite")
	Player_Global_Data.p_curr_health = 300; ui.refresh(); ui.rows.drop_001.grab_focus(); await frames()
	var row_instance: int = ui.rows.drop_001.get_instance_id()
	ui.use_button.grab_focus(); joy(JOY_BUTTON_A); await frames()
	check(Player_Global_Data.p_curr_health == 305 and Inventory_Manager.get_item_quantity("drop_001") == 4,"Gamepad Use applies a real effect and consumes one item")
	check(ui.rows.drop_001.get_instance_id() == row_instance and get_viewport().gui_get_focus_owner() == ui.use_button,"Quantity updates reuse the existing row and recover action focus")
	joy(JOY_BUTTON_X); await frames(); check(ui.search_keyboard.visible,"Controller search opens a navigable on-screen keyboard")
	joy(JOY_BUTTON_A); await frames(); check(ui.search.text == "A","Controller on-screen keyboard enters text without a physical keyboard")
	await shot("04-search-keyboard")
	joy(JOY_BUTTON_B); await frames(); check(not ui.search_keyboard.visible and is_instance_valid(get_viewport().gui_get_focus_owner()),"Controller Back exits search without trapping focus")
	ui.category.grab_focus(); joy(JOY_BUTTON_A); await frames(); joy(JOY_BUTTON_DPAD_DOWN); joy(JOY_BUTTON_A); await frames()
	check(ui.category.selected == 1,"Controller navigation changes category through the native popup")
	ui.category.select(0); ui.refresh()
	ui.sort.grab_focus(); joy(JOY_BUTTON_A); await frames(); joy(JOY_BUTTON_DPAD_DOWN); joy(JOY_BUTTON_A); await frames()
	check(ui.sort.selected == 1,"Controller navigation changes sorting through the native popup")
	ui.sort.select(0); ui.refresh()
	ui.search.grab_focus(); tap(KEY_V); await frames(); check(is_instance_valid(InventoryOverlay.ui),"Typing the inventory shortcut in search cannot close the overlay")
	ui.search.text = "zz-no-results"; ui.refresh(); await shot("05-no-results"); ui.search.clear(); ui.refresh()
	ui.category.select(8); ui.refresh(); await shot("06-favorites"); ui.category.select(0); ui.refresh()
	ui.select_item("preview_notes"); await shot("07-long-description")
	ui.select_item("drop_001"); ui._drop(); await shot("08-drop-confirmation"); ui.drop_dialog.hide(); ui._restore_focus()
	# Fill to the actual distinct-type capacity with scoped test resources.
	for i in 64:
		if Inventory_Manager.inventory.size() >= 64: break
		var fixture := item("record_%02d" % i,"Research material %02d" % i,ItemData.ItemType.MATERIAL if i%2 else ItemData.ItemType.COMPONENT)
		Inventory_Manager.add_item(fixture,1+i%12)
	ui.refresh(); check(Inventory_Manager.inventory.size() == 64,"Maximum-capacity list contains 64 distinct item types")
	ui.rows[ui.visible_ids.back()].grab_focus(); await frames()
	check(ui.scroll.scroll_vertical > 0,"Focusing a distant row scrolls the long list into view")
	await shot("09-capacity")
	ui.rows.drop_001.grab_focus(); await frames()
	var at := player.global_position; var velocity_ := player.velocity
	Input.action_press("move_right"); await frames(10); Input.action_release("move_right")
	check(player.global_position == at and player.velocity == velocity_,"Gameplay movement and velocity cannot leak through the paused overlay")
	joy(JOY_BUTTON_B); await frames(); check(not get_tree().paused and not is_instance_valid(InventoryOverlay.ui),"Gamepad Back closes inventory and restores pause ownership")
	print("GAMEPAD_HARDWARE: ",Input.get_connected_joypads())
	var school: CutsceneSequence = load("res://data/story/school-entrance.tres")
	QuestManager.world_flags.erase(CutsceneFlow.flag_for(school)); CutsceneFlow.play(self,school)
	await get_tree().create_timer(.9).timeout; await shot("10-cutscene-skip")
	var skip_at := CutsceneFlow.skip_button.get_global_rect().get_center()
	mouse(skip_at,false,true); mouse(skip_at,true); await get_tree().create_timer(.35).timeout
	check(CutsceneFlow.elapsed > .2 and CutsceneFlow.sequence != null,"Real mouse hold advances visible skip progress before completion")
	await shot("11-skip-hold")
	await get_tree().create_timer(.65).timeout; mouse(skip_at,false); await frames()
	check(CutsceneFlow.sequence == null and Dialogic.current_timeline == null and Player_Global_Data.p_moveable and Player_Global_Data.combat_mode,"Real mouse skip cleans up dialogue and resumes school gameplay")
	await shot("12-skipped-gameplay")
	print("INVENTORY_V2_GAMEPLAY: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)
