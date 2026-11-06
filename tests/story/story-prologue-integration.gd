extends Node2D

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROLOGUE_INTEGRATION: " + label)

func _ready() -> void:
	var prior_ready := SaveManager.session_ready
	SaveManager.session_ready = true
	StoryDirector._on_restored()
	SaveManager.loading = true
	var house: Node = load("res://scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn").instantiate()
	add_child(house)
	var house_portal: Variant = house.get_node_or_null("World/GameComponents/Doors/ZonePortal(SchoolEntrance)")
	check(house_portal != null and not house_portal.story_unlocked(), "house portal waits for completed introduction")
	SaveManager.loading = false
	QuestManager.set_world_flag("story_sequence:prologue.kampung", true)
	await get_tree().process_frame
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house" and house_portal.story_unlocked(), "completed introduction opens house portal")
	house.queue_free()
	await get_tree().process_frame
	var prior_scene_path: String = Player_Manager.previous_scene_path
	var arrival_controller := Node2D.new()
	arrival_controller.set_script(load("res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.gd"))
	SaveManager.loading = true
	add_child(arrival_controller)
	SaveManager.loading = false
	Player_Manager.previous_scene_path = "res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn"
	arrival_controller.call("_record_school_arrival")
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house", "unrelated scene entry is not school arrival")
	Player_Manager.previous_scene_path = "res://scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn"
	arrival_controller.call("_record_school_arrival")
	await get_tree().process_frame
	check(StoryDirector.get_current_stage_id() == &"prologue.reach_school", "house portal arrival advances once")
	check(QuestManager.world_flags.get("story.prologue.reached_school", false), "arrival fact recorded by QuestManager")
	arrival_controller.call("_record_school_arrival")
	await get_tree().process_frame
	check(StoryDirector.get_current_stage_id() == &"prologue.reach_school", "repeated arrival cannot double advance")
	arrival_controller.queue_free()
	StoryDirector.state.stage_id = &"prologue.spm_practical"
	QuestManager.world_flags.erase("story.prologue.practical_demonstrated")
	SaveManager.loading = true
	var school: Node = load("res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn").instantiate()
	add_child(school)
	await get_tree().process_frame
	var receiver: Variant = school.get_node_or_null("World/GameComponents/Environment/school-environment/ChillTarget")
	var portal: Variant = school.get_node_or_null("World/GameComponents/Doors/ZonePortal(EndOfExam)")
	check(receiver != null and receiver.has_signal("activated"), "real school receiver exists")
	check(portal != null and portal.get("practical_completion_portal") == true, "real exam exit has completion gate")
	if receiver != null:
		receiver.activated.emit(true)
	check(not QuestManager.world_flags.get("story.prologue.practical_demonstrated", false), "restore cannot record a demonstration")
	SaveManager.loading = false
	check(not portal.story_unlocked(), "exam exit remains blocked before demonstration")
	if receiver != null:
		receiver.activated.emit(true)
	check(QuestManager.world_flags.get("story.prologue.practical_demonstrated", false), "receiver signal records demonstrated spell interaction")
	check(portal.story_unlocked(), "authored portal opens after demonstration")
	check(StoryDirector.get_current_stage_id() == &"prologue.spm_practical", "demonstration does not finish exam")
	var destination: Node2D = Node2D.new()
	destination.set_script(load("res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-one/flac-f1-entrance.gd"))
	SaveManager.loading = true
	add_child(destination)
	SaveManager.loading = false
	Player_Manager.previous_scene_path = "res://scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn"
	destination.call("_complete_exam_arrival")
	check(not QuestManager.world_flags.get("story.prologue.spm_completed", false), "wrong previous scene cannot complete exam")
	Player_Manager.previous_scene_path = "res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn"
	destination.call("_complete_exam_arrival")
	await get_tree().process_frame
	check(StoryDirector.get_current_stage_id() == &"prologue.after_exam", "qualified FLAC arrival completes exam")
	Player_Manager.previous_scene_path = prior_scene_path
	destination.queue_free()
	school.queue_free()
	await get_tree().process_frame
	QuestManager.world_flags.erase("story.prologue.practical_demonstrated")
	QuestManager.world_flags.erase("story.prologue.left_house")
	QuestManager.world_flags.erase("story.prologue.reached_school")
	QuestManager.world_flags.erase("story.prologue.spm_completed")
	QuestManager.world_flags.erase("story_sequence:prologue.kampung")
	StoryDirector.state.clear()
	SaveManager.session_ready = prior_ready
	print("PROLOGUE_INTEGRATION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
