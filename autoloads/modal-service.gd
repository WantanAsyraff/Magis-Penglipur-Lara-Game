extends Node
var holder: Node
var previous_pause := false
var previous_mouse := Input.MOUSE_MODE_VISIBLE
var previous_focus: Control
var suppress_until := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func acquire(node: Node) -> bool:
	if is_instance_valid(holder) or get_tree().paused: return false
	holder = node; previous_pause = get_tree().paused; previous_mouse = Input.mouse_mode
	previous_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	node.tree_exiting.connect(release.bind(node),CONNECT_ONE_SHOT)
	return true
func release(node: Node) -> bool:
	if holder != node: return false
	holder = null; get_tree().paused = previous_pause; Input.mouse_mode = previous_mouse
	suppress_until = Engine.get_process_frames()+2
	if is_instance_valid(previous_focus) and previous_focus.is_inside_tree() and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	return true
func blocks_world_pause() -> bool:
	return is_instance_valid(holder) or Engine.get_process_frames() <= suppress_until
