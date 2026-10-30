extends CanvasLayer
var page: Control
func present(scene: PackedScene) -> bool:
	layer = 100; process_mode = Node.PROCESS_MODE_ALWAYS
	page = scene.instantiate()
	if not ModalService.acquire(page): page.free(); queue_free(); return false
	add_child(page); page.closed.connect(close)
	var world := get_tree().current_scene
	if world != null and world != page: world.tree_exiting.connect(close,CONNECT_ONE_SHOT)
	return true
func close() -> void:
	if is_instance_valid(page): ModalService.release(page)
	queue_free()
