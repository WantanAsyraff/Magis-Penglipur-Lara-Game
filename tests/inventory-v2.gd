extends Node2D
var checks := 0
var failures := 0
var player: Player
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+text)
func fixture(id: String, kind: ItemData.ItemType = ItemData.ItemType.MATERIAL) -> ItemData:
	var item := ItemData.new(); item.item_id = "inventory_fixture_"+id; item.item_name = id.capitalize(); item.item_type = kind; item.description = "An authored testing record for "+id
	QuestManager.registry.items[item.item_id] = item; return item
func settle() -> void:
	for i in 4: await get_tree().process_frame
func press(action: String) -> void:
	var event := InputEventAction.new(); event.action = action; event.pressed = true; get_viewport().push_input(event,true)
	event = event.duplicate(); event.pressed = false; get_viewport().push_input(event,true)
func _ready() -> void:
	await get_tree().process_frame
	Inventory_Manager.reset(); QuestManager.persistence_enabled = false
	Player_Global_Data.p_curr_health = 200; Player_Global_Data.p_curr_mana = 100; Player_Global_Data.p_moveable = true
	player = load("res://components/characters/player/player.tscn").instantiate(); player.position = Vector2(0,-200); add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	player.set_physics_process(false)
	var fish: ItemData = QuestManager.registry.items.drop_001
	check(Inventory_Manager.pickup(fish,3,"inventory-fish") == 3 and Player_Global_Data.p_curr_health == 200,"Fish pickup stores items without automatic healing")
	var used := Inventory_Manager.use_item(fish.item_id)
	check(used.ok and Player_Global_Data.p_curr_health == 205 and Inventory_Manager.get_item_quantity(fish.item_id) == 2,"Manual use heals and consumes exactly one item")
	Player_Global_Data.p_curr_health = 400
	check(not Inventory_Manager.use_item(fish.item_id).ok and Inventory_Manager.get_item_quantity(fish.item_id) == 2,"Full health refuses use without wasting food")
	var mana := fixture("mana",ItemData.ItemType.CONSUMABLE); mana.mana_restore = 30; Inventory_Manager.add_item(mana,2)
	Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana-10
	check(Inventory_Manager.use_item(mana.item_id).ok and Player_Global_Data.p_curr_mana == Player_Global_Data.p_max_mana,"Manual mana use clamps to maximum")
	check(not Inventory_Manager.use_item(mana.item_id).ok and Inventory_Manager.get_item_quantity(mana.item_id) == 1,"Full mana refuses consumption")
	var material := fixture("material"); Inventory_Manager.add_item(material,4)
	check(not Inventory_Manager.use_item(material.item_id).ok,"Material names never invent use effects")
	var reward := fixture("reward"); reward.exp_reward = 20; var xp := Player_Global_Data.player_exp
	Inventory_Manager.pickup(reward,1,"reward-first"); Inventory_Manager.remove_item(reward); Inventory_Manager.pickup(reward,1,"reward-second")
	check(Player_Global_Data.player_exp == xp+20,"Acquisition reward grants once per stable item ID")
	var robe: ItemData = QuestManager.registry.items.equipment_student_lab_robe; Inventory_Manager.add_item(robe)
	check(not Inventory_Manager.equip_item(material,Inventory_Manager.SlotType.ROBE).ok,"Arbitrary materials cannot be equipped")
	check(not Inventory_Manager.equip_item(robe,Inventory_Manager.SlotType.WEAPON).ok,"Equipment manager rejects incompatible slots")
	check(Inventory_Manager.equip_item(robe,Inventory_Manager.SlotType.ROBE).ok and not Inventory_Manager.has_item(robe.item_id),"Compatible equipment moves atomically from inventory")
	check(Inventory_Manager.unequip_item(Inventory_Manager.SlotType.ROBE).ok and Inventory_Manager.has_item(robe.item_id),"Unequip returns an owned item")
	var replacement := fixture("replacement",ItemData.ItemType.EQUIPMENT); replacement.equipment_slots = 4; replacement.is_stackable = false
	Inventory_Manager.add_item(replacement); Inventory_Manager.equip_item(robe,Inventory_Manager.SlotType.ROBE)
	check(Inventory_Manager.equip_item(replacement,Inventory_Manager.SlotType.ROBE).ok and Inventory_Manager.has_item(robe.item_id),"Equipment replacement returns the previous item atomically")
	var before := Inventory_Manager.snapshot(); var cap: int = Inventory_Manager.max_slots; Inventory_Manager.max_slots = Inventory_Manager.inventory.size()
	check(not Inventory_Manager.unequip_item(Inventory_Manager.SlotType.ROBE).ok and Inventory_Manager.snapshot() == before,"Full distinct-type capacity refuses unequip without item loss")
	Inventory_Manager.max_slots = cap
	var at := player.position; var scene := get_tree().current_scene
	check(InventoryOverlay.open(),"Inventory opens over the existing world")
	await settle(); var ui: InventoryUI = InventoryOverlay.ui
	check(get_tree().paused and ui.can_process(),"Gameplay pauses while the inventory continues processing")
	check(get_tree().current_scene == scene and player.position == at,"Opening preserves world identity and player position")
	check(ui.rows.size() == Inventory_Manager.inventory.size(),"Compact rows render actual inventory entries")
	ui.search.text = "FISH"; ui.refresh()
	check(ui.visible_ids == [fish.item_id],"Case-insensitive name search filters presentation")
	ui.search.text = "zzzz-no-match"; ui.refresh(); check(ui.visible_ids.is_empty() and ui.empty.visible,"Empty search results have a visible explanation")
	ui.search.clear(); ui.category.select(3); ui.refresh(); check(ui.visible_ids == [fish.item_id],"Food category uses authored type")
	ui.category.select(0); ui.sort.select(3); ui.refresh(); check(ui.visible_ids[0] == material.item_id,"Quantity sorting is deterministic")
	ui.select_item(fish.item_id); Inventory_Manager.toggle_favorite(fish.item_id); ui.category.select(8); ui.refresh()
	check(ui.visible_ids == [fish.item_id],"Favorites filter uses stable item IDs")
	var encoded := QuestSaveService.encode(QuestManager); var staged := QuestSaveService.stage(QuestManager,encoded)
	check(not staged.is_empty() and staged.favorites.has(fish.item_id),"Favorites stage through existing Quest V2 save state")
	var old := encoded.duplicate(true); old.erase("favorites"); old.erase("drop_escrow")
	check(not QuestSaveService.stage(QuestManager,old).is_empty(),"Old saves default optional inventory preferences safely")
	var corrupt := encoded.duplicate(true); corrupt.favorites = ["missing-id"]
	check(QuestSaveService.stage(QuestManager,corrupt).is_empty(),"Invalid favorite IDs reject the staged save")
	ui.category.select(0); ui.refresh(); ui.select_item(fish.item_id)
	check(ui.displayed == fish and ui.use_button.disabled,"Details reflect actual item data and unavailable-use reasons")
	ui.tabs.current_tab = 1
	var target: EquipmentDropTarget = ui.equipment_slots[2]
	var data := {"type":"inventory_item","id":robe.item_id,"from_slot":-1}
	check(target._can_drop_data(Vector2.ZERO,data),"Real drag target validates held item and slot compatibility")
	target._drop_data(Vector2.ZERO,data); check(Inventory_Manager.get_equipped(2) == robe,"Dropping row metadata equips through the central transaction")
	check(not target._can_drop_data(Vector2.ZERO,data),"Stale drag metadata is rejected after source removal")
	var cancel_before := Inventory_Manager.snapshot()
	check(Inventory_Manager.snapshot() == cancel_before,"Starting/canceling a drag does not remove inventory")
	ui.return_target._drop_data(Vector2.ZERO,{"type":"inventory_item","id":robe.item_id,"from_slot":2})
	check(Inventory_Manager.has_item(robe.item_id),"Equipped drag return uses validated unequip")
	ui.tabs.current_tab = 0; ui.select_item(robe.item_id); ui._equip(); await settle()
	check(ui.slot_dialog.visible and get_viewport().gui_get_focus_owner() is Button,"Controller-equivalent equip opens a focused slot chooser")
	ui.slot_dialog.hide(); ui._restore_focus()
	InventoryOverlay.close(); await settle()
	check(not get_tree().paused and get_tree().current_scene == scene and player.position == at,"Closing restores exactly the world that was paused")
	get_tree().paused = true; check(not InventoryOverlay.open(),"Inventory cannot steal an existing pause"); get_tree().paused = false
	var key_item := fixture("key",ItemData.ItemType.KEY_ITEM); Inventory_Manager.add_item(key_item)
	check(not Inventory_Manager.drop_item(key_item.item_id).ok,"Key items cannot be dropped")
	var dropped := Inventory_Manager.drop_item(fish.item_id,2)
	check(dropped.ok and dropped.world_drop != null and Inventory_Manager.get_item_quantity(fish.item_id) == 0,"World drop removes the selected stack quantity once")
	if dropped.ok:
		check(dropped.world_drop.pickup(player) == 0,"Fresh player drops cannot immediately auto-collect")
		var restored := QuestSaveService.stage(QuestManager,QuestSaveService.encode(QuestManager))
		check(restored.inventory[fish.item_id].quantity == 2 and restored.drop_escrow.is_empty(),"Save/load returns escrow without duplicating world drops")
		dropped.world_drop.drop_armed = true
		check(dropped.world_drop.pickup(player) == 2 and Inventory_Manager.get_item_quantity(fish.item_id) == 2,"Dropped stack is a real recoverable world pickup")
	var legacy := encoded.duplicate(true); legacy.equipment["2"] = "drop_002"
	check(QuestSaveService.stage(QuestManager,legacy).equipment[2] == QuestManager.registry.items.drop_002,"Legacy unspecified equipment remains loadable without reopening the equip loophole")
	var broken := encoded.duplicate(true); broken.inventory[0].quantity = 1.5
	check(QuestSaveService.stage(QuestManager,broken).is_empty(),"Fractional saved quantities are rejected")
	var block := StaticBody2D.new(); block.collision_layer = 16; block.position = player.position
	var block_shape := CollisionShape2D.new(); block_shape.shape = RectangleShape2D.new(); block_shape.shape.size = Vector2(2000,2000); block.add_child(block_shape); add_child(block)
	await get_tree().physics_frame; await get_tree().physics_frame
	var held_before := Inventory_Manager.get_item_quantity(fish.item_id)
	check(not Inventory_Manager.drop_item(fish.item_id,1).ok and Inventory_Manager.get_item_quantity(fish.item_id) == held_before,"Failed safe-spawn search leaves inventory untouched")
	block.free(); await get_tree().physics_frame; await get_tree().physics_frame
	var returned_on_exit := Inventory_Manager.drop_item(fish.item_id,1)
	if returned_on_exit.ok: returned_on_exit.world_drop.free()
	check(returned_on_exit.ok and Inventory_Manager.get_item_quantity(fish.item_id) == held_before,"Area-exit cleanup reclaims the reserved item exactly once")
	var protected := fixture("quest",ItemData.ItemType.QUEST_ITEM); Inventory_Manager.add_item(protected)
	check(not Inventory_Manager.drop_item(protected.item_id).ok,"Quest item dropping is protected independently of key items")
	var objective := QuestObjectiveData.new(); objective.objective_id = "inventory_reacquire"; objective.target_id = fish.item_id; objective.type = QuestObjectiveData.ObjectiveType.COLLECT_ITEM; objective.required_amount = 10
	var quest := QuestData.new(); quest.quest_id = "inventory_reacquire_fixture"; quest.title = "Inventory transfer fixture"; quest.objectives.assign([objective])
	QuestManager.registry.quests[quest.quest_id] = quest
	var instance := QuestInstance.new(quest,"inventory-fixture",-1,QuestManager.active_owner_id); instance.status = QuestInstance.Status.ACTIVE
	QuestManager._active_instances[instance.instance_id] = instance
	Inventory_Manager.pickup(fish,1,"new-fish-for-quest")
	var quest_before: int = instance.objective_progress[objective.objective_id]
	var transferred := Inventory_Manager.drop_item(fish.item_id,1)
	if transferred.ok: transferred.world_drop.drop_armed = true; transferred.world_drop.pickup(player)
	check(transferred.ok and instance.objective_progress[objective.objective_id] == quest_before,"Drop/re-pickup cannot farm cumulative acquisition objectives")
	QuestManager._active_instances.erase(instance.instance_id)
	var recipe := fixture("recipe",ItemData.ItemType.CONSUMABLE); recipe.health_restore = 10; recipe.ingredient_1 = material; recipe.qty_1 = 2
	var crafting: CraftingUI = load("res://scenes/crafting-room/crafting-ui.tscn").instantiate(); add_child(crafting)
	Player_Global_Data.p_curr_health = 100
	var ingredients_before := Inventory_Manager.get_item_quantity(material.item_id)
	crafting._on_recipe_selected(recipe); crafting._on_crafting_button_pressed()
	check(Inventory_Manager.has_item(recipe.item_id) and Inventory_Manager.get_item_quantity(material.item_id) == ingredients_before-2 and Player_Global_Data.p_curr_health == 100,"Actual crafting preserves transactions and stores consumables without auto-use")
	crafting.free()
	Player_Global_Data.p_curr_health = 350
	check(InventoryOverlay.open(),"Inventory reopens after world transactions")
	await settle(); var focused_ui: InventoryUI = InventoryOverlay.ui; focused_ui.select_item(fish.item_id); focused_ui.use_button.grab_focus()
	for i in 5:
		if not Inventory_Manager.has_item(fish.item_id): break
		focused_ui._use(); await settle()
	check(not Inventory_Manager.has_item(fish.item_id) and is_instance_valid(get_viewport().gui_get_focus_owner()) and get_viewport().gui_get_focus_owner().is_visible_in_tree(),"Removing the selected stack recovers visible controller focus")
	InventoryOverlay.close(); await settle()
	var a := fixture("empty_icon"); var fallback := InventoryPresentation.icon(a,40); check(fallback is Label,"Missing icons use a readable fallback"); fallback.free()
	Inventory_Manager.reset(); check(Inventory_Manager.favorites.is_empty(),"Profile reset clears favorites")
	check(InventoryOverlay.open(),"Empty inventory opens normally"); await settle()
	check(InventoryOverlay.ui.empty.visible and is_instance_valid(get_viewport().gui_get_focus_owner()),"Empty inventory retains useful controller focus")
	InventoryOverlay.close(); await settle()
	print("INVENTORY_V2: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)
