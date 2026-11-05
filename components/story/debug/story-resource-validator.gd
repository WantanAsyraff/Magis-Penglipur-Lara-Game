@tool
class_name StoryResourceValidator extends RefCounted
## Static, editor-safe checks. External gameplay registries are deliberately not loaded.
static func validate(database: StoryDatabase) -> Array[Dictionary]:
	var report: Array[Dictionary] = StoryGraphAnalyzer.analyze(database).issues
	if database == null: return report
	var arcs := {}
	var chapters := {}
	var stages := {}
	var flags := {}
	var choices := {}
	var transitions := {}
	for definition in database.flags:
		if definition == null:
			report.append(_issue("ERROR", "STORY_NULL_FLAG", "Null flag definition", database, "", "flags")); continue
		var id := String(definition.flag_id)
		if not _valid_id(id) or flags.has(id): report.append(_issue("ERROR", "STORY_DUPLICATE_FLAG", "Invalid or duplicate flag ID", definition, id, "flag_id"))
		flags[id] = definition
		if not _valid_flag_value(definition, definition.default_value): report.append(_issue("ERROR", "STORY_INVALID_FLAG_DEFAULT", "Flag default has wrong type", definition, id, "default_value"))
	for choice in database.choices:
		if choice == null: report.append(_issue("ERROR", "STORY_NULL_CHOICE", "Null choice", database, "", "choices")); continue
		var id := String(choice.choice_id)
		if not _valid_id(id) or choices.has(id): report.append(_issue("ERROR", "STORY_DUPLICATE_CHOICE", "Invalid or duplicate choice ID", choice, id, "choice_id"))
		choices[id] = choice
		var options := {}
		for option in choice.options:
			if option == null or not _valid_id(String(option.option_id)) or options.has(String(option.option_id) if option else ""):
				report.append(_issue("ERROR", "STORY_INVALID_CHOICE_OPTION", "Null or duplicate choice option", choice, id, "options"))
			else: options[String(option.option_id)] = true
	for arc in database.arcs:
		if arc == null: continue
		var aid := String(arc.arc_id)
		if not _valid_id(aid) or arcs.has(aid): report.append(_issue("ERROR", "STORY_DUPLICATE_ARC", "Invalid or duplicate arc ID", arc, aid, "arc_id"))
		arcs[aid] = arc
		for chapter in arc.chapters:
			if chapter == null: continue
			var cid := String(chapter.chapter_id)
			if not _valid_id(cid) or chapters.has(cid): report.append(_issue("ERROR", "STORY_DUPLICATE_CHAPTER", "Invalid or duplicate chapter ID", chapter, cid, "chapter_id"))
			chapters[cid] = chapter
			for stage in chapter.stages:
				if stage != null: stages[String(stage.stage_id)] = stage
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage == null: continue
				var sid := String(stage.stage_id)
				for action in stage.on_enter_actions: _check_action(action, sid, "on_enter_actions", flags, choices, report)
				for action in stage.on_exit_actions: _check_action(action, sid, "on_exit_actions", flags, choices, report)
				for transition in stage.transitions:
					if transition == null: continue
					var tid := String(transition.transition_id)
					if not _valid_id(tid) or transitions.has(tid): report.append(_issue("ERROR", "STORY_DUPLICATE_TRANSITION", "Invalid or duplicate transition ID", transition, tid, "transition_id"))
					transitions[tid] = true
					if transition.required_choice_id != &"" and not choices.has(String(transition.required_choice_id)):
						report.append(_issue("ERROR", "STORY_UNKNOWN_CHOICE", "Transition requires an unregistered choice", transition, tid, "required_choice_id"))
					if transition.required_event_target.is_empty() and transition.automatic and transition.conditions.is_empty() and transition.required_choice_id.is_empty():
						report.append(_issue("ERROR", "STORY_UNCONDITIONAL_AUTO", "Unconditional automatic transition is unsafe", transition, tid, "automatic"))
					for condition in transition.conditions: _check_condition(condition, tid, "conditions", flags, choices, chapters, stages, report, {}, 0)
					for action in transition.actions: _check_action(action, tid, "actions", flags, choices, report)
					var execution_actions: Array[StoryAction] = []
					execution_actions.append_array(stage.on_exit_actions)
					execution_actions.append_array(transition.actions)
					var destination: StoryStageData = stages.get(String(transition.target_stage_id))
					if destination: execution_actions.append_array(destination.on_enter_actions)
					var action_ids := {}
					for action in execution_actions:
						if action == null or action.action_id.is_empty(): continue
						if action_ids.has(action.action_id): report.append(_issue("ERROR", "STORY_DUPLICATE_ACTION_RECEIPT", "Action ID repeats in one transition execution plan", action, tid, "actions"))
						else: action_ids[action.action_id] = true
	for row in report:
		if row.resource_path.is_empty(): row.resource_path = database.resource_path
	report.sort_custom(func(a: Dictionary, b: Dictionary): return a.resource_id < b.resource_id or a.resource_id == b.resource_id and a.code < b.code)
	return report

static func _check_condition(condition: StoryCondition, owner_id: String, field: String, flags: Dictionary, choices: Dictionary, chapters: Dictionary, stages: Dictionary, report: Array[Dictionary], path: Dictionary, depth: int) -> void:
	if condition == null or depth >= StoryConditionEvaluator.MAX_DEPTH:
		report.append(_issue("ERROR", "STORY_INVALID_CONDITION", "Null or over-deep condition", condition, owner_id, field)); return
	var identity := condition.get_instance_id()
	if path.has(identity): report.append(_issue("ERROR", "STORY_CONDITION_CYCLE", "Condition Resource references itself", condition, owner_id, field)); return
	path[identity] = true
	if condition is StoryAllCondition or condition is StoryAnyCondition:
		if condition.conditions.is_empty(): report.append(_issue("ERROR", "STORY_EMPTY_CONDITION", "Composite condition has no children", condition, owner_id, field))
		for child in condition.conditions: _check_condition(child, owner_id, field, flags, choices, chapters, stages, report, path, depth + 1)
	elif condition is StoryNotCondition: _check_condition(condition.condition, owner_id, field, flags, choices, chapters, stages, report, path, depth + 1)
	elif condition is StoryFlagCondition:
		var definition: StoryFlagDefinition = condition.flag_definition
		if definition == null or flags.get(String(definition.flag_id)) != definition or not _valid_flag_value(definition, condition.expected_value): report.append(_issue("ERROR", "STORY_INVALID_FLAG_CONDITION", "Flag reference or expected value invalid", condition, owner_id, field))
	elif condition is StoryStageCondition:
		if not stages.has(String(condition.stage_id)): report.append(_issue("ERROR", "STORY_UNKNOWN_STAGE", "Condition references unknown stage", condition, owner_id, field))
	elif condition is StoryChapterCondition:
		if not chapters.has(String(condition.chapter_id)): report.append(_issue("ERROR", "STORY_UNKNOWN_CHAPTER", "Condition references unknown chapter", condition, owner_id, field))
	elif condition is StoryChoiceCondition:
		var choice: StoryChoiceData = condition.choice
		if choice == null or choices.get(String(choice.choice_id)) != choice or not choice.options.any(func(o: StoryChoiceOptionData): return o != null and o.option_id == condition.option_id): report.append(_issue("ERROR", "STORY_INVALID_CHOICE_CONDITION", "Choice or option is unregistered", condition, owner_id, field))
	elif condition is StoryCutsceneCondition:
		if condition.sequence_reference == null or not condition.sequence_reference.validate().is_empty(): report.append(_issue("ERROR", "STORY_INVALID_CUTSCENE", "Cutscene Resource is missing or invalid", condition, owner_id, field))
	elif condition is StoryQuestCondition:
		if condition.quest_id.is_empty(): report.append(_issue("ERROR", "STORY_INVALID_QUEST_CONDITION", "Quest ID is empty", condition, owner_id, field))
	elif condition is StoryItemCondition:
		if condition.item == null or condition.minimum_quantity < 1: report.append(_issue("ERROR", "STORY_INVALID_ITEM_CONDITION", "Item reference or quantity is invalid", condition, owner_id, field))
	elif condition is StorySpellCondition:
		if condition.spell == null: report.append(_issue("ERROR", "STORY_INVALID_SPELL_CONDITION", "Spell reference missing", condition, owner_id, field))
	elif condition is StorySubjectCondition:
		if condition.subject_id.is_empty(): report.append(_issue("ERROR", "STORY_INVALID_SUBJECT_CONDITION", "Subject ID is empty", condition, owner_id, field))
	else: report.append(_issue("INFO", "STORY_CONDITION_UNCHECKED", "Custom condition requires runtime validation", condition, owner_id, field))
	path.erase(identity)

static func _check_action(action: StoryAction, owner_id: String, field: String, flags: Dictionary, choices: Dictionary, report: Array[Dictionary]) -> void:
	if action == null: report.append(_issue("ERROR", "STORY_NULL_ACTION", "Null action", null, owner_id, field)); return
	if action.required and not _valid_id(String(action.action_id)): report.append(_issue("ERROR", "STORY_INVALID_ACTION_ID", "Required action needs a stable ID", action, owner_id, field))
	if action is SetStoryFlagAction and (action.flag_definition == null or flags.get(String(action.flag_definition.flag_id)) != action.flag_definition or not _valid_flag_value(action.flag_definition, action.value)):
		report.append(_issue("ERROR", "STORY_INVALID_FLAG_ACTION", "Flag action target or value invalid", action, owner_id, field))
	elif action is SetStoryVariableAction and (action.variable_definition == null or flags.get(String(action.variable_definition.flag_id)) != action.variable_definition):
		report.append(_issue("ERROR", "STORY_INVALID_VARIABLE_ACTION", "Variable action target invalid", action, owner_id, field))
	elif action is SetStoryChoiceAction and (action.choice == null or choices.get(String(action.choice.choice_id)) != action.choice):
		report.append(_issue("ERROR", "STORY_INVALID_CHOICE_ACTION", "Choice action target invalid", action, owner_id, field))
	elif action is SetStoryObjectiveAction and (action.objective_id.is_empty() or action.display_text.is_empty()): report.append(_issue("ERROR", "STORY_INVALID_OBJECTIVE_ACTION", "Objective ID and text required", action, owner_id, field))
	elif action is EmitStorySignalAction and action.event_id.is_empty(): report.append(_issue("ERROR", "STORY_INVALID_SIGNAL_ACTION", "Signal ID required", action, owner_id, field))
	elif action is RequestStoryAutosaveAction and action.required: report.append(_issue("ERROR", "STORY_REQUIRED_AUTOSAVE", "Autosave cannot be a required synchronous action", action, owner_id, field))

static func _valid_id(id: String) -> bool:
	if id.is_empty() or id.length() > 128 or id != id.to_lower(): return false
	for c in id:
		if not (c >= "a" and c <= "z" or c >= "0" and c <= "9" or c in "._-"): return false
	return true

static func _valid_flag_value(definition: StoryFlagDefinition, value: Variant) -> bool:
	if definition == null: return false
	match definition.value_type:
		StoryFlagDefinition.ValueType.BOOLEAN: return value is bool
		StoryFlagDefinition.ValueType.INTEGER: return value is int and absi(value) <= 9007199254740991
		StoryFlagDefinition.ValueType.FLOAT: return value is float and is_finite(value) and absf(value) <= 1000000000000.0
		StoryFlagDefinition.ValueType.STRING: return value is String and value.length() <= 512
	return false

static func _issue(severity: String, code: String, message: String, resource: Resource, resource_id: String, field: String) -> Dictionary:
	return StoryGraphAnalyzer.issue(severity, code, message, resource, resource_id, field)
