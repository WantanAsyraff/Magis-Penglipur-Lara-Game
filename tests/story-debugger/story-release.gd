extends Node
func _ready() -> void:
	await get_tree().process_frame
	var debug_build := OS.has_feature("debug")
	var active := StoryDebugRuntime.open_debugger()
	print("STORY_DEBUG_RELEASE: debug_feature=%s overlay_activated=%s" % [debug_build, active])
	if not debug_build and active:
		push_error("Release build activated story debugger")
		get_tree().quit(1)
		return
	if active: StoryDebugRuntime.close_debugger()
	get_tree().quit(0)
