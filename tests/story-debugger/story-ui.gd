extends Node
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STORY_DEBUG_UI: " + message)
func _ready() -> void:
	await get_tree().process_frame
	SaveManager.session_ready = true
	StoryDirector._on_restored()
	var before := StorySaveService.encode(StoryDirector.state, StoryDirector.registry)
	var flags_before := QuestManager.world_flags.duplicate(true)
	check(StoryDebugRuntime.open_debugger(), "developer overlay opens")
	await get_tree().process_frame
	var overlay := StoryDebugRuntime.overlay
	check(overlay != null and overlay.visible and overlay.tabs.get_tab_count() == 7, "seven working tabs visible")
	check("prologue.wake_up" in overlay.overview.text, "active stage shown")
	check(overlay._graph_nodes.size() == 5, "authored stages drawn")
	overlay.search.text = "after_exam"
	overlay._populate_graph()
	await get_tree().process_frame
	check(overlay._graph_nodes.size() == 1, "graph search filters stages")
	var node: Node = overlay._graph_nodes.get("prologue.after_exam")
	if node: overlay._on_graph_node_selected(node)
	check("prologue.after_exam" in overlay.inspector.text, "stage selection updates inspector")
	overlay._scan_world()
	check(overlay.world_list.item_count > 0, "world inspection handles the active scene")
	check(overlay.simulation_conditions.item_count > 0, "what-if panel handles active stage")
	if "--capture-story-debugger" in OS.get_cmdline_user_args():
		if "--story-debug-720p" in OS.get_cmdline_user_args():
			get_window().content_scale_size = Vector2i(1280,720)
			get_window().size = Vector2i(1280,720)
		overlay.search.clear(); overlay.chapter_filter.select(0); overlay._populate_graph(); overlay._focus_active()
		overlay.tabs.current_tab = 1
		overlay._on_graph_node_selected(overlay._graph_nodes["prologue.wake_up"])
		for tick in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("/tmp/magis-story-debugger")
		get_viewport().get_texture().get_image().save_png("/tmp/magis-story-debugger/story-debugger.png")
	StoryDebugRuntime.close_debugger()
	check(not overlay.visible, "overlay closes")
	check(StorySaveService.encode(StoryDirector.state, StoryDirector.registry) == before and QuestManager.world_flags == flags_before, "open refresh and close leave campaign unchanged")
	print("STORY_DEBUG_UI: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
