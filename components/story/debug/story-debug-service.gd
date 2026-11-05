class_name StoryDebugService extends RefCounted
## One read-only acquisition layer for runtime UI and tests. Never stored in Save V1.
var director
var revision := 0
var max_history_entries := 250
var enable_event_history := true
var _last_valid: Dictionary = {}
var _history: Array[Dictionary] = []
var _sequence := 0
var _attached := false
var _graph_cache: Dictionary = {}
func _init(source = null) -> void:
	director = source

func attach_runtime() -> void:
	if _attached or director == null: return
	_attached = true
	director.stage_changed.connect(_on_stage_changed)
	director.transition_completed.connect(_on_transition_completed)
	director.transition_rejected.connect(_on_transition_rejected)
	director.story_flag_changed.connect(_on_flag_changed)
	director.story_choice_recorded.connect(_on_choice)
	director.story_restored.connect(_on_restored)
	QuestManager.gameplay_event_accepted.connect(_on_gameplay_event)
	CutsceneFlow.sequence_finished.connect(_on_cutscene)
	SaveManager.operation_finished.connect(_on_save_operation)

func detach_runtime() -> void:
	if not _attached or director == null: return
	_attached = false
	for pair in [[director.stage_changed, _on_stage_changed], [director.transition_completed, _on_transition_completed], [director.transition_rejected, _on_transition_rejected], [director.story_flag_changed, _on_flag_changed], [director.story_choice_recorded, _on_choice], [director.story_restored, _on_restored], [QuestManager.gameplay_event_accepted, _on_gameplay_event], [CutsceneFlow.sequence_finished, _on_cutscene], [SaveManager.operation_finished, _on_save_operation]]:
		if pair[0].is_connected(pair[1]): pair[0].disconnect(pair[1])

func get_story_snapshot() -> Dictionary:
	revision += 1
	if director == null or not director.is_ready() or director.registry == null:
		var stale := _last_valid.duplicate(true)
		stale["revision"] = revision
		stale["stale"] = true
		stale["available"] = false
		stale["reason"] = "Story session loading or unavailable"
		return stale
	var state: StoryState = director.state
	var registry: StoryRegistry = director.registry
	var context := StoryContext.new(registry, state)
	var flags := {}
	var ids: Array = registry.flags.keys(); ids.sort()
	for id in ids:
		var definition: StoryFlagDefinition = registry.flags[id]
		flags[id] = {"value": context.flag_value(StringName(id)), "scope": StoryFlagDefinition.Scope.keys()[definition.scope], "recorded": QuestManager.world_flags.has(id) if definition.scope == StoryFlagDefinition.Scope.CAMPAIGN else state._transient.has(StringName(id))}
	var world_flags := {}
	var world_ids: Array = QuestManager.world_flags.keys(); world_ids.sort()
	for id in world_ids:
		if String(id).begins_with("story") and world_flags.size() < 256: world_flags[String(id)] = QuestManager.world_flags[id]
	var choices := {}
	for id in state.choices: choices[String(id)] = String(state.choices[id])
	var transitions: Array = state.receipts.keys(); transitions.sort()
	var actions: Array = state.action_receipts.keys(); actions.sort()
	var dialogues: Array = state.dialogue_receipts.keys(); dialogues.sort()
	var data := {"revision": revision, "available": true, "stale": false, "arc": String(state.arc_id), "chapter": String(state.chapter_id), "stage": String(state.stage_id), "objective": state.objective_text, "profile": SaveManager.active_profile, "loading": SaveManager.loading, "flags": flags, "world_flags": world_flags, "choices": choices, "completed_transitions": transitions, "completed_actions": actions, "completed_dialogues": dialogues, "transition_diagnostics": get_transition_diagnostics(state.stage_id)}
	_last_valid = data.duplicate(true)
	return data.duplicate(true)

func get_transition_diagnostics(stage_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if director == null or director.registry == null: return result
	var stage: StoryStageData = director.registry.get_stage(stage_id)
	if stage == null: return result
	for transition in stage.transitions:
		if transition == null: continue
		var status := "UNKNOWN"
		var reason := "Stage is not active"
		if director.is_ready() and director.state.stage_id == stage_id:
			var authoritative: StoryTransitionResult = director.get_transition_status(transition.transition_id)
			status = "AVAILABLE" if authoritative.status == StoryTransitionResult.Status.AVAILABLE else "BLOCKED_BY_CONDITION"
			reason = authoritative.reason
			var receipt := "%s:%s:%s" % [director.state.arc_id, director.state.chapter_id, transition.transition_id]
			if transition.once_only and director.state.receipts.has(receipt): status = "ALREADY_COMPLETED"
			elif not transition.required_choice_id.is_empty() and director.state.choices.get(transition.required_choice_id, &"") != transition.required_option_id: status = "AWAITING_PLAYER_CHOICE"
			elif not transition.required_event_target.is_empty(): status = "WAITING_FOR_EVENT" if status != "ALREADY_COMPLETED" else status
			elif authoritative.reason == "Invalid action" or authoritative.reason == "Unknown destination": status = "INVALID_REFERENCE"
		var traces: Array[Dictionary] = []
		for condition in transition.conditions:
			traces.append(get_condition_trace(condition))
		var actions: Array[String] = []
		for action in stage.on_exit_actions + transition.actions:
			if action: actions.append("%s%s" % [String(action.action_id), " (required)" if action.required else " (optional)"])
		result.append({"id": String(transition.transition_id), "source": String(stage_id), "target": String(transition.target_stage_id), "priority": transition.priority, "automatic": transition.automatic, "required_event": transition.required_event_target, "required_event_type": GameplayEvent.Type.keys()[transition.required_event_type], "required_choice": String(transition.required_choice_id), "required_option": String(transition.required_option_id), "status": status, "reason": reason, "conditions": traces, "actions": actions, "resource_path": transition.resource_path})
	result.sort_custom(func(a: Dictionary, b: Dictionary): return a.priority > b.priority if a.priority != b.priority else a.id < b.id)
	return result

func get_condition_trace(condition: StoryCondition) -> Dictionary:
	if director == null or not director.is_ready(): return {"result": "UNKNOWN", "reason": "Story unavailable", "children": [], "revision": revision}
	return StoryConditionTrace.runtime(condition, StoryContext.new(director.registry, director.state), revision)

func get_registered_story_graph() -> Dictionary:
	if director == null or director.database == null: return {"nodes": [], "edges": [], "issues": []}
	if _graph_cache.is_empty(): _graph_cache = StoryGraphAnalyzer.analyze(director.database)
	return _graph_cache.duplicate(true)

func get_validation_results() -> Array[Dictionary]:
	if director == null: return []
	return StoryResourceValidator.validate(director.database).duplicate(true)

func get_recent_story_events() -> Array[Dictionary]: return _history.duplicate(true)

func what_if(condition: StoryCondition, overrides: Dictionary) -> Dictionary:
	var snapshot := get_story_snapshot()
	if not snapshot.get("available", false): return {"result": "UNKNOWN", "reason": "No live story snapshot", "simulated": true}
	return StoryConditionTrace.simulated(condition, snapshot, overrides, revision)

func get_dialogue_diagnostics(target: Node) -> Dictionary:
	if not is_instance_valid(target): return {"available": false, "reason": "Target removed"}
	var resolver := target as StoryDialogueResolver
	if resolver == null: resolver = target.find_child("StoryDialogueResolver", true, false) as StoryDialogueResolver
	if resolver == null: return {"available": false, "reason": "No StoryDialogueResolver"}
	var selected := resolver.resolve_dialogue()
	var rows: Array[Dictionary] = []
	for variant in resolver.variants:
		if variant == null: continue
		var traces: Array[Dictionary] = []
		for condition in variant.conditions: traces.append(get_condition_trace(condition))
		rows.append({"id": String(variant.variant_id), "priority": variant.priority, "selected": variant == selected, "once_only": variant.once_only, "consumed": director.has_completed_dialogue(String(variant.variant_id)) if director and director.is_ready() else false, "conditions": traces, "timeline": variant.timeline.resource_path if variant.timeline else "", "direct_text": not variant.direct_text.is_empty()})
	rows.sort_custom(func(a: Dictionary, b: Dictionary): return a.priority > b.priority if a.priority != b.priority else a.id < b.id)
	return {"available": true, "node": str(resolver.get_path()), "selected": String(selected.variant_id) if selected else "fallback", "variants": rows, "warnings": resolver.validate_variants()}

func get_world_gating_diagnostics(target: Variant) -> Dictionary:
	if not is_instance_valid(target): return {"available": false, "reason": "Target removed"}
	if target is ElevatorPortal:
		var floor_rows: Array[Dictionary] = []
		for floor in target.floors:
			if floor == null: continue
			var row := get_world_gating_diagnostics(floor)
			row["accessible"] = (not target.use_locking or not floor.locked) and floor.story_allows()
			floor_rows.append(row)
		return {"available": true, "kind": "ElevatorPortal", "node": str(target.get_path()) if target.is_inside_tree() else "off-scene", "floors": floor_rows}
	var conditions: Array[StoryCondition] = []
	var kind: String = target.get_class()
	if target is StoryPresenceComponent or target is StoryWorldStateComponent:
		kind = target.get_script().get_global_name()
		if target.condition_component: conditions = target.condition_component.conditions
	elif target is StoryCutsceneTrigger:
		kind = "StoryCutsceneTrigger"
		if target.condition_component: conditions = target.condition_component.conditions
	elif target is ElevatorFloor:
		kind = "ElevatorFloor"; conditions = target.story_conditions
	elif target.has_method("story_unlocked"):
		kind = "ZonePortal"; conditions = target.entry_conditions
	else: return {"available": false, "reason": "No story gate on target"}
	var traces: Array[Dictionary] = []
	for condition in conditions: traces.append(get_condition_trace(condition))
	var eligible := traces.all(func(row: Dictionary): return row.result == "PASS")
	var output := {"available": true, "kind": kind, "node": str(target.get_path()) if target is Node and target.is_inside_tree() else "off-scene", "eligible": eligible, "conditions": traces}
	if target is StoryCutsceneTrigger:
		output["sequence"] = target.sequence.sequence_id if target.sequence else ""
		output["completed"] = target.sequence != null and QuestManager.world_flags.get(CutsceneFlow.flag_for(target.sequence), false)
		output["playback_active"] = CutsceneFlow.sequence != null
		output["playback_eligible"] = target.get_diagnostics().get("eligible", false)
	elif target is ElevatorFloor:
		output["destination"] = target.scene_id; output["legacy_locked"] = target.locked; output["accessible"] = target.is_accessible(); output["locked_hint"] = target.locked_hint
	elif target.has_method("story_unlocked"):
		output["destination"] = target.next_scene_id; output["unlocked"] = target.story_unlocked()
	elif target is StoryPresenceComponent:
		output["observed_visible"] = target.actor.visible if target.actor else null
	elif target is StoryWorldStateComponent and target.actuator:
		output["actuator_output"] = target.actuator.output
	return output

func _record(category: String, source: String, outcome: String, explanation: String) -> void:
	if not enable_event_history: return
	_sequence += 1
	_history.append({"sequence": _sequence, "category": category, "source": source, "stage": String(director.state.stage_id) if director else "", "outcome": outcome, "explanation": explanation, "revision": revision})
	while _history.size() > clampi(max_history_entries, 50, 1000): _history.pop_front()
func _on_stage_changed(previous_id: StringName, current_id: StringName) -> void: _record("stage", String(current_id), "CHANGED", String(previous_id) + " → " + String(current_id))
func _on_transition_completed(id: StringName) -> void: _record("transition", String(id), "COMPLETED", "Authoritative transition completed")
func _on_transition_rejected(id: StringName, reason: String) -> void: _record("transition", String(id), "REJECTED", reason)
func _on_flag_changed(id: StringName, _old: Variant, _new: Variant) -> void: _record("flag", String(id), "CHANGED", "Authoritative flag changed")
func _on_choice(id: StringName, option: StringName) -> void: _record("choice", String(id), "CONFIRMED", String(option))
func _on_restored() -> void:
	_record("session", "save", "RESTORED", "New diagnostic session boundary; prior history is not reconstructed")
func _on_gameplay_event(event: GameplayEvent) -> void:
	if event.type in [GameplayEvent.Type.WORLD_FLAG_CHANGED, GameplayEvent.Type.QUEST_COMPLETED, GameplayEvent.Type.LOCATION_REACHED, GameplayEvent.Type.DIALOGUE_COMPLETED]: _record("gameplay", event.target_id, "ACCEPTED", GameplayEvent.Type.keys()[event.type])
func _on_cutscene(sequence: CutsceneSequence, outcome: int) -> void:
	_record("cutscene", sequence.sequence_id if sequence else "", CutsceneFlow.Outcome.keys()[outcome], "CutsceneFlow resolved sequence")
func _on_save_operation(success: bool, message: String) -> void: _record("save", "campaign", "SUCCESS" if success else "FAILED", message)
