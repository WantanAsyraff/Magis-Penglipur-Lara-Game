extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("STORY_TRANSITIONS: " + label)
func _ready() -> void:
 var ready_before := SaveManager.session_ready
 SaveManager.session_ready = true
 StoryDirector._on_restored()
 var director := StoryDirector
 var source := director.registry.get_stage(&"prologue.wake_up")
 var second := director.registry.get_stage(&"prologue.leave_house")
 var third := director.registry.get_stage(&"prologue.reach_school")
 var original_source := source.transitions.duplicate()
 var original_second := second.transitions.duplicate()
 var original_third := third.transitions.duplicate()
 var first := StoryTransitionData.new()
 first.transition_id = &"test.wake_leave"
 first.target_stage_id = second.stage_id
 first.automatic = false
 var objective := SetStoryObjectiveAction.new()
 objective.objective_id = &"test.leave"
 objective.action_id = &"test.objective.leave"
 objective.display_text = "Go to school"
 var flag_action := SetStoryFlagAction.new()
 flag_action.flag_definition = director.registry.get_flag_definition(&"story.prologue.left_house")
 flag_action.value = true
 flag_action.required = false
 first.actions = [objective, flag_action]
 source.transitions = [first]
 check(director.get_transition_status(first.transition_id).status == StoryTransitionResult.Status.AVAILABLE, "manual transition eligible")
 check(director.get_available_transitions(null, true).is_empty(), "manual transition not automatic")
 check(director.request_transition(&"wrong").status == StoryTransitionResult.Status.BLOCKED, "unknown transition rejected")
 check(director.request_transition(first.transition_id).status == StoryTransitionResult.Status.COMPLETED, "manual transition executes")
 check(director.get_current_stage_id() == second.stage_id, "stage advanced")
 check(director.get_current_objective() == "Go to school", "objective action applied")
 check(QuestManager.world_flags.get("story.prologue.left_house", false), "flag action delegated to QuestManager")
 check(director.state.receipts.size() == 1, "session receipt recorded")
 check(director.request_transition(first.transition_id).status == StoryTransitionResult.Status.BLOCKED, "old source rejected")
 var event_transition := StoryTransitionData.new()
 event_transition.transition_id = &"test.leave_school"
 event_transition.target_stage_id = third.stage_id
 event_transition.required_event_target = "test.school_arrival"
 second.transitions = [event_transition]
 check(director.get_transition_status(event_transition.transition_id).status == StoryTransitionResult.Status.BLOCKED, "historical state cannot substitute event")
 var bad := GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "wrong", 1, QuestManager.active_owner_id)
 QuestManager.publish(bad)
 await get_tree().process_frame
 check(director.get_current_stage_id() == second.stage_id, "wrong event ignored")
 var good := GameplayEvent.new(GameplayEvent.Type.WORLD_FLAG_CHANGED, "test.school_arrival", 1, QuestManager.active_owner_id)
 check(QuestManager.publish(good), "legitimate event accepted")
 check(not QuestManager.publish(good), "duplicate event rejected")
 await get_tree().process_frame
 await get_tree().process_frame
 check(director.get_current_stage_id() == third.stage_id, "accepted event advanced automatically")
 var choice := StoryChoiceData.new()
 choice.choice_id = &"test.route"
 var option := StoryChoiceOptionData.new()
 option.option_id = &"talk"
 choice.options = [option]
 director.registry.choices[String(choice.choice_id)] = choice
 var branch := StoryTransitionData.new()
 branch.transition_id = &"test.route.talk"
 branch.target_stage_id = &"prologue.after_exam"
 branch.automatic = false
 branch.required_choice_id = choice.choice_id
 branch.required_option_id = option.option_id
 third.transitions = [branch]
 check(director.get_available_transitions().is_empty(), "choice branch needs confirmation")
 check(not director.confirm_choice(choice, &"wrong"), "invalid choice rejected")
 check(director.get_recorded_choice(choice.choice_id).is_empty(), "invalid choice records nothing")
 check(director.confirm_choice(choice, option.option_id), "confirmed choice commits branch")
 check(director.get_recorded_choice(choice.choice_id) == option.option_id, "confirmed option recorded")
 check(not director.confirm_choice(choice, option.option_id), "duplicate choice rejected")
 source.transitions = original_source
 second.transitions = original_second
 third.transitions = original_third
 director.registry.choices.erase(String(choice.choice_id))
 QuestManager.world_flags.erase("story.prologue.left_house")
 director.state.clear()
 SaveManager.session_ready = ready_before
 print("STORY_TRANSITIONS: %d checks, %d failures" % [checks, failures])
 get_tree().quit(failures)
