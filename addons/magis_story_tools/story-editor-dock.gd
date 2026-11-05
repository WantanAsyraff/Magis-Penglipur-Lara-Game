@tool
extends VBoxContainer
const DATABASE_PATH := "res://data/story/definitions/story-database.tres"
var database: StoryDatabase
var graph_data: Dictionary = {}
var issues: Array[Dictionary] = []
var resources_by_id: Dictionary = {}
var search: LineEdit
var chapter_filter: OptionButton
var tree: Tree
var graph: GraphEdit
var issue_list: ItemList
var details: RichTextLabel
var open_button: Button
var selected_resource: Resource
var _cards := {}
func _ready() -> void:
	custom_minimum_size.y = 360
	_build()
	refresh()
func _build() -> void:
	var controls := HBoxContainer.new(); add_child(controls)
	search = LineEdit.new(); search.placeholder_text = "Search story ID or title"; search.size_flags_horizontal = Control.SIZE_EXPAND_FILL; search.text_changed.connect(func(_text): _rebuild_views()); controls.add_child(search)
	chapter_filter = OptionButton.new(); chapter_filter.item_selected.connect(func(_index): _rebuild_views()); controls.add_child(chapter_filter)
	var refresh_button := Button.new(); refresh_button.text = "Reload & Validate"; refresh_button.pressed.connect(refresh); controls.add_child(refresh_button)
	open_button = Button.new(); open_button.text = "Open Resource"; open_button.disabled = true; open_button.pressed.connect(_open_selected); controls.add_child(open_button)
	var split := HSplitContainer.new(); split.size_flags_vertical = Control.SIZE_EXPAND_FILL; add_child(split)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 240; split.add_child(left)
	var navigator := Label.new(); navigator.text = "Story Resources"; left.add_child(navigator)
	tree = Tree.new(); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; tree.hide_root = true; tree.item_selected.connect(_on_tree_selected); left.add_child(tree)
	var center := VBoxContainer.new(); center.size_flags_horizontal = Control.SIZE_EXPAND_FILL; split.add_child(center)
	graph = GraphEdit.new(); graph.size_flags_vertical = Control.SIZE_EXPAND_FILL; graph.zoom = 0.75; graph.node_selected.connect(_on_graph_selected); center.add_child(graph)
	var findings := Label.new(); findings.text = "Validation findings"; center.add_child(findings)
	issue_list = ItemList.new(); issue_list.custom_minimum_size.y = 110; issue_list.item_selected.connect(_on_issue_selected); center.add_child(issue_list)
	details = RichTextLabel.new(); details.custom_minimum_size.x = 290; details.selection_enabled = true; details.text = "Select a Resource or finding."; split.add_child(details)

func refresh() -> void:
	database = load(DATABASE_PATH) as StoryDatabase
	resources_by_id.clear()
	graph_data = StoryGraphAnalyzer.analyze(database)
	issues = StoryResourceValidator.validate(database)
	var selected := chapter_filter.get_item_text(chapter_filter.selected) if chapter_filter.selected >= 0 else "All chapters"
	chapter_filter.clear(); chapter_filter.add_item("All chapters")
	var chapters := {}
	for node in graph_data.nodes: chapters[node.chapter] = true
	var names: Array = chapters.keys(); names.sort()
	for name in names: chapter_filter.add_item(name)
	for i in chapter_filter.item_count:
		if chapter_filter.get_item_text(i) == selected: chapter_filter.select(i); break
	_rebuild_views()

func _rebuild_views() -> void:
	if tree == null or graph == null: return
	tree.clear()
	var root := tree.create_item()
	var query := search.text.strip_edges().to_lower()
	var chapter_name := chapter_filter.get_item_text(chapter_filter.selected) if chapter_filter.selected >= 0 else "All chapters"
	if database:
		for arc in database.arcs:
			if arc == null: continue
			var arc_item := tree.create_item(root); arc_item.set_text(0, "%s · %s" % [arc.arc_id, arc.display_name]); arc_item.set_metadata(0, arc); resources_by_id[String(arc.arc_id)] = arc
			for chapter in arc.chapters:
				if chapter == null or chapter_name != "All chapters" and String(chapter.chapter_id) != chapter_name: continue
				var chapter_item := tree.create_item(arc_item); chapter_item.set_text(0, "%s · %s" % [chapter.chapter_id, chapter.chapter_name]); chapter_item.set_metadata(0, chapter); resources_by_id[String(chapter.chapter_id)] = chapter
				for stage in chapter.stages:
					if stage == null or not query.is_empty() and query not in String(stage.stage_id).to_lower() and query not in stage.display_name.to_lower(): continue
					var stage_item := tree.create_item(chapter_item); stage_item.set_text(0, "%s · %s" % [stage.stage_id, stage.display_name]); stage_item.set_metadata(0, stage); resources_by_id[String(stage.stage_id)] = stage
					for transition in stage.transitions:
						if transition == null: continue
						var transition_item := tree.create_item(stage_item); transition_item.set_text(0, "%s → %s" % [transition.transition_id, transition.target_stage_id]); transition_item.set_metadata(0, transition); resources_by_id[String(transition.transition_id)] = transition
	_populate_graph(query, chapter_name)
	issue_list.clear()
	for finding in issues: issue_list.add_item("[%s] %s · %s" % [finding.severity, finding.code, finding.resource_id])
	if database == null: details.text = "StoryDatabase could not be loaded: " + DATABASE_PATH

func _populate_graph(query: String, chapter_name: String) -> void:
	graph.clear_connections()
	for child in graph.get_children():
		if child is GraphElement: child.free()
	_cards.clear()
	var legend := GraphNode.new(); legend.name = "GraphLegend"; legend.title = "Legend"; legend.position_offset = Vector2.ZERO
	var legend_label := Label.new(); legend_label.text = "Select a stage\nto inspect its Resource"; legend.add_child(legend_label); graph.add_child(legend)
	var column := 0
	var row := 0
	for entry in graph_data.get("nodes", []):
		if chapter_name != "All chapters" and entry.chapter != chapter_name: continue
		if not query.is_empty() and query not in String(entry.id).to_lower() and query not in String(entry.name).to_lower(): continue
		var card := GraphNode.new(); card.name = String(entry.id).replace(".", "_"); card.title = entry.name if not entry.name.is_empty() else entry.id; card.position_offset = Vector2(210 + column * 315, 70 + row * 145)
		var label := Label.new(); label.text = "%s\n%s\n%d outgoing" % [entry.id, entry.chapter, entry.outgoing]; card.add_child(label)
		card.set_slot(0, true, 0, Color.LIGHT_BLUE, true, 0, Color.LIGHT_BLUE)
		card.set_meta("story_id", entry.id); graph.add_child(card); _cards[entry.id] = card
		column += 1
		if column >= 4: column = 0; row += 1
	for edge in graph_data.get("edges", []):
		if _cards.has(edge.source) and _cards.has(edge.target): graph.connect_node(_cards[edge.source].name, 0, _cards[edge.target].name, 0)

func _on_tree_selected() -> void:
	var item := tree.get_selected()
	if item: _select_resource(item.get_metadata(0))
func _on_graph_selected(node: Node) -> void:
	if node and node.has_meta("story_id"): _select_resource(resources_by_id.get(String(node.get_meta("story_id"))))
func _on_issue_selected(index: int) -> void:
	if index < 0 or index >= issues.size(): return
	var finding := issues[index]
	details.text = "[%s] %s\n%s\n\nID: %s\nField: %s\nResource: %s\n\n%s" % [finding.severity, finding.code, finding.message, finding.resource_id, finding.field_path, finding.resource_path, finding.suggestion]
	selected_resource = resources_by_id.get(finding.resource_id, database)
	open_button.disabled = selected_resource == null
func _select_resource(resource: Resource) -> void:
	selected_resource = resource
	open_button.disabled = resource == null
	if resource == null: details.text = "Resource unavailable"; return
	details.text = "%s\n%s\n\nInspector contains the editable @export fields.\n%s" % [resource.get_script().get_global_name() if resource.get_script() else resource.get_class(), resource.resource_path, "Select Open Resource to inspect it."]
func _open_selected() -> void:
	if selected_resource != null: EditorInterface.edit_resource(selected_resource)
