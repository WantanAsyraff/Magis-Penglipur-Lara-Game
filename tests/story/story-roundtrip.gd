extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("STORY_ROUNDTRIP: " + label)
func _ready() -> void:
 await get_tree().process_frame
 get_tree().current_scene = null
 if "--quest-test-mode" not in OS.get_cmdline_user_args():
  push_error("Use isolated --quest-test-mode")
  get_tree().quit(2)
  return
 var registry := StoryDirector.registry
 var variable := StoryFlagDefinition.new()
 variable.flag_id = &"story.prologue.test_score"
 variable.value_type = StoryFlagDefinition.ValueType.INTEGER
 variable.scope = StoryFlagDefinition.Scope.PERSISTENT_TYPED
 variable.default_value = 0
 registry.flags[String(variable.flag_id)] = variable
 var choice := StoryChoiceData.new()
 choice.choice_id = &"test.route"
 var option := StoryChoiceOptionData.new()
 option.option_id = &"talk"
 choice.options = [option]
 registry.choices[String(choice.choice_id)] = choice
 var stage := registry.get_stage(&"prologue.wake_up")
 var second := registry.get_stage(&"prologue.leave_house")
 var original := stage.transitions.duplicate()
 var original_second := second.transitions.duplicate()
 var transition := StoryTransitionData.new()
 transition.transition_id = &"test.saved_transition"
 transition.target_stage_id = &"prologue.leave_house"
 transition.automatic = false
 var objective := SetStoryObjectiveAction.new()
 objective.action_id = &"test.saved_objective"
 objective.objective_id = &"test.leave"
 objective.display_text = "Leave house"
 transition.actions = [objective]
 stage.transitions = [transition]
 registry.transitions[String(transition.transition_id)] = transition
 registry.transition_sources[String(transition.transition_id)] = String(stage.stage_id)
 registry.actions[String(objective.action_id)] = objective
 var branch := StoryTransitionData.new()
 branch.transition_id = &"test.saved_branch"
 branch.target_stage_id = &"prologue.after_exam"
 branch.automatic = false
 branch.required_choice_id = choice.choice_id
 branch.required_option_id = option.option_id
 second.transitions = [branch]
 registry.transitions[String(branch.transition_id)] = branch
 registry.transition_sources[String(branch.transition_id)] = String(second.stage_id)
 if "--write-story-save" in OS.get_cmdline_user_args():
  check(await SaveManager.new_game(3, "Story Fixture", true), "new campaign")
  check(StoryDirector.set_flag(variable.flag_id, 7), "persistent typed variable")
  check(StoryDirector.request_transition(transition.transition_id).status == StoryTransitionResult.Status.COMPLETED, "actual transition")
  check(StoryDirector.confirm_choice(choice, option.option_id), "confirmed branch")
  check(StoryDirector.complete_dialogue("test.saved_dialogue"), "one-time dialogue receipt recorded")
  check(StoryDirector.get_diagnostics().unsaved_story_changes, "diagnostics identify unsaved progression")
  check(not StorySaveService.stage(StorySaveService.encode(StoryDirector.state, registry), registry).is_empty(), "story payload valid before save")
  check(SaveManager.save_active(), "manual save: " + SaveManager.last_error)
  check(not StoryDirector.get_diagnostics().unsaved_story_changes, "successful save clears dirty story status")
 else:
  var file_data := GameSaveStore.read(SaveManager.path_for(3))
  check(not file_data.is_empty(), "saved envelope valid")
  check(not StorySaveService.stage(file_data.get("story"), registry).is_empty(), "story payload stages")
  check(not GameSaveSchema.stage(file_data, 3, Scene_Registry).is_empty(), "full payload stages")
  check(await SaveManager.load_slot(3), "fresh process load: " + SaveManager.last_error)
  check(StoryDirector.get_current_stage_id() == &"prologue.after_exam", "stage restored")
  check(StoryDirector.get_flag(variable.flag_id) == 7, "typed variable restored")
  check(StoryDirector.get_recorded_choice(choice.choice_id) == option.option_id, "choice restored")
  check(StoryDirector.state.receipts.size() == 2, "transition receipts restored")
  check(StoryDirector.state.action_receipts.size() == 1, "action receipt restored")
  check(StoryDirector.has_completed_dialogue("test.saved_dialogue"), "dialogue receipt restored")
  check(not StoryDirector.complete_dialogue("test.saved_dialogue"), "restored dialogue cannot complete twice")
  check(StoryDirector.get_current_objective() == registry.get_stage(&"prologue.after_exam").objective_hint, "stage objective restored without action replay")
  var damaged := file_data.duplicate(true)
  damaged.story.active_stage_id = "missing.stage"
  check(GameSaveSchema.stage(damaged, 3, Scene_Registry).is_empty(), "invalid story rejected before live mutation")
  check(StoryDirector.get_current_stage_id() == &"prologue.after_exam", "failed staging preserves current story")
  var legacy_save := file_data.duplicate(true)
  legacy_save.erase("story")
  var legacy_stage := GameSaveSchema.stage(legacy_save, 3, Scene_Registry)
  check(not legacy_stage.is_empty() and legacy_stage.story.active_stage_id == "prologue.wake_up", "legacy Save V1 stages without story section")
  check(await SaveManager.new_game(2, "Other Story", true), "second profile starts")
  check(StoryDirector.get_current_stage_id() == &"prologue.wake_up", "second profile has initial stage")
  check(StoryDirector.get_flag(variable.flag_id) == 0, "second profile has default variable")
  check(await SaveManager.load_slot(3), "first profile reloads after switch")
  check(StoryDirector.get_current_stage_id() == &"prologue.after_exam" and StoryDirector.get_flag(variable.flag_id) == 7, "first profile story remains isolated")
 stage.transitions = original
 second.transitions = original_second
 registry.transitions.erase(String(transition.transition_id))
 registry.transition_sources.erase(String(transition.transition_id))
 registry.transitions.erase(String(branch.transition_id))
 registry.transition_sources.erase(String(branch.transition_id))
 registry.actions.erase(String(objective.action_id))
 print("STORY_ROUNDTRIP: %d checks, %d failures" % [checks, failures])
 get_tree().quit(failures)
