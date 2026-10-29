extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	if "--read-inventory-save" in OS.get_cmdline_user_args():
		check(await SaveManager.load_slot(1),"Fresh process loads the intended Save V1 profile")
		check(Inventory_Manager.favorites.has("drop_001"),"Favorites survive a fresh process within their own profile")
		check(Inventory_Manager.get_item_quantity("drop_001") == 4 and Inventory_Manager.drop_escrow.is_empty(),"Saved player-drop escrow returns exactly once on load")
		check(Inventory_Manager.get_equipped(2) == QuestManager.registry.items.equipment_student_lab_robe,"Compatible equipment survives Save V1")
		check(QuestManager.world_flags.get("story_sequence:prologue.school",false),"Skipped sequence completion persists in existing world flags")
		check(InventoryOverlay.open(),"Loaded campaign can open the fullscreen inventory")
		check(await SaveManager.load_slot(1),"Load cooperatively cancels an active inventory modal")
		check(not get_tree().paused and not is_instance_valid(InventoryOverlay.ui) and not is_instance_valid(ModalService.holder),"Restore leaves no stuck pause owner or invisible overlay")
		check(await SaveManager.new_game(2,"Inventory profile B"),"Independent profile B initializes")
		check(Inventory_Manager.favorites.is_empty() and Inventory_Manager.get_item_quantity("drop_001") == 0,"Profile B inherits neither A's favorites nor item state")
		for profile in [1,2]:
			for kind in ["manual","auto"]: SaveManager.delete_slot(profile,kind)
	else:
		for profile in [1,2]:
			for kind in ["manual","auto"]: SaveManager.delete_slot(profile,kind)
		check(await SaveManager.new_game(1,"Inventory profile A"),"Isolated test-prefixed profile initializes")
		var player := Player_Manager.get_local_player() as Player; player.set_physics_process(false)
		Inventory_Manager.pickup(QuestManager.registry.items.drop_001,4,"save-fish")
		Inventory_Manager.toggle_favorite("drop_001")
		var robe: ItemData = QuestManager.registry.items.equipment_student_lab_robe; Inventory_Manager.add_item(robe)
		check(Inventory_Manager.equip_item(robe,Inventory_Manager.SlotType.ROBE).ok,"Real registered equipment commits to a campaign")
		player.global_position = Vector2(600,760)
		check(Inventory_Manager.drop_item("drop_001",2).ok,"Campaign creates a recoverable reserved world drop")
		var school: CutsceneSequence = load("res://data/story/school-entrance.tres")
		check(CutsceneFlow.play(get_tree().current_scene.get_node("World"),school),"Authored school contract starts for durable skip verification")
		for i in 60:
			if CutsceneFlow.eligible(): break
			await get_tree().process_frame
		check(CutsceneFlow.request_skip(),"Intentional skip invokes the guarded contract")
		for i in 10: await get_tree().process_frame
		check(SaveManager.save_active(),"Existing SaveManager durably saves optional inventory fields and story completion")
		var data := SaveManager.snapshot(); var old := data.duplicate(true); old.quest.erase("favorites"); old.quest.erase("drop_escrow")
		check(not GameSaveSchema.stage(old,1,Scene_Registry).is_empty(),"Version 1 saves lacking V2 optional fields remain loadable")
		data.quest.drop_escrow["bad-token"] = {"item_id":"drop_001","quantity":1}
		check(GameSaveSchema.stage(data,1,Scene_Registry).is_empty(),"Corrupt escrow rejects the full save before mutation")
	SaveManager._autosave_pending = false; QuestManager.persistence_enabled = false; QuestManager._save_timer.stop()
	print("INVENTORY_V2_SAVE: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)
