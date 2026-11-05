@tool
extends EditorPlugin
var _dock: Control
func _enter_tree() -> void:
	_dock = preload("res://addons/magis_story_tools/story-editor-dock.gd").new()
	_dock.name = "Magis Story Tools"
	add_control_to_bottom_panel(_dock, "Story")
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
