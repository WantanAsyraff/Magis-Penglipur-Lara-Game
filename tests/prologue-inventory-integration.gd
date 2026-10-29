extends Node
var checks := 0
var failures := 0
var world: Node
var capture := false
var folder := ""
const SCENES := [
	["res://scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn","prologue.kampung",false,false],
	["res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn","prologue.school",true,false],
	["res://scenes/worlds/hubs/story/chapter-1/subway-scene.tscn","prologue.after_final_paper",false,false],
	["res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-one/FLAC-F1-entrance.tscn","prologue.after_final_paper",false,true],
]
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func frames(count: int = 8) -> void:
	for i in count: await get_tree().process_frame
func shot(name_: String) -> void:
	if not capture: return
	await frames(); await get_tree().create_timer(.16).timeout; await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(folder+name_+".png") == OK,"Actual world capture "+name_)
func _ready() -> void:
	await frames()
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene = null
	QuestManager.persistence_enabled = false; SaveManager._autosave_pending = false
	Player_Global_Data.learned_spells.clear(); Player_Global_Data.equipped_spells.clear()
	capture = "--capture-prologue" in OS.get_cmdline_user_args()
	if capture:
		var size_ := Vector2i(1280,720) if "--720" in OS.get_cmdline_user_args() else Vector2i(1920,1080)
		get_window().size = size_; get_window().content_scale_size = size_
		folder = "res://docs/previews/inventory-v2/%dx%d/" % [size_.x,size_.y]; DirAccess.make_dir_recursive_absolute(folder)
	for entry in SCENES:
		QuestManager.world_flags.erase("story_sequence:"+entry[1])
		world = load(entry[0]).instantiate(); get_tree().root.add_child(world); get_tree().current_scene = world
		for i in 120:
			if CutsceneFlow.eligible() and is_instance_valid(Player_Manager.get_local_player()): break
			await get_tree().process_frame
		check(CutsceneFlow.eligible() and Player_Manager.get_local_player() != null,"Actual scene initializes its player and owned sequence: "+entry[1])
		check(not InventoryOverlay.open(),"Actual story blocks inventory before completion")
		check(CutsceneFlow.request_skip(),"Actual scene accepts intentional sequence completion")
		await frames()
		check(get_tree().current_scene == world and Player_Global_Data.p_moveable and Player_Global_Data.combat_mode == entry[2] and Player_Global_Data.phone_visible == entry[3],"Completion preserves actual scene and intended gameplay/phone context")
		if entry[1] == "prologue.kampung":
			var player := Player_Manager.get_local_player() as Player
			Inventory_Manager.pickup(QuestManager.registry.items.drop_001,2,"actual-house-fish")
			check(InventoryOverlay.open(),"Inventory opens over the actual house world after skipping")
			var position_ := player.global_position
			await shot("13-actual-house-inventory")
			check(get_tree().paused and player.global_position == position_ and get_tree().current_scene == world,"Actual house stays paused in the same scene and position")
			InventoryOverlay.close(); await frames()
			check(not get_tree().paused,"Actual house resumes after overlay close")
		if entry[1] == "prologue.school":
			check(Player_Global_Data.learned_spells.size() == 1 and Player_Global_Data.learned_spells[0].spell_id == "thermal_01","Actual school grants only the intended tutorial spell")
			await shot("14-actual-school-gameplay")
		CutsceneFlow.dismiss_recap(); get_tree().current_scene = null; world.queue_free(); await frames()
		Player_Manager.players.clear()
	print("PROLOGUE_INVENTORY_INTEGRATION: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)
