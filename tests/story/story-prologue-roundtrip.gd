extends Node

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROLOGUE_ROUNDTRIP: " + label)

func frames() -> void:
	for i in 3: await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args():
		get_tree().quit(2)
		return
	if "--write-prologue-save" in OS.get_cmdline_user_args():
		await _write()
	else:
		await _read()
	print("PROLOGUE_ROUNDTRIP: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)

func _write() -> void:
	check(await SaveManager.new_game(1, "Prologue Milestones", true), "new profile one")
	check(StoryDirector.get_current_stage_id() == &"prologue.wake_up", "new game starts at wake up")
	QuestManager.set_world_flag("story_sequence:prologue.kampung", true)
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house", "intro milestone")
	check(SaveManager._save("auto"), "autosave leave house")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id))
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.reach_school", "arrival milestone")
	check(SaveManager.save_active(), "manual save school arrival")
	check(await SaveManager.new_game(2, "Practical Milestone", true), "new profile two")
	QuestManager.set_world_flag("story_sequence:prologue.kampung", true)
	await frames()
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id))
	await frames()
	QuestManager.set_world_flag("story_sequence:prologue.school", true)
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.spm_practical", "practical milestone")
	check(SaveManager.save_active(), "manual save practical")
	QuestManager.set_world_flag("story.prologue.practical_demonstrated", true)
	await frames()
	check(SaveManager._save("auto"), "autosave demonstrated practical")
	check(await SaveManager.new_game(3, "After Exam Milestone", true), "new profile three")
	QuestManager.set_world_flag("story_sequence:prologue.kampung", true)
	await frames()
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id))
	await frames()
	QuestManager.set_world_flag("story_sequence:prologue.school", true)
	await frames()
	QuestManager.set_world_flag("story.prologue.practical_demonstrated", true)
	QuestManager.set_world_flag("story.prologue.spm_completed", true)
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.after_exam", "after exam milestone")
	check(SaveManager.save_active(), "manual save after exam")

func _read() -> void:
	var milestones := [[1, "auto", &"prologue.leave_house", 1], [1, "manual", &"prologue.reach_school", 2], [2, "manual", &"prologue.spm_practical", 3], [2, "auto", &"prologue.spm_practical", 3], [3, "manual", &"prologue.after_exam", 4]]
	for row in milestones:
		check(await SaveManager.load_slot(row[0], row[1]), "fresh-process load profile %s %s: %s" % [row[0], row[1], SaveManager.last_error])
		check(StoryDirector.get_current_stage_id() == row[2], "restored stage %s %s" % [row[0], row[1]])
		check(StoryDirector.state.receipts.size() == row[3], "restored receipts %s %s" % [row[0], row[1]])
		check(StoryDirector.get_current_objective() == StoryDirector.registry.get_stage(row[2]).objective_hint, "restored objective %s %s" % [row[0], row[1]])
	check(not QuestManager.world_flags.get("story.prologue.spm_completed", false) or StoryDirector.get_current_stage_id() == &"prologue.after_exam", "completion fact belongs to final profile")
