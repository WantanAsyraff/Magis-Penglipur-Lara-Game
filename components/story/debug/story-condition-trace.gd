class_name StoryConditionTrace extends RefCounted
## Explains conditions without executing actions. Simulated mode uses value snapshots only.
static func runtime(condition: StoryCondition, context: StoryContext, revision: int = 0) -> Dictionary:
	return _trace(condition, context, {}, {}, false, revision, 0)

static func simulated(condition: StoryCondition, snapshot: Dictionary, overrides: Dictionary, revision: int = 0) -> Dictionary:
	return _trace(condition, null, snapshot.duplicate(true), overrides.duplicate(true), true, revision, 0)

static func _trace(condition: StoryCondition, context: StoryContext, snapshot: Dictionary, overrides: Dictionary, simulation: bool, revision: int, depth: int) -> Dictionary:
	var row := {"type": "", "label": "", "target": "", "operator": "", "expected": null, "observed": null, "result": "UNKNOWN", "reason": "", "children": [], "revision": revision, "simulated": simulation}
	if condition == null:
		row.result = "ERROR"; row.reason = "Condition Resource is missing"; return row
	row.type = condition.get_script().get_global_name() if condition.get_script() else condition.get_class()
	row.label = row.type
	if depth >= StoryConditionEvaluator.MAX_DEPTH:
		row.result = "ERROR"; row.reason = "Condition nesting limit exceeded"; return row
	if condition is StoryAllCondition or condition is StoryAnyCondition:
		var all_mode := condition is StoryAllCondition
		var children: Array[StoryCondition] = condition.conditions
		if children.is_empty(): row.result = "ERROR"; row.reason = "Composite condition is empty"; return row
		var decided := false
		var unknown := false
		for child in children:
			if decided:
				row.children.append({"type": child.get_script().get_global_name() if child and child.get_script() else "Missing", "result": "SKIPPED", "reason": "Short-circuited by an earlier child", "children": [], "revision": revision})
				continue
			var traced := _trace(child, context, snapshot, overrides, simulation, revision, depth + 1)
			row.children.append(traced)
			if traced.result in ["UNKNOWN", "ERROR"]: unknown = true
			if all_mode and traced.result == "FAIL" or not all_mode and traced.result == "PASS": decided = true
		row.result = ("FAIL" if all_mode else "PASS") if decided else ("UNKNOWN" if unknown else ("PASS" if all_mode else "FAIL"))
		row.reason = "All children required" if all_mode else "Any child may satisfy"
		return row
	if condition is StoryNotCondition:
		var child_trace := _trace(condition.condition, context, snapshot, overrides, simulation, revision, depth + 1)
		row.children.append(child_trace)
		row.result = "FAIL" if child_trace.result == "PASS" else ("PASS" if child_trace.result == "FAIL" else child_trace.result)
		row.reason = "Negates one child condition"
		return row
	if simulation:
		return _simulate_leaf(condition, snapshot, overrides, row)
	if context == null or context.registry == null or context.state.lifecycle != StoryState.Lifecycle.READY:
		row.reason = "Story context unavailable"; return row
	if not StoryConditionEvaluator.validate_graph(condition, context.registry):
		row.result = "ERROR"; row.reason = "Condition validation failed"; return row
	if condition is StoryFlagCondition:
		row.target = String(condition.flag_definition.flag_id)
		row.operator = StoryFlagCondition.Comparison.keys()[condition.comparison]
		row.expected = condition.expected_value
		row.observed = context.flag_value(condition.flag_definition.flag_id)
		if condition.flag_definition.scope == StoryFlagDefinition.Scope.CAMPAIGN and not QuestManager.world_flags.has(row.target): row.reason = "No explicit world flag; using authored default"
	elif condition is StoryStageCondition:
		row.target = String(condition.stage_id); row.observed = String(context.stage_id()); row.expected = row.target if condition.equal else "not " + row.target
	elif condition is StoryChapterCondition:
		row.target = String(condition.chapter_id); row.observed = String(context.chapter_id()); row.expected = row.target if condition.equal else "not " + row.target
	elif condition is StoryQuestCondition:
		row.target = condition.quest_id; row.expected = StoryQuestCondition.RequiredStatus.keys()[condition.required_status]; row.observed = context.quest_status(condition.quest_id)
	elif condition is StoryCutsceneCondition:
		row.target = condition.sequence_reference.sequence_id; row.expected = condition.must_be_completed; row.observed = context.is_cutscene_complete(condition.sequence_reference)
	elif condition is StoryChoiceCondition:
		row.target = String(condition.choice.choice_id); row.expected = String(condition.option_id); row.observed = String(context.state.choices.get(condition.choice.choice_id, &""))
	elif condition is StoryItemCondition:
		row.target = condition.item.item_id; row.expected = condition.minimum_quantity; row.observed = Inventory_Manager.get_item_quantity(condition.item.item_id)
	elif condition is StorySpellCondition:
		row.target = condition.spell.spell_id; row.expected = condition.must_be_learned; row.observed = Player_Global_Data.has_spell(condition.spell)
	elif condition is StorySubjectCondition:
		row.target = condition.subject_id; row.expected = condition.must_be_completed; row.observed = Player_Global_Data.has_completed_subject(condition.subject_id)
	row.result = "PASS" if StoryConditionEvaluator.evaluate(condition, context) else "FAIL"
	if row.reason.is_empty(): row.reason = "Requirement satisfied" if row.result == "PASS" else "Requirement not satisfied"
	return row

static func _simulate_leaf(condition: StoryCondition, snapshot: Dictionary, overrides: Dictionary, row: Dictionary) -> Dictionary:
	if condition is StoryFlagCondition:
		if condition.flag_definition == null:
			row.result = "ERROR"; row.reason = "Missing flag definition"; return row
		var id := String(condition.flag_definition.flag_id)
		var flags: Dictionary = snapshot.get("flags", {})
		if not flags.has(id): row.reason = "Flag absent from diagnostic snapshot"; return row
		var value: Variant = overrides.get(id, flags[id].get("value"))
		if not condition.flag_definition.valid_value(value): row.result = "ERROR"; row.reason = "Hypothetical value has wrong type"; return row
		row.target = id; row.observed = value; row.expected = condition.expected_value; row.operator = StoryFlagCondition.Comparison.keys()[condition.comparison]
		var passed := false
		match condition.comparison:
			StoryFlagCondition.Comparison.EQUAL: passed = value == condition.expected_value
			StoryFlagCondition.Comparison.NOT_EQUAL: passed = value != condition.expected_value
			StoryFlagCondition.Comparison.GREATER: passed = value > condition.expected_value
			StoryFlagCondition.Comparison.LESS: passed = value < condition.expected_value
		row.result = "PASS" if passed else "FAIL"; row.reason = "SIMULATED flag comparison"; return row
	if condition is StoryStageCondition or condition is StoryChapterCondition:
		var field := "stage" if condition is StoryStageCondition else "chapter"
		row.target = String(condition.stage_id) if condition is StoryStageCondition else String(condition.chapter_id)
		row.observed = String(overrides.get(field, snapshot.get(field, "")))
		var equal: bool = condition.equal
		row.result = "PASS" if (row.observed == row.target) == equal else "FAIL"
		row.reason = "SIMULATED narrative position"; return row
	if condition is StoryChoiceCondition:
		if condition.choice == null: row.result = "ERROR"; row.reason = "Missing choice"; return row
		row.target = String(condition.choice.choice_id)
		row.observed = String(overrides.get(row.target, snapshot.get("choices", {}).get(row.target, "")))
		row.expected = String(condition.option_id)
		row.result = "PASS" if row.observed == row.expected else "FAIL"
		row.reason = "SIMULATED confirmed choice"; return row
	row.reason = "Condition depends on live gameplay data; simulation unsupported"
	return row
