class_name DetectionComponent extends Node
signal player_entered
signal player_exited
signal interacted
@export var interact_label_text: String = "E  to interact"
@export var interaction_radius: float = 250
@export_flags_2d_physics var obstruction_mask: int = 16
var _area: Area2D
var _label: Label
var is_player_in_range: bool = false
func _ready() -> void:
	add_to_group("npc_interaction")
	_area = get_parent() as Area2D if get_parent() is Area2D else get_parent().get_node_or_null("Area2D")
	_label = get_parent().get_node_or_null("InteractLabel")
	if _label:
		_label.text = interact_label_text
		_label.z_index = 100
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _area:
		if not _area.body_entered.is_connected(_on_area_2d_body_entered): _area.body_entered.connect(_on_area_2d_body_entered)
		if not _area.body_exited.is_connected(_on_area_2d_body_exited): _area.body_exited.connect(_on_area_2d_body_exited)
func available(player: Node2D) -> bool:
	if not is_instance_valid(player) or not is_inside_tree() or get_tree().paused or QuestOfferDialog.is_open() or Dialogic.current_timeline != null or not Player_Global_Data.p_moveable: return false
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return false
	var npc := get_parent() as Node2D
	if npc.global_position.distance_to(player.global_position) > interaction_radius: return false
	var exclude: Array[RID] = []
	if npc is CollisionObject2D: exclude.append(npc.get_rid())
	if player is CollisionObject2D: exclude.append(player.get_rid())
	var ray := PhysicsRayQueryParameters2D.create(player.global_position, npc.global_position, obstruction_mask, exclude)
	return npc.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
static func focused(tree: SceneTree) -> DetectionComponent:
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null: return null
	var best: DetectionComponent
	var distance := INF
	for candidate in tree.get_nodes_in_group("npc_interaction"):
		if not candidate.available(player): continue
		var d: float = player.global_position.distance_squared_to(candidate.get_parent().global_position)
		if d < distance or (is_equal_approx(d, distance) and str(candidate.get_path()) < str(best.get_path())):
			distance = d
			best = candidate
	return best
func _process(_delta: float) -> void:
	var focus := focused(get_tree()) == self
	if _label: _label.visible = focus
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and focused(get_tree()) == self:
		get_viewport().set_input_as_handled()
		interacted.emit()
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	is_player_in_range = true
	player_entered.emit()
func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	is_player_in_range = false
	player_exited.emit()
func set_label_text(text: String) -> void:
	interact_label_text = text
	if _label: _label.text = text
