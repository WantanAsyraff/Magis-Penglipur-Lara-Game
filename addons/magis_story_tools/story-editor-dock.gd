@tool
extends VBoxContainer
const DATABASE_PATH := "res://data/story/definitions/story-database.tres"
var database_path := DATABASE_PATH
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
var editor_plugin: EditorPlugin
var transition_list: ItemList
var status_label: Label
var delete_button: Button
var save_button: Button
var move_button: Button
var _move_menu: PopupMenu
var _positions := {}
var _selected_transition: StoryTransitionData
var _pending_delete: StoryTransitionData
var _pending_source: StoryStageData
var _delete_dialog: ConfirmationDialog
var _stage_dialog: ConfirmationDialog
var _stage_id_input: LineEdit
var _stage_chapter_choice: OptionButton
var _stage_dialog_mode := "create"
var _stage_template: StoryStageData
var _stage_picker: ConfirmationDialog
var _stage_picker_search: LineEdit
var _stage_picker_list: ItemList
var _stage_picker_mode := "to"
var _stage_picker_fixed_id := ""
var _context_menu: PopupMenu
var _context_mode := "canvas"
var _context_stage_id := ""
var _context_transition: StoryTransitionData
var _context_candidates: Array[StoryTransitionData] = []
var _context_screen_position := Vector2i.ZERO
var _context_frame := -1
var _selected_stage_id := ""
var _pending_delete_stage: StoryStageData
var _pending_delete_chapter: StoryChapterData
var _stage_delete_dialog: ConfirmationDialog
var _dependency_dialog: AcceptDialog
var _drag_active := false
var _drag_feedback := false
var interaction_diagnostics := false
enum ContextAction { ADD_STAGE, ARRANGE, FIT, REFRESH, VALIDATE, EDIT_STAGE, CONNECT_TO, CONNECT_FROM, SET_ENTRY, DUPLICATE_STAGE, COPY_STAGE_ID, DELETE_STAGE, EDIT_TRANSITION, VIEW_CONDITIONS, COPY_TRANSITION_ID, DELETE_TRANSITION, TOGGLE_DIAGNOSTICS }
func _ready() -> void:
	custom_minimum_size.y = 480
	_build()
	refresh()
func _build() -> void:
	var controls := HBoxContainer.new(); add_child(controls)
	search = LineEdit.new(); search.placeholder_text = "Search story ID or title"; search.size_flags_horizontal = Control.SIZE_EXPAND_FILL; search.text_changed.connect(func(_text): _rebuild_views()); controls.add_child(search)
	chapter_filter = OptionButton.new(); chapter_filter.item_selected.connect(func(_index): _rebuild_views()); controls.add_child(chapter_filter)
	var refresh_button := Button.new(); refresh_button.text = "Reload & Validate"; refresh_button.pressed.connect(refresh); controls.add_child(refresh_button)
	open_button = Button.new(); open_button.text = "Open Resource"; open_button.disabled = true; open_button.pressed.connect(_open_selected); controls.add_child(open_button)
	var actions_button := Button.new(); actions_button.text = "Actions"; actions_button.pressed.connect(_open_actions_menu); controls.add_child(actions_button)
	var split := HSplitContainer.new(); split.size_flags_vertical = Control.SIZE_EXPAND_FILL; add_child(split)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 200; split.add_child(left)
	var navigator := Label.new(); navigator.text = "Story Resources"; left.add_child(navigator)
	tree = Tree.new(); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; tree.hide_root = true; tree.item_selected.connect(_on_tree_selected); left.add_child(tree)
	var center := VBoxContainer.new(); center.size_flags_horizontal = Control.SIZE_EXPAND_FILL; split.add_child(center)
	graph = GraphEdit.new(); graph.custom_minimum_size.y = 220; graph.size_flags_vertical = Control.SIZE_EXPAND_FILL; graph.zoom = 0.75; graph.right_disconnects = false; graph.minimap_enabled = false; graph.show_minimap_button = false; graph.node_selected.connect(_on_graph_selected)
	graph.add_theme_constant_override("port_hotzone_inner_extent", 28)
	graph.add_theme_constant_override("port_hotzone_outer_extent", 34)
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	graph.connection_drag_started.connect(_on_drag_started)
	graph.connection_drag_ended.connect(_on_drag_ended)
	graph.connection_to_empty.connect(_on_connection_to_empty)
	graph.connection_from_empty.connect(_on_connection_from_empty)
	graph.popup_request.connect(_on_graph_popup_request)
	graph.gui_input.connect(_on_graph_gui_input)
	center.add_child(graph)
	var transition_label := Label.new(); transition_label.text = "Transitions (select to inspect)"; center.add_child(transition_label)
	var transition_row := HBoxContainer.new(); center.add_child(transition_row)
	delete_button = Button.new(); delete_button.text = "Delete Selected Transition"; delete_button.disabled = true; delete_button.pressed.connect(_request_delete_selected); transition_row.add_child(delete_button)
	save_button = Button.new(); save_button.text = "Save Transition"; save_button.disabled = true; save_button.pressed.connect(_save_selected_transition); transition_row.add_child(save_button)
	move_button = Button.new(); move_button.text = "Move Source"; move_button.disabled = true; move_button.pressed.connect(_show_move_sources); transition_row.add_child(move_button)
	_move_menu = PopupMenu.new(); _move_menu.id_pressed.connect(_move_source_selected); add_child(_move_menu)
	transition_list = ItemList.new(); transition_list.custom_minimum_size.y = 60; transition_list.item_selected.connect(_on_transition_selected); center.add_child(transition_list)
	status_label = Label.new(); status_label.text = "Drag a stage output to another stage input to add a manual transition."; center.add_child(status_label)
	var findings := Label.new(); findings.text = "Validation findings"; center.add_child(findings)
	issue_list = ItemList.new(); issue_list.custom_minimum_size.y = 75; issue_list.item_selected.connect(_on_issue_selected); center.add_child(issue_list)
	details = RichTextLabel.new(); details.custom_minimum_size.x = 240; details.selection_enabled = true; details.text = "Select a Resource or finding."; split.add_child(details)
	_delete_dialog = ConfirmationDialog.new(); _delete_dialog.title = "Delete story transition"; _delete_dialog.confirmed.connect(_confirm_delete); add_child(_delete_dialog)
	_build_context_controls()

func refresh() -> void:
	database = load(database_path) as StoryDatabase
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
	_populate_transition_list(query, chapter_name)
	issue_list.clear()
	for finding in issues: issue_list.add_item("[%s] %s · %s" % [finding.severity, finding.code, finding.resource_id])
	if database == null: details.text = "StoryDatabase could not be loaded: " + database_path

func _populate_graph(query: String, chapter_name: String) -> void:
	var view_scroll := graph.scroll_offset
	var view_zoom := graph.zoom
	for id in _cards:
		if is_instance_valid(_cards[id]): _positions[id] = _cards[id].position_offset
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
		var card := GraphNode.new(); card.name = "stage_" + str(entry.order); card.title = entry.name if not entry.name.is_empty() else entry.id; card.position_offset = _positions.get(entry.id, Vector2(210 + column * 315, 70 + row * 145))
		var label := Label.new(); label.text = "%s\n%s\n%d outgoing" % [entry.id, entry.chapter, entry.outgoing]; label.mouse_filter = Control.MOUSE_FILTER_PASS; card.add_child(label)
		card.set_slot(0, true, 0, Color.CORNFLOWER_BLUE, true, 0, Color.LIGHT_GREEN)
		card.gui_input.connect(_on_card_gui_input.bind(card))
		card.set_meta("story_id", entry.id); graph.add_child(card); _cards[entry.id] = card
		column += 1
		if column >= 4: column = 0; row += 1
	for edge in graph_data.get("edges", []):
		if _cards.has(edge.source) and _cards.has(edge.target) and not graph.is_node_connected(_cards[edge.source].name, 0, _cards[edge.target].name, 0): graph.connect_node(_cards[edge.source].name, 0, _cards[edge.target].name, 0)
	graph.zoom = view_zoom
	graph.scroll_offset = view_scroll

func _populate_transition_list(query: String, chapter_name: String) -> void:
	transition_list.clear()
	for edge in graph_data.get("edges", []):
		var source := StoryGraphAuthoring.find_stage(database, edge.source)
		if source.is_empty(): continue
		if chapter_name != "All chapters" and String(source.chapter.chapter_id) != chapter_name: continue
		if not query.is_empty() and query not in edge.source.to_lower() and query not in edge.target.to_lower() and query not in edge.id.to_lower(): continue
		for transition in source.stage.transitions:
			if transition != null and String(transition.transition_id) == edge.id:
				var index := transition_list.item_count
				transition_list.add_item("%s: %s → %s%s" % [edge.id, edge.source, edge.target, " (manual)" if not edge.automatic else " (automatic)"])
				transition_list.set_item_metadata(index, transition)
				break
	if _selected_transition != null:
		for i in transition_list.item_count:
			if transition_list.get_item_metadata(i) == _selected_transition: transition_list.select(i); break

func _on_tree_selected() -> void:
	var item := tree.get_selected()
	if item:
		var resource: Resource = item.get_metadata(0)
		if resource is StoryTransitionData: _select_transition(resource)
		else:
			_selected_stage_id = String(resource.stage_id) if resource is StoryStageData else ""
			_clear_transition_selection()
			_select_resource(resource)
			_open_selected()
func _on_graph_selected(node: Node) -> void:
	if node and node.has_meta("story_id"):
		_selected_stage_id = String(node.get_meta("story_id"))
		_clear_transition_selection()
		_select_resource(resources_by_id.get(String(node.get_meta("story_id"))))
		_open_selected()
func _clear_transition_selection() -> void:
	_selected_transition = null
	delete_button.disabled = true
	save_button.disabled = true
	move_button.disabled = true
	transition_list.deselect_all()
func _on_transition_selected(index: int) -> void:
	_selected_transition = transition_list.get_item_metadata(index) as StoryTransitionData
	delete_button.disabled = _selected_transition == null
	save_button.disabled = _selected_transition == null
	move_button.disabled = _selected_transition == null
	_select_resource(_selected_transition)
	_open_selected()
func _select_transition(transition: StoryTransitionData) -> void:
	_selected_transition = transition
	delete_button.disabled = transition == null
	save_button.disabled = transition == null
	move_button.disabled = transition == null
	_select_resource(transition)
	for i in transition_list.item_count:
		if transition_list.get_item_metadata(i) == transition: transition_list.select(i); break
	_open_selected()
func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_drag_feedback = true
	if from_port != 0 or to_port != 0:
		_status("Connection rejected: use the green output and blue input ports."); return
	var from_card := graph.get_node_or_null(NodePath(String(from_node))) as GraphNode
	var to_card := graph.get_node_or_null(NodePath(String(to_node))) as GraphNode
	if from_card == null or to_card == null or not from_card.has_meta("story_id") or not to_card.has_meta("story_id"):
		_status("Connect two story stages, not the legend."); return
	if graph.is_visible_in_tree() and (from_card.get_output_port_count() <= from_port or to_card.get_input_port_count() <= to_port):
		_status("Connection rejected: stage port unavailable. Expand the Story panel and retry."); return
	var from_slot := from_card.get_output_port_slot(from_port) if from_card.get_output_port_count() > from_port else 0
	var to_slot := to_card.get_input_port_slot(to_port) if to_card.get_input_port_count() > to_port else 0
	if not from_card.is_slot_enabled_right(from_slot) or not to_card.is_slot_enabled_left(to_slot):
		_status("The selected stage ports are disabled."); return
	if from_card.get_slot_type_right(from_slot) != to_card.get_slot_type_left(to_slot):
		_status("Connection rejected: incompatible ports."); return
	var source_id := String(from_card.get_meta("story_id"))
	var target_id := String(to_card.get_meta("story_id"))
	_create_transition(source_id, target_id)
func _create_transition(source_id: String, target_id: String) -> void:
	var reason := StoryGraphAuthoring.connection_error(database, source_id, target_id)
	if not reason.is_empty(): _status(reason); return
	var source: StoryStageData = StoryGraphAuthoring.find_stage(database, source_id).stage
	var transition := StoryTransitionData.new()
	transition.transition_id = StoryGraphAuthoring.next_id(database, source_id, target_id)
	transition.target_stage_id = StringName(target_id)
	transition.automatic = false
	var result := StoryGraphAuthoring.set_registered(database, source, transition, true)
	if result != OK: _status("Failed to save transition Resource: " + error_string(result)); return
	_record_undo("Add story transition " + String(transition.transition_id), source, transition, true)
	refresh()
	_select_transition(transition)
	_status("Saved manual transition " + String(transition.transition_id) + ". Configure it in the Inspector, then click Save Transition.")
func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_port != 0 or to_port != 0: return
	var from_card := graph.get_node_or_null(NodePath(String(from_node)))
	var to_card := graph.get_node_or_null(NodePath(String(to_node)))
	if from_card == null or to_card == null or not from_card.has_meta("story_id") or not to_card.has_meta("story_id"): return
	var source := StoryGraphAuthoring.find_stage(database, String(from_card.get_meta("story_id")))
	if source.is_empty(): return
	var matches := StoryGraphAuthoring.transitions_between(source.stage, String(to_card.get_meta("story_id")))
	if matches.size() == 1: _request_delete(source.stage, matches[0])
	elif matches.size() > 1: _status("This edge represents %d transitions. Select one in the list, then click Delete Selected Transition." % matches.size())
func _request_delete_selected() -> void:
	if _selected_transition == null: return
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage != null and _selected_transition in stage.transitions:
					_request_delete(stage, _selected_transition); return
func _request_delete(source: StoryStageData, transition: StoryTransitionData) -> void:
	_pending_source = source
	_pending_delete = transition
	_delete_dialog.dialog_text = "Delete persisted transition %s from %s to %s?" % [transition.transition_id, source.stage_id, transition.target_stage_id]
	_delete_dialog.popup_centered()
func _confirm_delete() -> void:
	if _pending_source == null or _pending_delete == null: return
	var transition := _pending_delete
	var source := _pending_source
	_pending_delete = null
	_pending_source = null
	var result := StoryGraphAuthoring.set_registered(database, source, transition, false)
	if result != OK: _status("Could not delete transition: " + error_string(result)); return
	_record_undo("Delete story transition " + String(transition.transition_id), source, transition, false)
	_selected_transition = null
	delete_button.disabled = true
	save_button.disabled = true
	move_button.disabled = true
	refresh()
	_status("Deleted transition " + String(transition.transition_id))
func _record_undo(label: String, source: StoryStageData, transition: StoryTransitionData, present: bool) -> void:
	if editor_plugin == null: return
	var undo_redo := editor_plugin.get_undo_redo()
	undo_redo.create_action(label)
	undo_redo.add_do_method(self, "_apply_undo_state", source, transition, present)
	undo_redo.add_undo_method(self, "_apply_undo_state", source, transition, not present)
	undo_redo.commit_action(false)
func _apply_undo_state(source: StoryStageData, transition: StoryTransitionData, present: bool) -> void:
	var result := StoryGraphAuthoring.set_registered(database, source, transition, present)
	if result != OK:
		_status("Undo/redo save failed: " + error_string(result)); return
	refresh()
	_status(("Restored " if present else "Removed ") + String(transition.transition_id))
func _status(message: String) -> void:
	status_label.text = message
func _save_selected_transition() -> void:
	if _selected_transition == null: return
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage == null or _selected_transition not in stage.transitions: continue
				var result := StoryGraphAuthoring.save_owner(database, stage)
				if result != OK:
					_status("Could not save transition: " + error_string(result)); return
				refresh()
				_status("Saved transition " + String(_selected_transition.transition_id)); return
	_status("Selected transition is no longer registered on a stage.")
func _show_move_sources() -> void:
	if _selected_transition == null: return
	_move_menu.clear()
	for entry in graph_data.get("nodes", []):
		_move_menu.add_item(entry.id)
	_move_menu.position = Vector2i(move_button.get_screen_position())
	_move_menu.popup()
func _move_source_selected(index: int) -> void:
	if _selected_transition == null: return
	var destination_id := _move_menu.get_item_text(index)
	var destination := StoryGraphAuthoring.find_stage(database, destination_id)
	if destination.is_empty(): _status("The selected source stage no longer exists."); return
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage == null or _selected_transition not in stage.transitions: continue
				if stage == destination.stage: _status("Transition already belongs to " + destination_id); return
				var reason := StoryGraphAuthoring.connection_error(database, destination_id, String(_selected_transition.target_stage_id))
				if not reason.is_empty(): _status(reason); return
				var transition := _selected_transition
				var result := StoryGraphAuthoring.reassign(database, stage, destination.stage, transition)
				if result != OK: _status("Could not move transition source: " + error_string(result)); return
				if editor_plugin != null:
					var history := editor_plugin.get_undo_redo()
					history.create_action("Move story transition source " + String(transition.transition_id))
					history.add_do_method(self, "_apply_source_move", stage, destination.stage, transition)
					history.add_undo_method(self, "_apply_source_move", destination.stage, stage, transition)
					history.commit_action(false)
				refresh()
				_select_transition(transition)
				_status("Moved transition source to " + destination_id); return
func _apply_source_move(old_source: StoryStageData, new_source: StoryStageData, transition: StoryTransitionData) -> void:
	var result := StoryGraphAuthoring.reassign(database, old_source, new_source, transition)
	if result != OK: _status("Could not save source move: " + error_string(result)); return
	refresh()
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

func _build_context_controls() -> void:
	_context_menu = PopupMenu.new(); _context_menu.id_pressed.connect(_on_context_action); add_child(_context_menu)
	_stage_dialog = ConfirmationDialog.new(); _stage_dialog.title = "Add story stage"; _stage_dialog.confirmed.connect(_confirm_stage_dialog); add_child(_stage_dialog)
	var stage_fields := VBoxContainer.new(); _stage_dialog.add_child(stage_fields)
	_stage_chapter_choice = OptionButton.new(); stage_fields.add_child(_stage_chapter_choice)
	_stage_id_input = LineEdit.new(); _stage_id_input.placeholder_text = "Stable stage ID, e.g. prologue.next_stage"; stage_fields.add_child(_stage_id_input)
	_stage_picker = ConfirmationDialog.new(); _stage_picker.title = "Choose a story stage"; _stage_picker.confirmed.connect(_confirm_stage_picker); add_child(_stage_picker)
	var picker_fields := VBoxContainer.new(); _stage_picker.add_child(picker_fields)
	_stage_picker_search = LineEdit.new(); _stage_picker_search.placeholder_text = "Search ID, name or chapter"; _stage_picker_search.text_changed.connect(_populate_stage_picker); picker_fields.add_child(_stage_picker_search)
	_stage_picker_list = ItemList.new(); _stage_picker_list.custom_minimum_size = Vector2(440, 260); _stage_picker_list.item_selected.connect(func(_index): _stage_picker.get_ok_button().disabled = false); picker_fields.add_child(_stage_picker_list)
	_stage_delete_dialog = ConfirmationDialog.new(); _stage_delete_dialog.title = "Delete story stage"; _stage_delete_dialog.confirmed.connect(_confirm_stage_delete); add_child(_stage_delete_dialog)
	_dependency_dialog = AcceptDialog.new(); _dependency_dialog.title = "Stage has dependencies"; add_child(_dependency_dialog)

func _on_graph_gui_input(event: InputEvent) -> void:
	if not interaction_diagnostics or not event is InputEventMouseButton or not event.pressed: return
	_diagnose_press("GraphEdit", event.position)
func _on_card_gui_input(event: InputEvent, card: GraphNode) -> void:
	if not event is InputEventMouseButton or not event.pressed: return
	var mouse := event as InputEventMouseButton
	if interaction_diagnostics: _diagnose_press(String(card.get_meta("story_id", card.name)), graph.get_global_transform().affine_inverse() * (card.get_global_transform() * mouse.position))
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		card.accept_event()
		_dispatch_context(card.get_global_transform() * mouse.position, String(card.get_meta("story_id", "")))
func _diagnose_press(origin: String, local_position: Vector2) -> void:
	var hovered := get_viewport().gui_get_hovered_control()
	var ports := []
	for id in _cards:
		var card: GraphNode = _cards[id]
		if not is_instance_valid(card) or not card.is_visible_in_tree(): continue
		for port in card.get_output_port_count():
			var point: Vector2 = graph.get_global_transform().affine_inverse() * (card.get_global_transform() * card.get_output_port_position(port))
			if point.distance_to(local_position) <= 38: ports.append("%s output %d at %.1f px" % [id, port, point.distance_to(local_position)])
		for port in card.get_input_port_count():
			var point: Vector2 = graph.get_global_transform().affine_inverse() * (card.get_global_transform() * card.get_input_port_position(port))
			if point.distance_to(local_position) <= 38: ports.append("%s input %d at %.1f px" % [id, port, point.distance_to(local_position)])
	print("STORY_GRAPH_INPUT: ", origin, " hovered=", hovered, " near=", ports, " selected=", _selected_stage_id, " drag=", _drag_active)
func _on_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	_drag_active = true; _drag_feedback = false
	if interaction_diagnostics: print("STORY_GRAPH_INPUT: drag started ", from_node, " port=", from_port, " output=", is_output)
func _on_drag_ended() -> void:
	if interaction_diagnostics: print("STORY_GRAPH_INPUT: drag ended feedback=", _drag_feedback)
	if _drag_active and not _drag_feedback: _status("Drag cancelled. Start on a green output and release on a blue input.")
	_drag_active = false
func _on_connection_to_empty(_from_node: StringName, _from_port: int, _position: Vector2) -> void:
	_drag_feedback = true; _status("Drag cancelled: release on a blue input port.")
func _on_connection_from_empty(_to_node: StringName, _to_port: int, _position: Vector2) -> void:
	_drag_feedback = true; _status("Drag cancelled: release on a green output port.")

func _on_graph_popup_request(at_position: Vector2) -> void:
	_dispatch_context(graph.get_global_transform() * at_position)
func _open_actions_menu() -> void:
	var stage_id := _selected_stage_id if not StoryGraphAuthoring.find_stage(database, _selected_stage_id).is_empty() else ""
	_context_screen_position = Vector2i(open_button.get_screen_position())
	_context_stage_id = stage_id
	_context_transition = _selected_transition
	_context_candidates.clear()
	_context_mode = "transition" if _selected_transition != null else "stage" if not stage_id.is_empty() else "canvas"
	_show_context_menu()
func _dispatch_context(viewport_position: Vector2, forced_stage_id: String = "") -> void:
	if _context_frame == Engine.get_process_frames(): return
	_context_frame = Engine.get_process_frames()
	var local: Vector2 = graph.get_global_transform().affine_inverse() * viewport_position
	_context_screen_position = Vector2i(graph.get_screen_transform() * local)
	_context_stage_id = forced_stage_id
	_context_transition = null
	_context_candidates.clear()
	_context_mode = "stage" if not forced_stage_id.is_empty() else "canvas"
	if forced_stage_id.is_empty():
		var hit: Dictionary = graph.get_closest_connection_at_point(local, 12.0)
		if not hit.is_empty():
			var from_card := graph.get_node_or_null(NodePath(String(hit.get("from_node", ""))))
			var to_card := graph.get_node_or_null(NodePath(String(hit.get("to_node", ""))))
			if from_card is GraphNode and to_card is GraphNode and from_card.has_meta("story_id") and to_card.has_meta("story_id"):
				var source := StoryGraphAuthoring.find_stage(database, String(from_card.get_meta("story_id")))
				if not source.is_empty(): _context_candidates = StoryGraphAuthoring.transitions_between(source.stage, String(to_card.get_meta("story_id")))
				if _context_candidates.size() == 1:
					_context_transition = _context_candidates[0]; _context_mode = "transition"
				elif _context_candidates.size() > 1: _context_mode = "transition_select"
	_show_context_menu()
func _show_context_menu() -> void:
	_context_menu.clear()
	match _context_mode:
		"canvas":
			_context_menu.add_item("Add New Stage...", ContextAction.ADD_STAGE)
			_context_menu.add_item("Arrange Nodes", ContextAction.ARRANGE)
			_context_menu.add_item("Fit Graph to View", ContextAction.FIT)
			_context_menu.add_item("Refresh Graph", ContextAction.REFRESH)
			_context_menu.add_item("Validate Story", ContextAction.VALIDATE)
		"stage":
			_context_menu.add_item("Edit Stage", ContextAction.EDIT_STAGE)
			_context_menu.add_item("Connect to Stage...", ContextAction.CONNECT_TO)
			_context_menu.add_item("Connect From Stage...", ContextAction.CONNECT_FROM)
			_context_menu.add_item("Set as Chapter Entry", ContextAction.SET_ENTRY)
			_context_menu.add_item("Duplicate Stage...", ContextAction.DUPLICATE_STAGE)
			_context_menu.add_item("Copy Stage ID", ContextAction.COPY_STAGE_ID)
			_context_menu.add_item("Delete Stage...", ContextAction.DELETE_STAGE)
		"transition":
			_context_menu.add_item("Edit Transition...", ContextAction.EDIT_TRANSITION)
			_context_menu.add_item("View Conditions", ContextAction.VIEW_CONDITIONS)
			_context_menu.add_item("Copy Transition ID", ContextAction.COPY_TRANSITION_ID)
			_context_menu.add_item("Delete Transition...", ContextAction.DELETE_TRANSITION)
		"transition_select":
			for i in _context_candidates.size(): _context_menu.add_item(String(_context_candidates[i].transition_id), 1000 + i)
	_context_menu.add_separator()
	_context_menu.add_check_item("Interaction diagnostics", ContextAction.TOGGLE_DIAGNOSTICS)
	_context_menu.set_item_checked(_context_menu.item_count - 1, interaction_diagnostics)
	_context_menu.popup()
	var origin := DisplayServer.window_get_position()
	var bounds := DisplayServer.window_get_size()
	_context_menu.position = Vector2i(clampi(_context_screen_position.x, origin.x, origin.x + bounds.x - _context_menu.size.x), clampi(_context_screen_position.y, origin.y, origin.y + bounds.y - _context_menu.size.y))
func _on_context_action(id: int) -> void:
	if id >= 1000:
		var index := id - 1000
		if index < _context_candidates.size():
			_context_transition = _context_candidates[index]; _context_mode = "transition"; _show_context_menu()
		return
	match id:
		ContextAction.ADD_STAGE: _show_stage_dialog(false)
		ContextAction.ARRANGE: _arrange_nodes()
		ContextAction.FIT: _fit_graph()
		ContextAction.REFRESH: refresh(); _status("Graph refreshed.")
		ContextAction.VALIDATE: refresh(); _status("Validation updated: %d findings." % issues.size())
		ContextAction.EDIT_STAGE:
			_select_resource(StoryGraphAuthoring.find_stage(database, _context_stage_id).get("stage")); _open_selected()
		ContextAction.CONNECT_TO: _show_stage_picker("to", _context_stage_id)
		ContextAction.CONNECT_FROM: _show_stage_picker("from", _context_stage_id)
		ContextAction.SET_ENTRY: _set_chapter_entry(_context_stage_id)
		ContextAction.DUPLICATE_STAGE: _show_stage_dialog(true)
		ContextAction.COPY_STAGE_ID: DisplayServer.clipboard_set(_context_stage_id); _status("Copied stage ID " + _context_stage_id)
		ContextAction.DELETE_STAGE: _request_stage_delete(_context_stage_id)
		ContextAction.EDIT_TRANSITION: _select_transition(_context_transition)
		ContextAction.VIEW_CONDITIONS:
			_select_transition(_context_transition); _status("%s has %d condition(s). Edit them in the Inspector." % [_context_transition.transition_id, _context_transition.conditions.size()])
		ContextAction.COPY_TRANSITION_ID: DisplayServer.clipboard_set(String(_context_transition.transition_id)); _status("Copied transition ID " + String(_context_transition.transition_id))
		ContextAction.DELETE_TRANSITION:
			_select_transition(_context_transition); _request_delete_selected()
		ContextAction.TOGGLE_DIAGNOSTICS: interaction_diagnostics = not interaction_diagnostics; _status("Interaction diagnostics %s (see Output)." % ("on" if interaction_diagnostics else "off"))

func _arrange_nodes() -> void:
	var index := 0
	for entry in graph_data.get("nodes", []):
		_positions[entry.id] = Vector2(210 + (index % 4) * 315, 70 + (index / 4) * 145)
		index += 1
	_rebuild_views(); _status("Nodes arranged for this editor session.")
func _fit_graph() -> void:
	if _cards.is_empty(): return
	var area := Rect2()
	var first := true
	for card in _cards.values():
		var rect := Rect2(card.position_offset, card.size)
		area = rect if first else area.merge(rect)
		first = false
	var available := graph.size - Vector2(60, 60)
	graph.zoom = clampf(minf(available.x / maxf(area.size.x, 1.0), available.y / maxf(area.size.y, 1.0)), 0.5, 1.0)
	graph.scroll_offset = area.position - Vector2(20, 20)
	_status("Graph fitted to view.")

func _show_stage_dialog(duplicate: bool) -> void:
	_stage_dialog_mode = "duplicate" if duplicate else "create"
	_stage_template = StoryGraphAuthoring.find_stage(database, _context_stage_id).get("stage") if duplicate else null
	_stage_dialog.title = "Duplicate story stage" if duplicate else "Add story stage"
	_stage_chapter_choice.clear()
	var selected_chapter := ""
	if duplicate:
		selected_chapter = String(StoryGraphAuthoring.find_stage(database, _context_stage_id).chapter.chapter_id)
	elif chapter_filter.selected > 0: selected_chapter = chapter_filter.get_item_text(chapter_filter.selected)
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			_stage_chapter_choice.add_item(String(chapter.chapter_id))
			if String(chapter.chapter_id) == selected_chapter: _stage_chapter_choice.select(_stage_chapter_choice.item_count - 1)
	_stage_id_input.text = String(_stage_template.stage_id) + ".copy" if duplicate and _stage_template != null else ""
	_stage_dialog.popup_centered(Vector2i(500, 130))
	_stage_id_input.grab_focus()
func _confirm_stage_dialog() -> void:
	if _stage_chapter_choice.selected < 0: _status("Select a chapter before adding a stage."); return
	var chapter_id := _stage_chapter_choice.get_item_text(_stage_chapter_choice.selected)
	var owner := StoryGraphAuthoring.find_chapter(database, chapter_id)
	if owner.is_empty(): _status("Selected chapter no longer exists."); return
	var id := _stage_id_input.text.strip_edges()
	var reason := StoryGraphAuthoring.stage_id_error(database, id)
	if not reason.is_empty(): _status(reason); _stage_dialog.popup_centered(); return
	var stage := StoryStageData.new(); stage.stage_id = StringName(id)
	if _stage_dialog_mode == "duplicate" and _stage_template != null:
		stage.display_name = _stage_template.display_name + " Copy"
		stage.description = _stage_template.description
		stage.objective_hint = _stage_template.objective_hint
	else: stage.display_name = id
	var result := StoryGraphAuthoring.set_stage_registered(database, owner.chapter, stage, true)
	if result != OK: _status("Failed to save stage Resource: " + error_string(result)); return
	_record_stage_undo("Add story stage " + id, owner.chapter, stage, true)
	refresh(); _select_resource(stage); _open_selected()
	_status("Saved stage %s in chapter %s. Outgoing transitions and actions are empty." % [id, chapter_id])
func _record_stage_undo(label: String, chapter: StoryChapterData, stage: StoryStageData, present: bool) -> void:
	if editor_plugin == null: return
	var history := editor_plugin.get_undo_redo()
	history.create_action(label)
	history.add_do_method(self, "_apply_stage_state", chapter, stage, present)
	history.add_undo_method(self, "_apply_stage_state", chapter, stage, not present)
	history.commit_action(false)
func _apply_stage_state(chapter: StoryChapterData, stage: StoryStageData, present: bool) -> void:
	var result := StoryGraphAuthoring.set_stage_registered(database, chapter, stage, present)
	if result != OK: _status("Could not save stage change: " + error_string(result)); return
	refresh()
func _set_chapter_entry(stage_id: String) -> void:
	var owner := StoryGraphAuthoring.find_stage(database, stage_id)
	if owner.is_empty(): _status("Stage no longer exists."); return
	var chapter: StoryChapterData = owner.chapter
	var previous := chapter.initial_stage_id
	if previous == StringName(stage_id): _status("Stage is already the chapter entry."); return
	var result := StoryGraphAuthoring.set_chapter_entry(database, chapter, StringName(stage_id))
	if result != OK: _status("Could not save chapter entry: " + error_string(result)); return
	if editor_plugin != null:
		var history := editor_plugin.get_undo_redo()
		history.create_action("Set chapter entry " + stage_id)
		history.add_do_method(self, "_apply_chapter_entry", chapter, StringName(stage_id))
		history.add_undo_method(self, "_apply_chapter_entry", chapter, previous)
		history.commit_action(false)
	refresh(); _status("Saved chapter entry " + stage_id)
func _apply_chapter_entry(chapter: StoryChapterData, id: StringName) -> void:
	var result := StoryGraphAuthoring.set_chapter_entry(database, chapter, id)
	if result != OK: _status("Could not save chapter entry: " + error_string(result)); return
	refresh()
func _request_stage_delete(stage_id: String) -> void:
	var owner := StoryGraphAuthoring.find_stage(database, stage_id)
	if owner.is_empty(): _status("Stage no longer exists."); return
	var dependencies := StoryGraphAuthoring.stage_dependencies(database, owner.stage)
	if not dependencies.is_empty():
		_dependency_dialog.dialog_text = "Cannot delete %s until these dependencies are removed:\n%s" % [stage_id, "\n".join(dependencies)]
		_dependency_dialog.popup_centered(); return
	_pending_delete_stage = owner.stage; _pending_delete_chapter = owner.chapter
	_stage_delete_dialog.dialog_text = "Delete persisted stage %s? No registered transitions depend on it." % stage_id
	_stage_delete_dialog.popup_centered()
func _confirm_stage_delete() -> void:
	if _pending_delete_stage == null or _pending_delete_chapter == null: return
	var stage := _pending_delete_stage; var chapter := _pending_delete_chapter
	_pending_delete_stage = null; _pending_delete_chapter = null
	var result := StoryGraphAuthoring.set_stage_registered(database, chapter, stage, false)
	if result != OK: _status("Failed to delete stage: " + error_string(result)); return
	_record_stage_undo("Delete story stage " + String(stage.stage_id), chapter, stage, false)
	refresh(); _status("Deleted stage " + String(stage.stage_id))

func _show_stage_picker(mode: String, fixed_id: String) -> void:
	_stage_picker_mode = mode; _stage_picker_fixed_id = fixed_id
	_stage_picker.title = "Connect to Stage" if mode == "to" else "Connect from Stage"
	_stage_picker_search.clear()
	_populate_stage_picker("")
	_stage_picker.get_ok_button().disabled = true
	_stage_picker.popup_centered(Vector2i(470, 340))
	_stage_picker_search.grab_focus()
func _populate_stage_picker(query: String) -> void:
	_stage_picker_list.clear()
	if database == null: return
	var text_query := query.strip_edges().to_lower()
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage == null or String(stage.stage_id) == _stage_picker_fixed_id: continue
				var label := "%s · %s · %s" % [stage.stage_id, chapter.chapter_id, stage.display_name]
				if not text_query.is_empty() and text_query not in label.to_lower(): continue
				var index := _stage_picker_list.item_count
				_stage_picker_list.add_item(label)
				_stage_picker_list.set_item_metadata(index, String(stage.stage_id))
	_stage_picker.get_ok_button().disabled = true
func _confirm_stage_picker() -> void:
	var selected := _stage_picker_list.get_selected_items()
	if selected.is_empty(): _status("Select a registered stage."); return
	var chosen := String(_stage_picker_list.get_item_metadata(selected[0]))
	var source_id := _stage_picker_fixed_id if _stage_picker_mode == "to" else chosen
	var target_id := chosen if _stage_picker_mode == "to" else _stage_picker_fixed_id
	_create_transition(source_id, target_id)
