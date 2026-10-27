class_name EnemyDetection extends Node
signal player_entered
signal player_exited
var config: EnemyPerceptionData
## Legacy name retained; the selected target may now be any eligible combat actor.
var player: Node2D
var last_known_position := Vector2.ZERO
var visible: bool = false
var _sight_memory_timer: float = 0
var _until_scan: float = 0
var threat: Dictionary = {}
var blackboard: Dictionary = {}
var scan_count: int = 0
func connect_area(area: Area2D) -> void:
	# Compatibility with existing scenes. Periodic candidate discovery handles all groups.
	if not area.body_entered.is_connected(_on_body_entered): area.body_entered.connect(_on_body_entered)
	if not area.body_exited.is_connected(_on_body_exited): area.body_exited.connect(_on_body_exited)
func configure(value: EnemyPerceptionData) -> void:
	config = value
	get_parent().set_meta("faction_relations", value.relations.duplicate())
func tick(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	if config == null: config = EnemyPerceptionData.new()
	_sight_memory_timer = maxf(0, _sight_memory_timer - delta)
	for key in threat.keys():
		threat[key] = maxf(0, float(threat[key]) - config.threat_decay * delta)
		if threat[key] <= 0 or not is_instance_id_valid(key): threat.erase(key)
	_until_scan -= delta
	if _until_scan <= 0:
		_until_scan = config.scan_interval
		scan()
	if not valid_target(player):
		player = null; visible = false
	if not visible and _sight_memory_timer <= 0: _select(null)
	_refresh_blackboard()
func valid_target(target: Variant) -> bool:
	return is_instance_valid(target) and target is Node2D and not target.is_queued_for_deletion() and not target.get_meta("combat_dead", false) and target != get_parent() and CombatFactions.relation(get_parent(), target) < 0
func can_see(target: Node2D) -> bool:
	if not valid_target(target): return false
	var actor := get_parent() as Node2D
	if actor.global_position.distance_to(target.global_position) > config.detection_range: return false
	var query := PhysicsRayQueryParameters2D.create(actor.global_position, target.global_position, config.terrain_mask)
	if actor is CollisionObject2D: query.exclude = [actor.get_rid()]
	return actor.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
func scan() -> void:
	if not SpellExecutor.is_authoritative(self) or config == null: return
	scan_count += 1
	var actor := get_parent() as Node2D
	var candidates: Array[Node2D] = []
	for group in config.target_groups:
		for node in get_tree().get_nodes_in_group(group):
			var target := node as Node2D
			if valid_target(target) and target not in candidates and actor.global_position.distance_to(target.global_position) <= config.detection_range: candidates.append(target)
	candidates.sort_custom(func(a, b): return _priority(a) > _priority(b))
	var best: Node2D
	for target in candidates.slice(0, config.max_candidates):
		if can_see(target): best = target; break
	visible = best != null
	if best:
		_select(best)
		last_known_position = best.global_position
		_sight_memory_timer = config.sight_memory
	elif not valid_target(player) or _sight_memory_timer <= 0:
		_select(null)
	_refresh_blackboard()
func _priority(target: Node2D) -> float:
	return float(threat.get(target.get_instance_id(), 0)) * 10 - (get_parent() as Node2D).global_position.distance_to(target.global_position) + (20 if target == player else 0)
func record_hit(source: Node2D, amount: float) -> void:
	if amount <= 0 or not valid_target(source): return
	threat[source.get_instance_id()] = float(threat.get(source.get_instance_id(), 0)) + amount
	_until_scan = 0
func _select(value: Node2D) -> void:
	if player == value: return
	if is_instance_valid(player): player_exited.emit()
	player = value
	if player: player_entered.emit()
func _refresh_blackboard() -> void:
	blackboard.target = player
	blackboard.visible = visible and valid_target(player)
	blackboard.last_known_position = last_known_position
	blackboard.distance = (get_parent() as Node2D).global_position.distance_to(player.global_position) if valid_target(player) else INF
	blackboard.threat = float(threat.get(player.get_instance_id(), 0)) if valid_target(player) else 0
func has_line_of_sight() -> bool:
	return visible and valid_target(player)
func has_memory() -> bool:
	return _sight_memory_timer > 0
func _on_body_entered(_body: Node) -> void:
	_until_scan = 0
func _on_body_exited(_body: Node) -> void:
	_until_scan = 0
