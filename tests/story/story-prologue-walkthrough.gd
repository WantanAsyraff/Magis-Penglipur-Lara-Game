extends Node

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROLOGUE_WALKTHROUGH: " + label)

func skip_with_input() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_F1
	press.physical_keycode = KEY_F1
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().create_timer(1.0).timeout
	press = press.duplicate()
	press.pressed = false
	Input.parse_input_event(press)
	for i in 8: await get_tree().process_frame

func key(code: int, down: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	get_viewport().push_input(event, true)

func tap(code: int) -> void:
	key(code)
	key(code, false)

func attempt_full_practical() -> void:
	var school_scene := get_tree().current_scene
	var school_player := Player_Manager.get_local_player() as Player
	var receiver: EnvironmentDevice = school_scene.get_node("World/GameComponents/Environment/school-environment/ChillTarget")
	Input.action_press("move_right")
	for i in 850:
		await get_tree().physics_frame
		if school_player.global_position.x >= receiver.global_position.x - 190: break
	Input.action_release("move_right")
	check(school_player.global_position.x >= receiver.global_position.x - 240, "player walks to the practical receiver")
	var chill: SpellData = load("res://data/magis/spells/thermal-kinetic.tres")
	tap(KEY_R)
	key(KEY_O)
	for direction in chill.spell_incantation:
		tap({"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L}[direction])
	key(KEY_O, false)
	for i in 120: await get_tree().physics_frame
	check(QuestManager.world_flags.get("story.prologue.practical_demonstrated", false), "physical Kinetic Chill cast activates real receiver")
	if not QuestManager.world_flags.get("story.prologue.practical_demonstrated", false): return
	var portal := school_scene.get_node("World/GameComponents/Doors/ZonePortal(EndOfExam)")
	Input.action_press("move_right")
	for i in 3500:
		await get_tree().physics_frame
		if portal.get("_player_in_area"): break
	Input.action_release("move_right")
	check(portal.get("_player_in_area"), "player reaches practical exit using movement")
	if not portal.get("_player_in_area"): return
	Input.action_press("interact")
	await get_tree().process_frame
	Input.action_release("interact")
	for i in 360:
		await get_tree().process_frame
		if get_tree().current_scene != school_scene: break
	check(get_tree().current_scene != school_scene and StoryDirector.get_current_stage_id() == &"prologue.after_exam", "portal reaches FLAC and finishes practical")
	if get_tree().current_scene == school_scene: return
	for i in 60:
		if CutsceneFlow.eligible(): break
		await get_tree().process_frame
	check(CutsceneFlow.eligible(), "after-paper sequence starts at FLAC")
	if CutsceneFlow.eligible():
		await skip_with_input()
		check(QuestManager.world_flags.get("story_sequence:prologue.after_final_paper", false), "after-paper skip records completion")
		var saved_position: Vector2 = Player_Manager.get_local_player().global_position
		check(SaveManager.save_active(), "final FLAC milestone saves through Save V1")
		check(await SaveManager.load_slot(1), "final FLAC milestone reloads")
		check(StoryDirector.get_current_stage_id() == &"prologue.after_exam" and CutsceneFlow.sequence == null, "reload keeps final stage without replay")
		check(Player_Manager.get_local_player().global_position.distance_to(saved_position) < 2.0, "reload restores FLAC player position")

func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args():
		get_tree().quit(2)
		return
	check(await SaveManager.new_game(1, "Prologue Walkthrough", true), "isolated new campaign starts")
	var house := get_tree().current_scene
	check(house != null and house.scene_file_path.ends_with("rumah-yan-entrance.tscn"), "real house scene loaded")
	if house == null:
		get_tree().quit(1)
		return
	# Test mode suppresses automatic intro; start the same authored scene controller used by normal new game.
	house.get_node("World").begin_intro()
	for i in 60:
		if CutsceneFlow.eligible(): break
		await get_tree().process_frame
	check(CutsceneFlow.eligible(), "real intro accepts skip input")
	await skip_with_input()
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house", "F1 skip advances to leave house")
	check(SaveManager.save_active(), "completed house milestone saves through Save V1")
	var player := Player_Manager.get_local_player() as Player
	var portal := house.get_node("World/GameComponents/Doors/ZonePortal(SchoolEntrance)")
	Input.action_press("move_right")
	for i in 1500:
		await get_tree().physics_frame
		if portal.get("_player_in_area"): break
	Input.action_release("move_right")
	var reached_x: float = player.global_position.x
	check(portal.get("_player_in_area"), "player reaches school portal using movement")
	if portal.get("_player_in_area"):
		Input.action_press("interact")
		await get_tree().process_frame
		Input.action_release("interact")
		for i in 360:
			await get_tree().process_frame
			if get_tree().current_scene != house: break
	check(get_tree().current_scene != house, "portal routes to school scene")
	if get_tree().current_scene != house:
		check(StoryDirector.get_current_stage_id() == &"prologue.reach_school", "real arrival advances story")
		for i in 60:
			if CutsceneFlow.eligible(): break
			await get_tree().process_frame
		check(CutsceneFlow.eligible(), "school entrance cutscene starts")
		await skip_with_input()
		check(StoryDirector.get_current_stage_id() == &"prologue.spm_practical", "school skip reaches practical")
		check(Player_Global_Data.learned_spells.any(func(spell: SpellData): return spell.spell_id == "thermal_01"), "Kinetic Chill learned through CutsceneFlow")
		check(SaveManager.save_active(), "school practical milestone saves through Save V1")
		if "--full-practical" in OS.get_cmdline_user_args(): await attempt_full_practical()
	print("PROLOGUE_WALKTHROUGH: %d checks, %d failures; portal_x=%.1f" % [checks, failures, reached_x])
	get_tree().quit(failures)
