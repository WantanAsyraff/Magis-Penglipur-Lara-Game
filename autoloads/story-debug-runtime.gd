extends Node
## Development-only launcher. Release builds never create the overlay or history.
var service: StoryDebugService
var overlay: StoryDebugOverlay
var _previous_mouse := Input.MOUSE_MODE_VISIBLE
var _previous_focus: Control
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("debug"): set_process_unhandled_key_input(false); return
	service = StoryDebugService.new(StoryDirector)
	service.attach_runtime()
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.has_feature("debug") or not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_F12: return
	if overlay != null and is_instance_valid(overlay) and overlay.visible: close_debugger()
	elif CutsceneFlow.sequence == null and not is_instance_valid(ModalService.holder): open_debugger()
	get_viewport().set_input_as_handled()
func open_debugger() -> bool:
	if not OS.has_feature("debug") or service == null or CutsceneFlow.sequence != null or is_instance_valid(ModalService.holder): return false
	if not is_instance_valid(overlay):
		overlay = load("res://components/story/debug/ui/story-debug-overlay.tscn").instantiate() as StoryDebugOverlay
		overlay.service = service
		add_child(overlay)
		overlay.close_requested.connect(close_debugger)
	_previous_mouse = Input.mouse_mode
	_previous_focus = get_viewport().gui_get_focus_owner()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show(); overlay.refresh()
	return true
func close_debugger() -> void:
	if not is_instance_valid(overlay) or not overlay.visible: return
	overlay.hide()
	Input.mouse_mode = _previous_mouse
	if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree(): _previous_focus.grab_focus()
func _exit_tree() -> void:
	if service: service.detach_runtime()
