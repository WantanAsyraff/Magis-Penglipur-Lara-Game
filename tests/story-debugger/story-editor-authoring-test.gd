@tool
extends RefCounted

const FIXTURE_PATH := "res://.godot/story-graph-authoring-fixture.tres"
const MOUSE_TARGET_PATH := "res://.godot/story-os-mouse-target.json"
static var checks := 0
static var failures := 0

static func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STORY_AUTHORING_TEST: " + message)

static func setup() -> void:
	var database := StoryDatabase.new()
	var arc := StoryArcData.new(); arc.arc_id = &"test.arc"; arc.initial_chapter_id = &"test.chapter"
	var chapter := StoryChapterData.new(); chapter.chapter_id = &"test.chapter"; chapter.initial_stage_id = &"test.a"
	for id in ["test.a", "test.b", "test.c"]:
		var stage := StoryStageData.new(); stage.stage_id = StringName(id); stage.display_name = id
		chapter.stages.append(stage)
	arc.chapters.append(chapter)
	database.arcs.append(arc)
	check(ResourceSaver.save(database, FIXTURE_PATH) == OK, "fixture saved")

static func run_create(plugin: EditorPlugin, dock: Control) -> int:
	var database: StoryDatabase = dock.database
	check(database != null and dock.graph_data.nodes.size() == 3, "isolated graph loaded")
	check(dock.graph.connection_request.get_connections().size() == 1, "one connection subscription")
	check(dock.graph.disconnection_request.get_connections().size() == 1, "one disconnection subscription")
	var a: GraphNode = dock._cards["test.a"]
	var b: GraphNode = dock._cards["test.b"]
	check(a.get_child_count() == 1 and a.is_slot_enabled_left(0) and a.is_slot_enabled_right(0), "stage slots configured")
	check(a.get_slot_type_left(0) == b.get_slot_type_right(0), "compatible port types")
	dock._on_graph_selected(a)
	check(dock.selected_resource == StoryGraphAuthoring.find_stage(dock.database, "test.a").stage, "stage selection opens real Resource")
	var initial_unreachable := _count(dock.issues, "STORY_STRUCTURALLY_UNREACHABLE")
	dock.graph.connection_request.emit(a.name, 0, b.name, 0)
	var source := StoryGraphAuthoring.find_stage(dock.database, "test.a").stage as StoryStageData
	check(source.transitions.size() == 1, "transition registered on source stage")
	var ab: StoryTransitionData = source.transitions[0] if source.transitions.size() == 1 else null
	check(ab != null and ab.transition_id != &"" and ab.target_stage_id == &"test.b" and not ab.automatic, "stable manual transition created")
	check(dock.graph.is_node_connected(dock._cards["test.a"].name, 0, dock._cards["test.b"].name, 0), "edge shown after refresh")
	check(dock.selected_resource == ab, "new transition opened in Inspector")
	dock._cards["test.a"].position_offset = Vector2(333, 144)
	dock.graph.zoom = 0.8
	dock.graph.scroll_offset = Vector2(20, 15)
	dock.refresh()
	check(dock._cards["test.a"].position_offset == Vector2(333, 144), "node position survives refresh")
	check(dock.graph.scroll_offset == Vector2(20, 15) and is_equal_approx(dock.graph.zoom, 0.8), "pan and zoom survive refresh")
	check(_count(dock.issues, "STORY_STRUCTURALLY_UNREACHABLE") == initial_unreachable - 1, "reachability refreshed")
	check(_count(dock.issues, "STORY_DEAD_END") == 2, "dead ends refreshed")
	dock.graph.connection_request.emit(dock._cards["test.a"].name, 0, dock._cards["test.b"].name, 0)
	check(source.transitions.size() == 1, "duplicate pair rejected")
	check(StoryGraphAuthoring.connection_error(dock.database, "test.a", "missing") != "", "invalid target rejected")
	check(StoryGraphAuthoring.connection_error(dock.database, "test.a", "test.a") != "", "self-loop policy enforced")
	dock.graph.connection_request.emit(dock._cards["test.a"].name, 0, dock._cards["test.c"].name, 0)
	dock.graph.connection_request.emit(dock._cards["test.c"].name, 0, dock._cards["test.b"].name, 0)
	var ac: StoryTransitionData = StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions[1]
	ac.priority = 7
	ac.required_event_target = "test.trigger"
	dock._select_transition(ac)
	dock._save_selected_transition()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 2, "multiple outgoing paths")
	check(StoryGraphAuthoring.find_stage(dock.database, "test.c").stage.transitions.size() == 1, "multiple incoming paths")
	dock._show_move_sources()
	dock._move_source_selected(1)
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.has(ac), "source reassignment registered")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.has(ac), "undo source reassignment")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.has(ac), "redo source reassignment")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	var alternate := StoryTransitionData.new(); alternate.transition_id = &"test.ac.alternative"; alternate.target_stage_id = &"test.c"; alternate.automatic = false
	check(StoryGraphAuthoring.set_registered(dock.database, StoryGraphAuthoring.find_stage(dock.database, "test.a").stage, alternate, true) == OK, "parallel transition registered")
	dock.refresh()
	check(dock.transition_list.item_count == 4 and dock.graph.is_node_connected(dock._cards["test.a"].name, 0, dock._cards["test.c"].name, 0), "parallel Resources listed behind one edge")
	dock._on_disconnection_request(dock._cards["test.a"].name, 0, dock._cards["test.c"].name, 0)
	check(dock._pending_delete == null, "ambiguous graph disconnect does not delete")
	dock._select_transition(alternate)
	dock._request_delete_selected()
	dock._confirm_delete()
	dock._delete_dialog.hide()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.has(ac) and not StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.has(alternate), "selected parallel transition removed alone")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.has(alternate), "undo exact deletion")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.has(alternate), "redo exact deletion")
	var saved: StoryDatabase = ResourceLoader.load(FIXTURE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(saved != null and StoryGraphAuthoring.find_stage(saved, "test.a").stage.transitions.size() == 2, "disk contains transitions")
	check(StoryGraphAuthoring.find_stage(saved, "test.a").stage.transitions[1].priority == 7, "Inspector configuration saved")
	dock._on_disconnection_request(dock._cards["test.a"].name, 0, dock._cards["test.b"].name, 0)
	check(dock._pending_delete == ab, "disconnection identifies exact Resource")
	dock._confirm_delete()
	dock._delete_dialog.hide()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1, "disconnect persisted")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 2, "undo restores transition")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1, "redo removes transition")
	dock._show_stage_dialog(false)
	dock._stage_id_input.text = "test.d"
	dock._confirm_stage_dialog()
	dock._stage_dialog.hide()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "canvas action registers new stage")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "undo stage creation")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "redo stage creation")
	dock._request_stage_delete("test.a")
	check(dock._pending_delete_stage == null and "Outgoing transition" in dock._dependency_dialog.dialog_text, "stage deletion reports dependencies")
	dock._dependency_dialog.hide()
	dock._request_stage_delete("test.d")
	check(dock._pending_delete_stage != null, "unlinked stage requires confirmation")
	dock._confirm_stage_delete()
	dock._stage_delete_dialog.hide()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "confirmed stage deletion saved")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "undo stage deletion")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.d").is_empty(), "remove temporary stage fixture")
	dock._set_chapter_entry("test.b")
	check(StoryGraphAuthoring.find_chapter(dock.database, "test.chapter").chapter.initial_stage_id == &"test.b", "chapter entry saved")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_chapter(dock.database, "test.chapter").chapter.initial_stage_id == &"test.a", "undo chapter entry")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(StoryGraphAuthoring.find_chapter(dock.database, "test.chapter").chapter.initial_stage_id == &"test.b", "redo chapter entry")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	dock._context_stage_id = "test.a"
	dock._show_stage_dialog(true)
	dock._confirm_stage_dialog()
	dock._stage_dialog.hide()
	var copy := StoryGraphAuthoring.find_stage(dock.database, "test.a.copy")
	check(not copy.is_empty() and copy.stage.transitions.is_empty() and copy.stage.on_enter_actions.is_empty(), "duplicate stage omits outgoing transition and actions")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	dock._show_stage_picker("to", "test.b")
	for i in dock._stage_picker_list.item_count:
		if dock._stage_picker_list.get_item_metadata(i) == "test.c": dock._stage_picker_list.select(i); break
	dock._confirm_stage_picker()
	dock._stage_picker.hide()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.size() == 1, "menu fallback uses transition authoring service")
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions[0].automatic, "menu fallback defaults manual")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.is_empty(), "undo menu transition")
	dock._show_stage_picker("from", "test.c")
	for i in dock._stage_picker_list.item_count:
		if dock._stage_picker_list.get_item_metadata(i) == "test.b": dock._stage_picker_list.select(i); break
	dock._confirm_stage_picker()
	dock._stage_picker.hide()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.size() == 1, "Connect From Stage chooses source")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.b").stage.transitions.is_empty(), "undo Connect From Stage")
	dock._tree_context_resource = null
	dock._show_tree_menu(Vector2i(20, 20))
	check(dock._tree_menu.get_item_text(0) == "New Story...", "empty resource panel offers new story")
	dock._tree_menu.hide()
	dock._tree_context_resource = dock.database.arcs[0]
	dock._show_tree_menu(Vector2i(20, 20))
	check(dock._tree_menu.get_item_text(1) == "Add Chapter...", "story arc offers chapter creation")
	dock._tree_menu.hide()
	dock._show_story_dialog("arc")
	dock._story_arc_id.text = "test.side"
	dock._story_arc_name.text = "Side Story"
	dock._story_chapter_id.text = "test.side.chapter"
	dock._story_chapter_name.text = "First Chapter"
	dock._story_stage_id.text = "test.side.start"
	dock._story_stage_name.text = "Start"
	dock._confirm_story_dialog()
	dock._story_dialog.hide()
	var side := StoryGraphAuthoring.find_stage(dock.database, "test.side.start")
	check(not side.is_empty() and side.arc.arc_id == &"test.side" and side.arc.initial_chapter_id == &"test.side.chapter" and side.chapter.initial_stage_id == &"test.side.start", "new story registers arc, chapter and entry stage")
	var story_disk: StoryDatabase = ResourceLoader.load(FIXTURE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	check(not StoryGraphAuthoring.find_stage(story_disk, "test.side.start").is_empty(), "new story persisted to disk")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.side.start").is_empty(), "undo new story")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.side.start").is_empty(), "redo new story")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	dock._tree_context_resource = dock.database.arcs[0]
	dock._show_story_dialog("chapter")
	dock._story_chapter_id.text = "test.chapter_2"
	dock._story_chapter_name.text = "Second Chapter"
	dock._story_stage_id.text = "test.chapter_2.start"
	dock._confirm_story_dialog()
	dock._story_dialog.hide()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.chapter_2.start").is_empty(), "arc menu adds chapter with entry stage")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.chapter_2.start").is_empty(), "undo chapter creation")
	plugin.get_undo_redo().get_history_undo_redo(0).redo()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.chapter_2.start").is_empty(), "redo chapter creation")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	dock._tree_context_resource = dock.database.arcs[0].chapters[0]
	dock._on_tree_action(2)
	check(dock._stage_chapter_choice.get_item_text(dock._stage_chapter_choice.selected) == "test.chapter", "chapter right-click preselects owning chapter")
	dock._stage_id_input.text = "test.tree_stage"
	dock._confirm_stage_dialog()
	dock._stage_dialog.hide()
	check(not StoryGraphAuthoring.find_stage(dock.database, "test.tree_stage").is_empty(), "chapter menu creates registered stage")
	plugin.get_undo_redo().get_history_undo_redo(0).undo()
	check(StoryGraphAuthoring.find_stage(dock.database, "test.tree_stage").is_empty(), "undo tree stage creation")
	var failure_db := StoryDatabase.new()
	failure_db.resource_path = "res://.godot/nonexistent-story-test-dir/failure.tres"
	var failure_stage := StoryStageData.new(); failure_stage.stage_id = &"failure.a"
	var failure_transition := StoryTransitionData.new(); failure_transition.transition_id = &"failure.ab"; failure_transition.target_stage_id = &"failure.b"
	check(StoryGraphAuthoring.set_registered(failure_db, failure_stage, failure_transition, true) != OK and failure_stage.transitions.is_empty(), "save failure rolls back")
	check(not FileAccess.file_exists("res://.godot/nonexistent-story-test-dir/failure.tres"), "failed save leaves no file")
	check(StoryResourceValidator.validate(dock.database).size() == dock.issues.size(), "validation counters refreshed")
	print("STORY_AUTHORING_TEST CREATE: %d checks, %d failures" % [checks, failures])
	return failures

static func run_reopen(dock: Control) -> int:
	var source := StoryGraphAuthoring.find_stage(dock.database, "test.a")
	check(not source.is_empty() and source.stage.transitions.size() == 1, "project reopen retains authored transition")
	check(source.stage.transitions[0].priority == 7 and source.stage.transitions[0].required_event_target == "test.trigger", "project reopen retains trigger configuration")
	check(dock.graph.is_node_connected(dock._cards["test.a"].name, 0, dock._cards["test.c"].name, 0), "project reopen reconstructs graph")
	check(dock.transition_list.item_count == 2, "transition list reconstructs distinct edges")
	check(dock.graph.connection_request.get_connections().size() == 1, "plugin reload has one signal subscription")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH)) == OK, "fixture cleaned")
	print("STORY_AUTHORING_TEST REOPEN: %d checks, %d failures" % [checks, failures])
	return failures

static func run_gui(plugin: EditorPlugin, dock: Control) -> int:
	print("STORY_GUI_BACKEND: ", DisplayServer.get_name())
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
		plugin.get_tree().root.size = resolution
		plugin.make_bottom_panel_item_visible(dock)
		await plugin.get_tree().create_timer(0.5).timeout
		dock.graph.scroll_offset = Vector2.ZERO
		await plugin.get_tree().process_frame
		var a: GraphNode = dock._cards["test.a"]
		var b: GraphNode = dock._cards["test.b"]
		check(dock.graph.is_visible_in_tree(), "graph visible at %s" % resolution)
		var arc_item: TreeItem = dock.tree.get_root().get_first_child()
		var chapter_item: TreeItem = arc_item.get_first_child()
		var stage_item: TreeItem = chapter_item.get_first_child()
		await _right_click(plugin, dock.tree.get_global_transform() * dock.tree.get_item_area_rect(arc_item, 0).get_center())
		check(dock._tree_menu.visible and dock._tree_context_resource is StoryArcData, "resource tree arc right-click at %s" % resolution)
		dock._tree_menu.hide()
		await _right_click(plugin, dock.tree.get_global_transform() * dock.tree.get_item_area_rect(chapter_item, 0).get_center())
		check(dock._tree_menu.visible and dock._tree_context_resource is StoryChapterData, "resource tree chapter right-click at %s" % resolution)
		dock._tree_menu.hide()
		await _right_click(plugin, dock.tree.get_global_transform() * dock.tree.get_item_area_rect(stage_item, 0).get_center())
		check(dock._tree_menu.visible and dock._tree_context_resource is StoryStageData, "resource tree stage right-click at %s" % resolution)
		dock._tree_menu.hide()
		await _right_click(plugin, dock.tree.get_global_rect().position + Vector2(20, dock.tree.size.y - 15))
		check(dock._tree_menu.visible and dock._tree_context_resource == null, "resource tree empty-space right-click at %s" % resolution)
		dock._tree_menu.hide()
		print("STORY_GUI_SIZE: requested=", resolution, " actual=", DisplayServer.window_get_size(), " viewport=", plugin.get_tree().root.size)
		check(a.get_output_port_count() == 1 and b.get_input_port_count() == 1, "rendered ports at %s" % resolution)
		check(dock.graph.get_theme_constant("port_hotzone_inner_extent") >= 28 and not dock.graph.minimap_enabled, "expanded hotzones and minimap off")
		await _right_click(plugin, dock.graph.get_global_rect().position + Vector2(20, dock.graph.size.y - 20))
		check(dock._context_mode == "canvas" and dock._context_menu.visible, "right-click empty canvas")
		dock._context_menu.hide()
		await _right_click(plugin, a.get_global_rect().position + Vector2(20, 10))
		check(dock._context_mode == "stage" and dock._context_stage_id == "test.a", "right-click stage title")
		dock._context_menu.hide()
		dock._on_context_action(6)
		check(dock._stage_picker.visible, "context Connect to Stage opens picker")
		dock._populate_stage_picker("test.b")
		check(dock._stage_picker_list.item_count == 1 and "test.b" in dock._stage_picker_list.get_item_text(0), "destination search filters by stable ID")
		dock._stage_picker_list.select(0)
		dock._confirm_stage_picker()
		dock._stage_picker.hide()
		check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1, "context Connect to Stage persists transition")
		dock._on_disconnection_request(dock._cards["test.a"].name, 0, dock._cards["test.b"].name, 0)
		dock._confirm_delete()
		dock._delete_dialog.hide()
		await plugin.get_tree().process_frame
		a = dock._cards["test.a"]; b = dock._cards["test.b"]
		await _right_click(plugin, a.get_global_rect().position + Vector2(20, 48))
		check(dock._context_mode == "stage" and dock._context_stage_id == "test.a", "right-click stage content")
		dock._context_menu.hide()
		for zoom_value in [0.5, 0.75, 1.0]:
			dock.graph.zoom = zoom_value
			dock.graph.scroll_offset = Vector2(120 if zoom_value == 1.0 else 70, 15)
			await plugin.get_tree().process_frame
			var out_point: Vector2 = a.get_global_transform() * a.get_output_port_position(0)
			var in_point: Vector2 = b.get_global_transform() * b.get_input_port_position(0)
			check(dock.graph.get_global_rect().has_point(out_point) and dock.graph.get_global_rect().has_point(in_point), "ports reachable at zoom %.2f, %s" % [zoom_value, resolution])
		dock.graph.zoom = 0.75
		dock.graph.scroll_offset = Vector2.ZERO
		await plugin.get_tree().process_frame
		var cancel_start: Vector2 = a.get_global_transform() * a.get_output_port_position(0)
		var empty_point: Vector2 = dock.graph.get_global_rect().position + Vector2(25, dock.graph.size.y - 20)
		var cancel_hover := InputEventMouseMotion.new(); cancel_hover.position = cancel_start; cancel_hover.global_position = cancel_start
		plugin.get_tree().root.push_input(cancel_hover, true)
		await plugin.get_tree().process_frame
		var cancel_press := InputEventMouseButton.new(); cancel_press.position = cancel_start; cancel_press.global_position = cancel_start; cancel_press.button_index = MOUSE_BUTTON_LEFT; cancel_press.pressed = true
		plugin.get_tree().root.push_input(cancel_press, true)
		await plugin.get_tree().process_frame
		var cancel_motion := InputEventMouseMotion.new(); cancel_motion.position = empty_point; cancel_motion.global_position = empty_point; cancel_motion.relative = empty_point - cancel_start; cancel_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		plugin.get_tree().root.push_input(cancel_motion, true)
		await plugin.get_tree().process_frame
		var cancel_release := InputEventMouseButton.new(); cancel_release.position = empty_point; cancel_release.global_position = empty_point; cancel_release.button_index = MOUSE_BUTTON_LEFT; cancel_release.pressed = false
		plugin.get_tree().root.push_input(cancel_release, true)
		await plugin.get_tree().process_frame
		check("Drag cancelled" in dock.status_label.text and StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.is_empty(), "empty drop cancels without authoring")
		var screenshot := "res://.godot/story-authoring-editor-%d.png" % resolution.x
		check(plugin.get_tree().root.get_texture().get_image().save_png(screenshot) == OK, "editor screenshot at %s" % resolution)
		if a.get_output_port_count() == 0 or b.get_input_port_count() == 0: continue
		var start: Vector2 = a.get_global_transform() * a.get_output_port_position(0)
		var finish: Vector2 = b.get_global_transform() * b.get_input_port_position(0)
		var drag_started := [false]
		if dock.graph.has_signal("connection_drag_started"):
			dock.graph.connect("connection_drag_started", func(_node: StringName, _port: int, _is_output: bool): drag_started[0] = true)
		var hover := InputEventMouseMotion.new(); hover.position = start; hover.global_position = start
		plugin.get_tree().root.push_input(hover, true)
		await plugin.get_tree().process_frame
		var press := InputEventMouseButton.new(); press.position = start; press.global_position = start; press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
		plugin.get_tree().root.push_input(press, true)
		await plugin.get_tree().process_frame
		var move := InputEventMouseMotion.new(); move.position = finish; move.global_position = finish; move.relative = finish - start; move.button_mask = MOUSE_BUTTON_MASK_LEFT
		plugin.get_tree().root.push_input(move, true)
		await plugin.get_tree().process_frame
		check(drag_started[0], "connection drag preview starts")
		var release := InputEventMouseButton.new(); release.position = finish; release.global_position = finish; release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false
		plugin.get_tree().root.push_input(release, true)
		await plugin.get_tree().process_frame
		check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1, "mouse drag creates Resource")
		check(dock.selected_resource is StoryTransitionData, "drag opens transition Inspector")
		var card_a: GraphNode = dock._cards["test.a"]
		var card_b: GraphNode = dock._cards["test.b"]
		var line_start: Vector2 = card_a.get_global_transform() * card_a.get_output_port_position(0)
		var line_end: Vector2 = card_b.get_global_transform() * card_b.get_input_port_position(0)
		await _right_click(plugin, (line_start + line_end) / 2.0)
		check(dock._context_mode == "transition" and dock._context_transition is StoryTransitionData, "right-click connection resolves Resource")
		dock._context_menu.hide()
		if resolution.x == 1920:
			var parallel := StoryTransitionData.new(); parallel.transition_id = &"test.parallel"; parallel.target_stage_id = &"test.b"; parallel.automatic = false
			check(StoryGraphAuthoring.set_registered(dock.database, StoryGraphAuthoring.find_stage(dock.database, "test.a").stage, parallel, true) == OK, "parallel Resource persisted for context test")
			dock.refresh()
			await plugin.get_tree().process_frame
			card_a = dock._cards["test.a"]; card_b = dock._cards["test.b"]
			line_start = card_a.get_global_transform() * card_a.get_output_port_position(0)
			line_end = card_b.get_global_transform() * card_b.get_input_port_position(0)
			await _right_click(plugin, (line_start + line_end) / 2.0)
			check(dock._context_mode == "transition_select" and dock._context_candidates.size() == 2, "parallel edge opens ID selection")
			dock._on_context_action(1001)
			check(dock._context_transition == parallel, "parallel context selects exact transition")
			dock._context_menu.hide()
		if resolution.x == 1280:
			dock._on_disconnection_request(dock._cards["test.a"].name, 0, dock._cards["test.b"].name, 0)
			dock._confirm_delete()
			dock._delete_dialog.hide()
			check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.is_empty(), "edge removed before next layout")
	check(DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH)) == OK, "GUI fixture cleaned")
	print("STORY_AUTHORING_TEST GUI: %d checks, %d failures" % [checks, failures])
	return failures

static func _right_click(plugin: EditorPlugin, point: Vector2) -> void:
	var hover := InputEventMouseMotion.new(); hover.position = point; hover.global_position = point
	plugin.get_tree().root.push_input(hover, true)
	await plugin.get_tree().process_frame
	var press := InputEventMouseButton.new(); press.position = point; press.global_position = point; press.button_index = MOUSE_BUTTON_RIGHT; press.pressed = true
	plugin.get_tree().root.push_input(press, true)
	await plugin.get_tree().process_frame
	var release := InputEventMouseButton.new(); release.position = point; release.global_position = point; release.button_index = MOUSE_BUTTON_RIGHT; release.pressed = false
	plugin.get_tree().root.push_input(release, true)
	await plugin.get_tree().process_frame

static func run_os_mouse(plugin: EditorPlugin, dock: Control) -> int:
	var requested := Vector2i(1280, 720) if "--size-1280" in OS.get_cmdline_user_args() else Vector2i(1920, 1080)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(requested)
	plugin.get_tree().root.size = requested
	DisplayServer.window_set_position(Vector2i.ZERO)
	plugin.make_bottom_panel_item_visible(dock)
	dock.interaction_diagnostics = true
	await plugin.get_tree().create_timer(0.5).timeout
	dock.graph.scroll_offset = Vector2.ZERO
	await plugin.get_tree().process_frame
	var a: GraphNode = dock._cards["test.a"]
	var b: GraphNode = dock._cards["test.b"]
	check(a.get_output_port_count() == 1 and b.get_input_port_count() == 1, "OS mouse ports rendered")
	var start: Vector2 = a.get_screen_transform() * a.get_output_port_position(0)
	var finish: Vector2 = b.get_screen_transform() * b.get_input_port_position(0)
	var drag_started := [false]
	dock.graph.connection_drag_started.connect(func(_node: StringName, _port: int, _output: bool): drag_started[0] = true)
	var payload := {"start": [roundi(start.x), roundi(start.y)], "finish": [roundi(finish.x), roundi(finish.y)], "size": [requested.x, requested.y], "window": [DisplayServer.window_get_position().x, DisplayServer.window_get_position().y]}
	var file := FileAccess.open(MOUSE_TARGET_PATH, FileAccess.WRITE)
	if file == null:
		check(false, "OS mouse target file created")
		return failures
	file.store_string(JSON.stringify(payload)); file.close()
	print("STORY_OS_MOUSE_READY: ", JSON.stringify(payload))
	for wait_index in 120:
		if StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1: break
		await plugin.get_tree().create_timer(0.1).timeout
	print("STORY_OS_MOUSE_OBSERVED: mouse=", DisplayServer.mouse_get_position(), " hovered=", plugin.get_tree().root.gui_get_hovered_control(), " graph=", dock.graph.get_global_rect(), " window=", DisplayServer.window_get_position())
	check(drag_started[0], "X11 mouse press started GraphEdit preview")
	check(StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1, "X11 mouse drag saved transition")
	check(dock.selected_resource is StoryTransitionData, "X11 mouse drop opened Inspector")
	if StoryGraphAuthoring.find_stage(dock.database, "test.a").stage.transitions.size() == 1:
		var disk: StoryDatabase = ResourceLoader.load(FIXTURE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		check(StoryGraphAuthoring.find_stage(disk, "test.a").stage.transitions.size() == 1, "X11 mouse transition persisted on disk")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MOUSE_TARGET_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH))
	print("STORY_AUTHORING_TEST OS_MOUSE: %d checks, %d failures" % [checks, failures])
	return failures

static func _count(rows: Array[Dictionary], code: String) -> int:
	var count := 0
	for row in rows:
		if row.code == code: count += 1
	return count
