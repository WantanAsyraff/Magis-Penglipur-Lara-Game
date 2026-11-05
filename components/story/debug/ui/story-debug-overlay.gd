class_name StoryDebugOverlay extends CanvasLayer
signal close_requested
@export var show_internal_identifiers := true
@export var default_graph_zoom := 0.85
var service: StoryDebugService
var tabs: TabContainer
var overview: RichTextLabel
var state_view: RichTextLabel
var events_view: RichTextLabel
var validation_view: RichTextLabel
var world_list: ItemList
var simulation_conditions: OptionButton
var simulation_value: LineEdit
var simulation_result: RichTextLabel
var _world_targets: Array[WeakRef] = []
var _sim_conditions: Array[StoryCondition] = []
var inspector: RichTextLabel
var graph: GraphEdit
var search: LineEdit
var chapter_filter: OptionButton
var _graph_nodes := {}
var _graph_built := false
var _last_graph_hash := 0
func _ready() -> void:
	if not OS.has_feature("debug"):
		queue_free(); return
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	StoryDirector.story_state_changed.connect(refresh)
	SaveManager.restored.connect(refresh)
	refresh()

func _build() -> void:
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left", 14); margin.add_theme_constant_override("margin_top", 14); margin.add_theme_constant_override("margin_right", 14); margin.add_theme_constant_override("margin_bottom", 14); add_child(margin)
	var panel := PanelContainer.new(); panel.mouse_filter = Control.MOUSE_FILTER_STOP; margin.add_child(panel)
	var vertical := VBoxContainer.new(); panel.add_child(vertical)
	var header := HBoxContainer.new(); vertical.add_child(header)
	var title := Label.new(); title.text = "STORY DEBUGGER · READ ONLY"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	var refresh_button := Button.new(); refresh_button.text = "Refresh"; refresh_button.pressed.connect(refresh); header.add_child(refresh_button)
	var close_button := Button.new(); close_button.text = "Close  F12"; close_button.pressed.connect(func(): close_requested.emit()); header.add_child(close_button)
	var splitter := HSplitContainer.new(); splitter.size_flags_vertical = Control.SIZE_EXPAND_FILL; vertical.add_child(splitter)
	tabs = TabContainer.new(); tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL; splitter.add_child(tabs)
	overview = _text_tab("Overview")
	var graph_page := VBoxContainer.new(); graph_page.name = "Graph"; tabs.add_child(graph_page)
	var filters := HBoxContainer.new(); graph_page.add_child(filters)
	search = LineEdit.new(); search.placeholder_text = "Search stage ID or title"; search.size_flags_horizontal = Control.SIZE_EXPAND_FILL; search.text_changed.connect(func(_value): _populate_graph()); filters.add_child(search)
	chapter_filter = OptionButton.new(); chapter_filter.item_selected.connect(func(_index): _populate_graph()); filters.add_child(chapter_filter)
	var active_button := Button.new(); active_button.text = "Focus active"; active_button.pressed.connect(_focus_active); filters.add_child(active_button)
	graph = GraphEdit.new(); graph.size_flags_vertical = Control.SIZE_EXPAND_FILL; graph.zoom = default_graph_zoom; graph_page.add_child(graph)
	graph.node_selected.connect(_on_graph_node_selected)
	state_view = _text_tab("State")
	var world_page := VBoxContainer.new(); world_page.name = "World"; tabs.add_child(world_page)
	var world_refresh := Button.new(); world_refresh.text = "Scan current scene"; world_refresh.pressed.connect(_scan_world); world_page.add_child(world_refresh)
	world_list = ItemList.new(); world_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; world_list.item_selected.connect(_inspect_world); world_page.add_child(world_list)
	var simulation_page := VBoxContainer.new(); simulation_page.name = "What-if"; tabs.add_child(simulation_page)
	var help := Label.new(); help.text = "SIMULATED · pure flag, stage, chapter and choice conditions only"; simulation_page.add_child(help)
	simulation_conditions = OptionButton.new(); simulation_page.add_child(simulation_conditions)
	simulation_value = LineEdit.new(); simulation_value.placeholder_text = "Hypothetical JSON value (true, 80, or \"option_id\")"; simulation_page.add_child(simulation_value)
	var preview := Button.new(); preview.text = "Preview condition"; preview.pressed.connect(_preview_condition); simulation_page.add_child(preview)
	simulation_result = RichTextLabel.new(); simulation_result.size_flags_vertical = Control.SIZE_EXPAND_FILL; simulation_page.add_child(simulation_result)
	events_view = _text_tab("Events")
	validation_view = _text_tab("Validation")
	inspector = RichTextLabel.new(); inspector.custom_minimum_size.x = 290; inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL; inspector.selection_enabled = true; inspector.text = "Select a stage, transition, or issue."; splitter.add_child(inspector)
	_splitter_ratio(splitter)

func _splitter_ratio(splitter: HSplitContainer) -> void:
	await get_tree().process_frame
	if is_instance_valid(splitter): splitter.split_offset = int(get_viewport().get_visible_rect().size.x * 0.67)

func _text_tab(title: String) -> RichTextLabel:
	var label := RichTextLabel.new(); label.name = title; label.selection_enabled = true; label.size_flags_vertical = Control.SIZE_EXPAND_FILL; label.scroll_active = true; tabs.add_child(label); return label

func refresh() -> void:
	if service == null or not is_inside_tree(): return
	var snapshot := service.get_story_snapshot()
	var stale := " [STALE: %s]" % snapshot.get("reason", "") if snapshot.get("stale", false) else ""
	overview.text = "Profile: %s%s\nArc: %s\nChapter: %s\nStage: %s\nObjective: %s\n\nOutgoing transitions:\n" % [snapshot.get("profile", "none"), stale, snapshot.get("arc", "unavailable"), snapshot.get("chapter", "unavailable"), snapshot.get("stage", "unavailable"), snapshot.get("objective", "")]
	for transition in snapshot.get("transition_diagnostics", []): overview.text += "  %s → %s  [%s] %s\n" % [transition.id, transition.target, transition.status, transition.reason]
	state_view.text = "Registered flags\n"
	var flags: Dictionary = snapshot.get("flags", {})
	var ids: Array = flags.keys(); ids.sort()
	for id in ids: state_view.text += "%s = %s  (%s%s)\n" % [id, flags[id].value, flags[id].scope, " explicit" if flags[id].recorded else " default"]
	state_view.text += "\nChoices: %s\n\nTransition receipts: %s\n\nAction receipts: %s\n\nDialogue receipts: %s\n" % [snapshot.get("choices", {}), snapshot.get("completed_transitions", []), snapshot.get("completed_actions", []), snapshot.get("completed_dialogues", [])]
	events_view.text = "In-session events only; saved receipts are shown under State.\n"
	for entry in service.get_recent_story_events(): events_view.text += "#%d  %s  %s  %s  %s\n" % [entry.sequence, entry.category, entry.source, entry.outcome, entry.explanation]
	validation_view.text = "Static Resource validation\n"
	for finding in service.get_validation_results(): validation_view.text += "[%s] %s  %s  (%s)\n" % [finding.severity, finding.code, finding.message, finding.resource_id]
	var graph_data := service.get_registered_story_graph()
	var graph_hash := hash(graph_data)
	if not _graph_built or graph_hash != _last_graph_hash:
		_last_graph_hash = graph_hash
		_rebuild_chapter_filter(graph_data)
		_populate_graph()
	_rebuild_simulation_conditions()

func _rebuild_chapter_filter(graph_data: Dictionary) -> void:
	var selected := chapter_filter.get_item_text(chapter_filter.selected) if chapter_filter.selected >= 0 else "All chapters"
	chapter_filter.clear(); chapter_filter.add_item("All chapters")
	var chapters := {}
	for node in graph_data.nodes: chapters[node.chapter] = true
	var names: Array = chapters.keys(); names.sort()
	for chapter in names: chapter_filter.add_item(chapter)
	for index in chapter_filter.item_count:
		if chapter_filter.get_item_text(index) == selected: chapter_filter.select(index); break

func _populate_graph() -> void:
	if service == null or graph == null: return
	graph.clear_connections()
	for node in graph.get_children():
		if node is GraphElement: node.free()
	_graph_nodes.clear()
	var data := service.get_registered_story_graph()
	var query := search.text.strip_edges().to_lower()
	var chapter := chapter_filter.get_item_text(chapter_filter.selected) if chapter_filter.selected >= 0 else "All chapters"
	var legend := GraphNode.new(); legend.name = "GraphLegend"; legend.title = "Legend"; legend.position_offset = Vector2.ZERO
	var legend_label := Label.new(); legend_label.text = "● Active stage\nSelect a stage to inspect"; legend.add_child(legend_label); graph.add_child(legend)
	var column := 0
	var row := 0
	for entry in data.nodes:
		if chapter != "All chapters" and entry.chapter != chapter: continue
		if not query.is_empty() and query not in String(entry.id).to_lower() and query not in String(entry.name).to_lower(): continue
		var card := GraphNode.new(); card.name = String(entry.id).replace(".", "_"); card.title = ("● " if service.director and service.director.is_ready() and String(service.director.state.stage_id) == entry.id else "") + String(entry.name); card.position_offset = Vector2(220 + column * 330, 75 + row * 160); card.resizable = false
		var label := Label.new(); label.text = "%s\n%s\n%d outgoing" % [entry.id, entry.chapter, entry.outgoing]; card.add_child(label)
		card.set_slot(0, true, 0, Color.LIGHT_BLUE, true, 0, Color.LIGHT_BLUE)
		card.set_meta("story_stage_id", entry.id)
		graph.add_child(card); _graph_nodes[entry.id] = card
		column += 1
		if column >= 4: column = 0; row += 1
	for edge in data.edges:
		if _graph_nodes.has(edge.source) and _graph_nodes.has(edge.target): graph.connect_node(_graph_nodes[edge.source].name, 0, _graph_nodes[edge.target].name, 0)
	_graph_built = true

func _on_graph_node_selected(node: Node) -> void:
	if node == null or not node.has_meta("story_stage_id"): return
	var id := StringName(node.get_meta("story_stage_id"))
	var stage: StoryStageData = service.director.registry.get_stage(id)
	if stage == null: return
	inspector.text = "%s\n%s\n\n%s\n\nTransitions:\n" % [stage.display_name, stage.stage_id, stage.objective_hint]
	for transition in service.get_transition_diagnostics(id):
		inspector.text += "\n%s → %s\nPriority: %d; %s\nStatus: %s\nReason: %s\n" % [transition.id, transition.target, transition.priority, "automatic" if transition.automatic else "manual", transition.status, transition.reason]
		for condition in transition.conditions: _append_trace(condition, 1)

func _append_trace(trace: Dictionary, depth: int) -> void:
	inspector.text += "%s[%s] %s: %s\n" % ["  ".repeat(depth), trace.get("result", "UNKNOWN"), trace.get("type", "Condition"), trace.get("reason", "")]
	for child in trace.get("children", []): _append_trace(child, depth + 1)

func _focus_active() -> void:
	if service == null or service.director == null or not service.director.is_ready(): return
	var id := String(service.director.state.stage_id)
	if not _graph_nodes.has(id):
		search.clear(); chapter_filter.select(0); _populate_graph()
	if _graph_nodes.has(id):
		await get_tree().process_frame
		if not is_instance_valid(graph) or not _graph_nodes.has(id): return
		var desired: Vector2 = _graph_nodes[id].position_offset - graph.size * 0.3
		graph.scroll_offset = Vector2(maxf(0.0, desired.x), maxf(0.0, desired.y))

func _scan_world() -> void:
	_world_targets.clear(); world_list.clear()
	var scene := get_tree().current_scene
	if scene == null:
		world_list.add_item("No active scene"); return
	var queue: Array[Node] = [scene]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		if node is StoryDialogueResolver or node is StoryPresenceComponent or node is StoryWorldStateComponent or node is StoryCutsceneTrigger or node is ElevatorPortal or node.has_method("story_unlocked"):
			_world_targets.append(weakref(node)); world_list.add_item("%s  %s" % [node.get_class(), node.get_path()])
		for child in node.get_children(): queue.append(child)
	if world_list.item_count == 0: world_list.add_item("No story-aware components in this scene")

func _inspect_world(index: int) -> void:
	if index >= _world_targets.size(): return
	var target: Node = _world_targets[index].get_ref()
	if target == null: inspector.text = "Target has left the scene"; return
	var data := service.get_dialogue_diagnostics(target) if target is StoryDialogueResolver else service.get_world_gating_diagnostics(target)
	inspector.text = "World inspection · READ ONLY\n%s\n" % str(data)

func _rebuild_simulation_conditions() -> void:
	if simulation_conditions == null or service == null or service.director == null or service.director.registry == null: return
	_sim_conditions.clear(); simulation_conditions.clear()
	var stage: StoryStageData = service.director.registry.get_stage(service.director.state.stage_id)
	if stage == null: return
	for transition in stage.transitions:
		if transition == null: continue
		for condition in transition.conditions: _add_simulation_condition(condition, String(transition.transition_id))
	if _sim_conditions.is_empty(): simulation_conditions.add_item("No conditions on active stage")

func _add_simulation_condition(condition: StoryCondition, prefix: String) -> void:
	if condition == null: return
	if condition is StoryAllCondition or condition is StoryAnyCondition:
		for child in condition.conditions: _add_simulation_condition(child, prefix)
		return
	if condition is StoryNotCondition:
		_add_simulation_condition(condition.condition, prefix); return
	var id := ""
	if condition is StoryFlagCondition and condition.flag_definition: id = String(condition.flag_definition.flag_id)
	elif condition is StoryStageCondition: id = "stage"
	elif condition is StoryChapterCondition: id = "chapter"
	elif condition is StoryChoiceCondition and condition.choice: id = String(condition.choice.choice_id)
	if id.is_empty(): return
	_sim_conditions.append(condition)
	simulation_conditions.add_item("%s · %s" % [prefix, id])

func _preview_condition() -> void:
	var index := simulation_conditions.selected
	if index < 0 or index >= _sim_conditions.size(): simulation_result.text = "No supported condition selected"; return
	var condition := _sim_conditions[index]
	var key := "stage" if condition is StoryStageCondition else "chapter" if condition is StoryChapterCondition else String(condition.flag_definition.flag_id) if condition is StoryFlagCondition else String(condition.choice.choice_id)
	var input := simulation_value.text.strip_edges()
	var value: Variant = JSON.parse_string(input)
	if value == null and input != "null": simulation_result.text = "Enter a valid JSON value"; return
	var current := service.get_condition_trace(condition)
	var simulated := service.what_if(condition, {key: value})
	simulation_result.text = "Current: %s · %s\nSIMULATED: %s · %s\nObserved: %s\nCampaign state was not changed." % [current.get("result", "UNKNOWN"), current.get("reason", ""), simulated.get("result", "UNKNOWN"), simulated.get("reason", ""), str(simulated.get("observed", "unavailable"))]
