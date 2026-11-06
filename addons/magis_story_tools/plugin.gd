@tool
extends EditorPlugin
var _dock: Control
func _enter_tree() -> void:
	var authoring_test := preload("res://tests/story-debugger/story-editor-authoring-test.gd")
	var args := OS.get_cmdline_user_args()
	if "--story-authoring-create" in args or "--story-authoring-gui" in args or "--story-authoring-os-mouse" in args: authoring_test.setup()
	_dock = preload("res://addons/magis_story_tools/story-editor-dock.gd").new()
	_dock.editor_plugin = self
	if "--story-authoring-create" in args or "--story-authoring-reopen" in args or "--story-authoring-gui" in args or "--story-authoring-os-mouse" in args:
		_dock.database_path = authoring_test.FIXTURE_PATH
	_dock.name = "Magis Story Tools"
	add_control_to_bottom_panel(_dock, "Story")
	if "--story-authoring-create" in args or "--story-authoring-reopen" in args or "--story-authoring-gui" in args or "--story-authoring-os-mouse" in args:
		make_bottom_panel_item_visible(_dock)
	if "--story-authoring-create" in args:
		_run_authoring_test.call_deferred("create")
	elif "--story-authoring-reopen" in args:
		_run_authoring_test.call_deferred("reopen")
	elif "--story-authoring-gui" in args:
		_run_authoring_test.call_deferred("gui")
	elif "--story-authoring-os-mouse" in args:
		_run_authoring_test.call_deferred("os_mouse")
	if "--story-editor-test" in OS.get_cmdline_user_args():
		print("STORY_EDITOR_TEST: loaded %d stages, %d findings" % [_dock.graph_data.get("nodes", []).size(), _dock.issues.size()])
		if _dock.database != null and not _dock.database.arcs.is_empty():
			_dock._select_resource(_dock.database.arcs[0])
			_dock._open_selected()
			_dock.refresh()
			print("STORY_EDITOR_TEST: resource navigation and refresh %s" % ("ready" if _dock.selected_resource != null and _dock.graph_data.get("nodes", []).size() > 0 else "failed"))
func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		if "--story-editor-test" in OS.get_cmdline_user_args(): print("STORY_EDITOR_TEST: dock removed")
	_dock = null
func _run_authoring_test(mode: String) -> void:
	await get_tree().create_timer(2.0).timeout
	var suite := preload("res://tests/story-debugger/story-editor-authoring-test.gd")
	var result: int
	if mode == "create": result = suite.run_create(self, _dock)
	elif mode == "reopen": result = suite.run_reopen(_dock)
	elif mode == "gui": result = await suite.run_gui(self, _dock)
	else: result = await suite.run_os_mouse(self, _dock)
	get_tree().quit(result)
