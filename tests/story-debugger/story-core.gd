extends Node
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STORY_DEBUG_CORE: " + message)
func _ready() -> void:
	await get_tree().process_frame
	SaveManager.session_ready = true
	StoryDirector._on_restored()
	var service := StoryDebugService.new(StoryDirector)
	service.attach_runtime()
	service.attach_runtime()
	var before := StorySaveService.encode(StoryDirector.state, StoryDirector.registry)
	var world_before := QuestManager.world_flags.duplicate(true)
	var changes := [0]
	StoryDirector.story_state_changed.connect(func(): changes[0] += 1)
	var snapshot := service.get_story_snapshot()
	check(snapshot.available and snapshot.stage == "prologue.wake_up", "current stage snapshot")
	check(snapshot.flags.has("story.prologue.spm_completed"), "registered flags visible")
	var flag := StoryFlagCondition.new()
	flag.flag_definition = StoryDirector.registry.get_flag_definition(&"story.prologue.spm_completed")
	flag.expected_value = true
	var trace := service.get_condition_trace(flag)
	check(trace.result == "FAIL" and trace.observed == false, "false flag explained")
	var what_if := service.what_if(flag, {"story.prologue.spm_completed": true})
	check(what_if.result == "PASS" and what_if.simulated, "isolated what-if comparison")
	check(StoryDirector.get_flag(&"story.prologue.spm_completed") == false, "what-if leaves live flag intact")
	var all := StoryAllCondition.new()
	all.conditions = [flag, StoryStageCondition.new()]
	var nested := service.get_condition_trace(all)
	check(nested.result == "FAIL" and nested.children.size() == 2 and nested.children[1].result == "SKIPPED", "short-circuit trace")
	snapshot.flags["story.prologue.spm_completed"].value = true
	snapshot.choices["fake"] = "fake"
	check(StoryDirector.get_flag(&"story.prologue.spm_completed") == false and StoryDirector.state.choices.is_empty(), "returned snapshot detached")
	check(StorySaveService.encode(StoryDirector.state, StoryDirector.registry) == before and QuestManager.world_flags == world_before and changes[0] == 0, "inspection emits no progression")
	var graph := service.get_registered_story_graph()
	check(graph.nodes.size() == 5, "authored prologue graph extracted")
	check(graph.issues.any(func(row: Dictionary): return row.code == "STORY_STRUCTURALLY_UNREACHABLE"), "missing production transitions identified")
	var synthetic := StoryDatabase.new()
	var arc := StoryArcData.new(); arc.arc_id = &"test.arc"; arc.initial_chapter_id = &"test.chapter"
	var chapter := StoryChapterData.new(); chapter.chapter_id = &"test.chapter"; chapter.initial_stage_id = &"test.a"
	var a := StoryStageData.new(); a.stage_id = &"test.a"
	var b := StoryStageData.new(); b.stage_id = &"test.b"
	var c := StoryStageData.new(); c.stage_id = &"test.c"
	var ab := StoryTransitionData.new(); ab.transition_id = &"test.ab"; ab.target_stage_id = &"test.b"; ab.conditions.append(flag)
	var ba := StoryTransitionData.new(); ba.transition_id = &"test.ba"; ba.target_stage_id = &"test.a"; ba.conditions.append(flag)
	a.transitions = [ab]; b.transitions = [ba]
	chapter.stages = [a, b, c]; arc.chapters = [chapter]; synthetic.arcs = [arc]; synthetic.flags = [flag.flag_definition]
	var analysis := StoryGraphAnalyzer.analyze(synthetic)
	check(analysis.issues.any(func(row: Dictionary): return row.code == "STORY_POSSIBLE_AUTO_LOOP"), "automatic SCC detected")
	check(analysis.issues.any(func(row: Dictionary): return row.resource_id == "test.c" and row.code == "STORY_STRUCTURALLY_UNREACHABLE"), "unreachable stage detected")
	check(StoryResourceValidator.validate(synthetic).any(func(row: Dictionary): return row.code == "STORY_POSSIBLE_AUTO_LOOP"), "editor-safe validator shares graph analysis")
	var duplicate_a := StoryAction.new(); duplicate_a.action_id = &"test.duplicate"
	var duplicate_b := StoryAction.new(); duplicate_b.action_id = &"test.duplicate"
	ab.actions = [duplicate_a, duplicate_b]
	check(StoryResourceValidator.validate(synthetic).any(func(row: Dictionary): return row.code == "STORY_DUPLICATE_ACTION_RECEIPT"), "duplicate action receipt identity detected")
	ab.actions.clear()
	var portal: Variant = load("res://scenes/transitioners/zone-portal/zone-portal.gd").new()
	portal.entry_conditions.append(flag)
	check(service.get_world_gating_diagnostics(portal).eligible == false, "portal gate diagnosed without transition")
	portal.free()
	var floor := ElevatorFloor.new(); floor.scene_id = "test.destination"; floor.story_conditions.append(flag)
	check(not service.get_world_gating_diagnostics(floor).accessible, "elevator gate diagnosed without navigation")
	var lift := ElevatorPortal.new(); lift.floors = [floor]
	check(service.get_world_gating_diagnostics(lift).floors.size() == 1, "elevator portal exposes floor diagnostics")
	lift.free()
	var resolver := StoryDialogueResolver.new()
	var variant := StoryDialogueVariant.new(); variant.variant_id = &"test.dialogue"; variant.direct_text = "Test fixture"; variant.conditions.append(flag)
	resolver.variants = [variant]
	check(service.get_dialogue_diagnostics(resolver).selected == "fallback", "dialogue resolver inspected without playback")
	resolver.free()
	var presence := StoryPresenceComponent.new()
	var gate := StoryConditionComponent.new(); gate.conditions.append(flag); presence.condition_component = gate
	check(not service.get_world_gating_diagnostics(presence).eligible, "NPC presence condition diagnosed")
	presence.free(); gate.free()
	check(service.get_recent_story_events().is_empty(), "inspection adds no diagnostic events")
	service.max_history_entries = 50
	for index in 55: service._record("test", str(index), "OBSERVED", "bounded history fixture")
	var history := service.get_recent_story_events()
	check(history.size() == 50 and history[0].sequence == 6 and history[-1].sequence == 55, "event history is bounded and ordered")
	service.detach_runtime()
	print("STORY_DEBUG_CORE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
