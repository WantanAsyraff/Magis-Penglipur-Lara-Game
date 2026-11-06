extends Node

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROLOGUE_MIGRATION: " + label)

func _ready() -> void:
	var director := StoryDirector
	var registry := director.registry
	check(registry.errors.is_empty(), "production registry valid")
	var graph := StoryGraphAnalyzer.analyze(director.database)
	check(graph.edges.size() == 4, "four authored edges")
	check(not graph.issues.any(func(row: Dictionary): return row.code == "STORY_STRUCTURALLY_UNREACHABLE"), "all stages reachable")
	check(not StoryResourceValidator.validate(director.database).any(func(row: Dictionary): return row.severity == "ERROR"), "authoring validation has no errors")
	check(StorySaveService.stage(null, registry, {"world_flags": {"story.prologue.reached_school": true}}).active_stage_id == "prologue.reach_school", "legacy school arrival uses recorded fact")
	var ids := [&"prologue.wake_up", &"prologue.leave_house", &"prologue.reach_school", &"prologue.spm_practical", &"prologue.after_exam"]
	for id in ids: check(registry.get_stage(id) != null, "canonical stage " + String(id))
	var previous_ready := SaveManager.session_ready
	SaveManager.session_ready = true
	director._on_restored()
	check(director.get_current_stage_id() == ids[0], "fresh start at wake up")
	check(director.get_available_transitions(null, true).is_empty(), "intro cannot advance before completion")
	QuestManager.set_world_flag("story_sequence:prologue.kampung", true)
	await get_tree().process_frame
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[1], "completed kampung sequence advances")
	check(director.get_transition_status(&"prologue.leave_house_to_reach_school").status == StoryTransitionResult.Status.BLOCKED, "arrival needs current event")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "wrong.arrival", 1, QuestManager.active_owner_id))
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[1], "wrong arrival ignored")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id))
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[2], "school arrival advances")
	QuestManager.set_world_flag("story_sequence:prologue.school", true)
	await get_tree().process_frame
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[3], "completed school sequence advances")
	var exam_portal: Node = load("res://scenes/transitioners/zone-portal/zone-portal.gd").new()
	exam_portal.set("practical_completion_portal", true)
	check(not exam_portal.story_unlocked(), "exam exit blocked before demonstration")
	check(director.get_available_transitions(null, true).is_empty(), "entering practical is insufficient")
	QuestManager.set_world_flag("story.prologue.spm_completed", true)
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[3], "completion without demonstration is insufficient")
	QuestManager.set_world_flag("story.prologue.practical_demonstrated", true)
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[3], "demonstration alone is insufficient")
	check(exam_portal.story_unlocked(), "exam exit opens after demonstration")
	QuestManager.set_world_flag("story.prologue.spm_completed", false)
	QuestManager.set_world_flag("story.prologue.spm_completed", true)
	await get_tree().process_frame
	check(director.get_current_stage_id() == ids[4], "confirmed practical completion advances")
	check(director.state.receipts.size() == 4, "four stable receipts")
	check(director.get_available_transitions(null, true).is_empty(), "after exam is terminal")
	exam_portal.free()
	SaveManager.session_ready = previous_ready
	director.state.clear()
	for flag in ["story_sequence:prologue.kampung", "story_sequence:prologue.school", "story.prologue.spm_completed", "story.prologue.practical_demonstrated"]: QuestManager.world_flags.erase(flag)
	print("PROLOGUE_MIGRATION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
