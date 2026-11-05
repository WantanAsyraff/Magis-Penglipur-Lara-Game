extends Node
signal story_initialized
signal story_restored
signal story_state_changed
signal story_flag_changed(flag_id: StringName, old_value: Variant, new_value: Variant)
signal chapter_changed(previous_id: StringName, current_id: StringName)
signal stage_changed(previous_id: StringName, current_id: StringName)
signal transition_completed(transition_id: StringName)
signal transition_rejected(transition_id: StringName, reason: String)
signal story_notification(event_id: StringName)
signal story_choice_recorded(choice_id: StringName, option_id: StringName)
@export var database: StoryDatabase = preload("res://data/story/definitions/story-database.tres")
var registry: StoryRegistry
var state := StoryState.new()
var _processing := false
var _automatic_queued := false
var _pending_events: Array[GameplayEvent] = []
var _last_committed_story: Dictionary = {}
var _last_save_status := "No campaign save observed"
var _presented_objective := ""
const MAX_AUTOMATIC_PER_PASS := 16
const MAX_PENDING_EVENTS := 128
func _ready() -> void:
 registry = StoryRegistry.new(database)
 if not registry.errors.is_empty(): push_error("Story database invalid: " + "; ".join(registry.errors))
 SaveManager.restored.connect(_on_restored)
 SaveManager.operation_finished.connect(_on_save_operation)
 story_state_changed.connect(_refresh_objective_presentation)
 QuestManager.quests_changed.connect(func(): if is_ready(): story_state_changed.emit())
 CutsceneFlow.sequence_finished.connect(func(_sequence, outcome): if is_ready() and outcome != CutsceneFlow.Outcome.INTERRUPTED: story_state_changed.emit())
 QuestManager.world_flag_changed.connect(_on_world_flag_changed)
 QuestManager.gameplay_event_accepted.connect(_on_gameplay_event)
 if SaveManager.session_ready and not SaveManager.loading: _on_restored()
func _on_restored() -> void:
 if not registry.errors.is_empty(): return
 _pending_events.clear()
 if state.lifecycle != StoryState.Lifecycle.READY:
  var initial := StorySaveService.defaults(registry)
  if initial.is_empty(): return
  StorySaveService.apply(state, initial)
 if state.objective_text.is_empty(): state.objective_text = registry.get_stage(state.stage_id).objective_hint
 _last_committed_story = {} if SaveManager._creating_new_game else StorySaveService.encode(state, registry)
 _last_save_status = "New campaign awaiting save" if SaveManager._creating_new_game else "Campaign restored"
 story_initialized.emit()
 story_restored.emit()
 story_state_changed.emit()
func is_ready() -> bool: return state.lifecycle == StoryState.Lifecycle.READY and SaveManager.session_ready and not SaveManager.loading
func is_restoring() -> bool: return SaveManager.loading or QuestManager._restoring or state.lifecycle == StoryState.Lifecycle.RESTORING
func get_current_arc_id() -> StringName: return state.arc_id if is_ready() else &""
func get_current_chapter_id() -> StringName: return state.chapter_id if is_ready() else &""
func get_current_stage_id() -> StringName: return state.stage_id if is_ready() else &""
func get_arc(id: StringName) -> StoryArcData: return registry.get_arc(id)
func get_chapter(id: StringName) -> StoryChapterData: return registry.get_chapter(id)
func get_stage(id: StringName) -> StoryStageData: return registry.get_stage(id)
func get_flag(id: StringName) -> Variant:
 return StoryContext.new(registry, state).flag_value(id)
func has_flag(id: StringName) -> bool: return registry.get_flag_definition(id) != null
func set_flag(id: StringName, value: Variant) -> bool:
 var definition := registry.get_flag_definition(id)
 if definition == null or not definition.valid_value(value) or not is_ready() or is_restoring() or not QuestManager.authoritative():
  push_warning("StoryDirector rejected flag mutation: " + String(id))
  return false
 var old: Variant = get_flag(id)
 if old == value: return false
 if definition.scope == StoryFlagDefinition.Scope.CAMPAIGN:
  return QuestManager.set_world_flag(String(id), value)
 state.write_transient(id, value)
 story_flag_changed.emit(id, old, value)
 story_state_changed.emit()
 return true
func evaluate_condition(condition: StoryCondition) -> bool:
 return is_ready() and StoryConditionEvaluator.evaluate(condition, StoryContext.new(registry, state))
func _on_world_flag_changed(id: String, old_value: bool, value: bool) -> void:
 if is_ready() and registry.get_flag_definition(StringName(id)) != null:
  story_flag_changed.emit(StringName(id), old_value, value)
  story_state_changed.emit()
 if is_ready(): _queue_automatic()
func _on_gameplay_event(event: GameplayEvent) -> void:
 if not is_ready() or event.owner_id != QuestManager.active_owner_id: return
 if _pending_events.size() >= MAX_PENDING_EVENTS:
  push_warning("Story event queue full")
  return
 _pending_events.append(event)
 _queue_automatic()
func _queue_automatic() -> void:
 if _automatic_queued or not is_ready(): return
 _automatic_queued = true
 call_deferred("_run_automatic")
func _run_automatic() -> void:
 _automatic_queued = false
 if not is_ready() or _processing: return
 for i in MAX_AUTOMATIC_PER_PASS:
  var event: GameplayEvent = _pending_events.pop_front() if not _pending_events.is_empty() else null
  var available := get_available_transitions(event, true)
  if available.is_empty():
   if event != null: continue
   return
  var result := request_transition(available[0].transition_id, event)
  if result.status != StoryTransitionResult.Status.COMPLETED: return
 _pending_events.clear()
 push_warning("Story automatic transition budget reached")
func _current_stage() -> StoryStageData:
 return registry.get_stage(state.stage_id) if is_ready() else null
func _receipt(id: StringName) -> String:
 return "%s:%s:%s" % [state.arc_id, state.chapter_id, id]
func _find_transition(id: StringName) -> StoryTransitionData:
 var stage := _current_stage()
 if stage:
  for transition in stage.transitions:
   if transition != null and transition.transition_id == id: return transition
 return null
func get_available_transitions(event: GameplayEvent = null, automatic_only: bool = false) -> Array[StoryTransitionData]:
 var result: Array[StoryTransitionData] = []
 var stage := _current_stage()
 if stage == null: return result
 for transition in stage.transitions:
  if transition == null or (automatic_only and not transition.automatic): continue
  if get_transition_status(transition.transition_id, event).status == StoryTransitionResult.Status.AVAILABLE: result.append(transition)
 result.sort_custom(func(a: StoryTransitionData, b: StoryTransitionData): return a.priority > b.priority if a.priority != b.priority else String(a.transition_id) < String(b.transition_id))
 return result
func get_transition_status(id: StringName, event: GameplayEvent = null) -> StoryTransitionResult:
 if not is_ready() or is_restoring(): return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Story session unavailable")
 var transition := _find_transition(id)
 if transition == null: return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Transition not owned by current stage")
 if transition.once_only and state.receipts.has(_receipt(id)): return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Already completed this session")
 if registry.get_stage(transition.target_stage_id) == null: return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Unknown destination")
 if not transition.required_choice_id.is_empty() and state.choices.get(transition.required_choice_id, &"") != transition.required_option_id: return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Confirmed choice required")
 if not transition.required_event_target.is_empty() and (event == null or event.type != transition.required_event_type or event.target_id != transition.required_event_target): return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Required current-stage event missing")
 for condition in transition.conditions:
  if not evaluate_condition(condition): return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Condition unmet or invalid")
 var source := _current_stage()
 var target := registry.get_stage(transition.target_stage_id)
 for action in source.on_exit_actions + transition.actions + target.on_enter_actions:
  if action == null or not action.validate(registry).is_empty(): return StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Invalid action")
 return StoryTransitionResult.new(id, StoryTransitionResult.Status.AVAILABLE)
func request_transition(id: StringName, event: GameplayEvent = null) -> StoryTransitionResult:
 var status := get_transition_status(id, event)
 if _processing or not QuestManager.authoritative() or (event != null and event.owner_id != QuestManager.active_owner_id): status = StoryTransitionResult.new(id, StoryTransitionResult.Status.BLOCKED, "Unauthorized or reentrant request")
 if status.status != StoryTransitionResult.Status.AVAILABLE:
  transition_rejected.emit(id, status.reason)
  return status
 _processing = true
 var transition := _find_transition(id)
 var source := _current_stage()
 var target := registry.get_stage(transition.target_stage_id)
 var context := StoryActionContext.new(self, source, target, transition, event)
 var actions: Array = source.on_exit_actions + transition.actions + target.on_enter_actions
 var completed_actions: Array[String] = []
 for action: StoryAction in actions:
  var result := action.execute(context)
  if action.required and result not in [StoryAction.Result.SUCCESS, StoryAction.Result.NO_CHANGE]:
   _processing = false
   status = StoryTransitionResult.new(id, StoryTransitionResult.Status.FAILED, "Required action failed")
   transition_rejected.emit(id, status.reason)
   return status
  if action.required and not action.action_id.is_empty(): completed_actions.append(context.receipt + ":" + String(action.action_id))
 var old_stage := state.stage_id
 var old_chapter := state.chapter_id
 state.stage_id = target.stage_id
 for arc in registry.arcs.values():
  for chapter in arc.chapters:
   if target in chapter.stages:
    state.chapter_id = chapter.chapter_id
    state.arc_id = arc.arc_id
 if transition.once_only: state.receipts[context.receipt] = true
 for action_receipt in completed_actions: state.action_receipts[action_receipt] = true
 if not actions.any(func(action: StoryAction): return action is SetStoryObjectiveAction):
  state.objective_id = &""
  state.objective_text = target.objective_hint
 if old_chapter != state.chapter_id: chapter_changed.emit(old_chapter, state.chapter_id)
 stage_changed.emit(old_stage, state.stage_id)
 transition_completed.emit(id)
 story_state_changed.emit()
 _processing = false
 for action: StoryAction in actions:
  if action is RequestStoryAutosaveAction and not action.required and SaveManager.session_ready and not SaveManager.loading:
   SaveManager.request_autosave()
   break
 return StoryTransitionResult.new(id, StoryTransitionResult.Status.COMPLETED)
func get_current_objective() -> String: return state.objective_text if is_ready() else ""
func get_recorded_choice(id: StringName) -> StringName: return state.choices.get(id, &"")
func confirm_choice(choice: StoryChoiceData, option_id: StringName) -> bool:
 if not is_ready() or is_restoring() or _processing or choice == null or registry.get_choice(choice.choice_id) != choice or state.choices.has(choice.choice_id) or not QuestManager.authoritative(): return false
 var selected: StoryChoiceOptionData
 for option in choice.options:
  if option != null and option.option_id == option_id: selected = option
 if selected == null: return false
 for condition in selected.conditions:
  if not evaluate_condition(condition): return false
 var matching: Array[StoryTransitionData] = []
 var stage := _current_stage()
 for transition in stage.transitions:
  if transition != null and transition.required_choice_id == choice.choice_id and transition.required_option_id == option_id: matching.append(transition)
 if matching.size() != 1: return false
 state.choices[choice.choice_id] = option_id
 var result := request_transition(matching[0].transition_id)
 if result.status != StoryTransitionResult.Status.COMPLETED:
  state.choices.erase(choice.choice_id)
  return false
 story_choice_recorded.emit(choice.choice_id, option_id)
 return true
func get_diagnostics() -> Dictionary:
 var blocked := {}
 var stage := _current_stage()
 if stage:
  for transition in stage.transitions: if transition: blocked[transition.transition_id] = get_transition_status(transition.transition_id).reason
 return {"profile": SaveManager.active_profile, "arc": state.arc_id, "chapter": state.chapter_id, "stage": state.stage_id, "transitions": blocked, "completed_transitions": state.receipts.size(), "completed_actions": state.action_receipts.size(), "choices": state.choices.size(), "persistent_variables": StorySaveService.encode(state, registry).get("variables", {}).size(), "unsaved_story_changes": StorySaveService.encode(state, registry) != _last_committed_story, "last_save_status": _last_save_status, "persistence": "Campaign V1 + Story V1"}
func _on_save_operation(success: bool, message: String) -> void:
 if success and message == "Game saved." and state.lifecycle == StoryState.Lifecycle.READY:
  _last_committed_story = StorySaveService.encode(state, registry)
 _last_save_status = message

func complete_dialogue(variant_id: String) -> bool:
 if not is_ready() or is_restoring() or not QuestManager.authoritative() or not registry._id(variant_id) or has_completed_dialogue(variant_id): return false
 state.dialogue_receipts[variant_id] = true
 story_state_changed.emit()
 SaveManager.request_autosave()
 return true
func has_completed_dialogue(variant_id: String) -> bool:
 return state.dialogue_receipts.has(variant_id) or QuestManager.world_flags.get("story_dialogue:" + variant_id, false)
func _refresh_objective_presentation() -> void:
 if not is_ready(): return
 var goals := Player_Global_Data.active_goals.duplicate()
 if not _presented_objective.is_empty(): goals.erase(_presented_objective)
 _presented_objective = "Main Story: " + state.objective_text if not state.objective_text.is_empty() else ""
 if not _presented_objective.is_empty() and not goals.has(_presented_objective): goals.push_front(_presented_objective)
 if goals != Player_Global_Data.active_goals: Player_Global_Data.active_goals = goals
