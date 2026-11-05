@tool
class_name StoryGraphAnalyzer extends RefCounted
## Pure analysis of authored Resources. Never instantiates gameplay services.
static func issue(severity: String, code: String, message: String, resource: Resource = null, resource_id: String = "", field: String = "", suggestion: String = "") -> Dictionary:
	return {"severity": severity, "code": code, "message": message, "resource_path": resource.resource_path if resource else "", "resource_id": resource_id, "field_path": field, "suggestion": suggestion}

static func analyze(database: StoryDatabase) -> Dictionary:
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var issues: Array[Dictionary] = []
	if database == null:
		issues.append(issue("ERROR", "STORY_DATABASE_MISSING", "StoryDatabase is missing"))
		return {"nodes": nodes, "edges": edges, "issues": issues}
	var by_id := {}
	var roots: Array[String] = []
	for arc in database.arcs:
		if arc == null:
			issues.append(issue("ERROR", "STORY_NULL_ARC", "Null arc in database", database, "", "arcs"))
			continue
		var arc_id := String(arc.arc_id)
		var entry_chapter: StoryChapterData
		for chapter in arc.chapters:
			if chapter == null:
				issues.append(issue("ERROR", "STORY_NULL_CHAPTER", "Null chapter", arc, arc_id, "chapters"))
				continue
			var chapter_id := String(chapter.chapter_id)
			if chapter.chapter_id == arc.initial_chapter_id: entry_chapter = chapter
			for stage in chapter.stages:
				if stage == null:
					issues.append(issue("ERROR", "STORY_NULL_STAGE", "Null stage", chapter, chapter_id, "stages"))
					continue
				var sid := String(stage.stage_id)
				if sid.is_empty() or by_id.has(sid):
					issues.append(issue("ERROR", "STORY_DUPLICATE_STAGE", "Missing or duplicate stage ID: " + sid, stage, sid, "stage_id", "Assign a unique stable ID"))
					continue
				by_id[sid] = stage
				nodes.append({"id": sid, "name": stage.display_name, "chapter": chapter_id, "arc": arc_id, "resource_path": stage.resource_path, "outgoing": 0, "entry": stage.stage_id == chapter.initial_stage_id, "order": nodes.size()})
			if chapter.stages.is_empty() or not chapter.stages.any(func(s: StoryStageData): return s != null and s.stage_id == chapter.initial_stage_id):
				issues.append(issue("ERROR", "STORY_MISSING_ENTRY_STAGE", "Initial stage is not in chapter", chapter, chapter_id, "initial_stage_id"))
		if entry_chapter == null:
			issues.append(issue("ERROR", "STORY_MISSING_ENTRY_CHAPTER", "Initial chapter is not in arc", arc, arc_id, "initial_chapter_id"))
		else: roots.append(String(entry_chapter.initial_stage_id))
	for node in nodes:
		var stage: StoryStageData = by_id[node.id]
		for transition in stage.transitions:
			if transition == null:
				issues.append(issue("ERROR", "STORY_NULL_TRANSITION", "Null transition", stage, node.id, "transitions"))
				continue
			var target := String(transition.target_stage_id)
			var tid := String(transition.transition_id)
			edges.append({"id": tid, "source": node.id, "target": target, "priority": transition.priority, "automatic": transition.automatic, "event": transition.required_event_target, "choice": String(transition.required_choice_id), "conditions": transition.conditions.size(), "resource_path": transition.resource_path})
			if not by_id.has(target): issues.append(issue("ERROR", "STORY_MISSING_TARGET", "Transition target does not exist: " + target, transition, tid, "target_stage_id"))
			if target == node.id: issues.append(issue("INFO", "STORY_SELF_TRANSITION", "Stage transitions to itself", transition, tid, "target_stage_id"))
		if stage.transitions.is_empty(): issues.append(issue("INFO", "STORY_DEAD_END", "Stage has no outgoing transition", stage, node.id, "transitions", "Confirm this is an intended terminal stage"))
		node.outgoing = stage.transitions.size()
	var reachable := {}
	var queue := roots.duplicate()
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if reachable.has(current) or not by_id.has(current): continue
		reachable[current] = true
		for edge in edges:
			if edge.source == current and by_id.has(edge.target): queue.append(edge.target)
	for node in nodes:
		if not reachable.has(node.id): issues.append(issue("WARNING", "STORY_STRUCTURALLY_UNREACHABLE", "No authored path from an arc entry to this stage", by_id[node.id], node.id, "stage_id", "Add a transition or document a migration-only stage"))
	var adjacency := {}
	for node in nodes: adjacency[node.id] = []
	for edge in edges:
		if adjacency.has(edge.source) and adjacency.has(edge.target): adjacency[edge.source].append(edge.target)
	var tarjan := {"index": 0, "indices": {}, "low": {}, "stack": [], "on_stack": {}, "components": []}
	for node in nodes:
		if not tarjan.indices.has(node.id): _strong_connect(node.id, adjacency, tarjan)
	for component in tarjan.components:
		var cyclic: bool = component.size() > 1 or (component.size() == 1 and component[0] in adjacency[component[0]])
		if not cyclic: continue
		var inside: Array[Dictionary] = []
		for edge in edges:
			if edge.source in component and edge.target in component: inside.append(edge)
		if inside.all(func(e: Dictionary): return e.automatic and e.event.is_empty() and e.choice.is_empty()):
			issues.append(issue("WARNING", "STORY_POSSIBLE_AUTO_LOOP", "Automatic cycle may repeatedly process: " + ", ".join(component), by_id[component[0]], component[0], "transitions", "Require a current-stage event or an explicit choice on at least one edge"))
	nodes.sort_custom(func(a: Dictionary, b: Dictionary): return a.order < b.order)
	edges.sort_custom(func(a: Dictionary, b: Dictionary): return a.source < b.source or a.source == b.source and a.id < b.id)
	issues.sort_custom(func(a: Dictionary, b: Dictionary): return a.resource_id < b.resource_id or a.resource_id == b.resource_id and a.code < b.code)
	return {"nodes": nodes, "edges": edges, "issues": issues}

static func _strong_connect(id: String, adjacency: Dictionary, state: Dictionary) -> void:
	state.indices[id] = state.index
	state.low[id] = state.index
	state.index += 1
	state.stack.append(id)
	state.on_stack[id] = true
	for target in adjacency[id]:
		if not state.indices.has(target):
			_strong_connect(target, adjacency, state)
			state.low[id] = mini(state.low[id], state.low[target])
		elif state.on_stack.has(target): state.low[id] = mini(state.low[id], state.indices[target])
	if state.low[id] == state.indices[id]:
		var component: Array[String] = []
		while not state.stack.is_empty():
			var member: String = state.stack.pop_back()
			state.on_stack.erase(member)
			component.append(member)
			if member == id: break
		component.sort()
		state.components.append(component)
