class_name EnemySpawner extends Marker2D
signal enemy_spawned(enemy: Enemy)
@export var spawn_pool: Array[SpawnData] = []
@export_range(0, 1000) var max_enemies: int = 5
@export var spawn_interval: float = 3
@export var autostart: bool = true
@export var respawn: bool = true
@export var use_area_spawning: bool = false
@export var spawn_area_width: float = 200
@export var spawn_area_height: float = 200
@export_flags_2d_physics var spawn_blocking_mask: int = 19
@export_range(1, 16) var placement_attempts: int = 6
var timer: Timer
var _active_enemies: Array[Enemy] = []
var _pending: int = 0
var _epoch: int = 0
var _spawned_total: int = 0
var _sequence: int = 0
var _running: bool = true
func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = maxf(spawn_interval, 0.05)
	timer.timeout.connect(_try_spawn)
	if autostart: start_spawning()
	hide()
func start_spawning() -> void:
	_running = true
	if SpellExecutor.is_authoritative(self): timer.start()
func stop_spawning() -> void:
	_running = false
	_epoch += 1
	if timer: timer.stop()
func _exit_tree() -> void:
	_epoch += 1
func _try_spawn() -> void:
	if not _running or not SpellExecutor.is_authoritative(self): return
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion() and not e.get_meta("combat_dead", false))
	if _active_enemies.size() + _pending >= max_enemies or (not respawn and _spawned_total + _pending >= max_enemies): return
	var entry := _pick_entry()
	if entry == null: return
	_pending += 1
	_commit_spawn.call_deferred(entry, _epoch)
func _pick_entry() -> SpawnData:
	var total := 0.0
	for entry in spawn_pool:
		if entry != null and entry.enemy_scene != null and is_finite(entry.spawn_weight) and entry.spawn_weight > 0: total += entry.spawn_weight
	if total <= 0: return null
	var roll := randf() * total
	for entry in spawn_pool:
		if entry == null or entry.enemy_scene == null or not is_finite(entry.spawn_weight) or entry.spawn_weight <= 0: continue
		roll -= entry.spawn_weight
		if roll < 0: return entry
	return null
func _get_random_enemy_scene() -> PackedScene:
	var entry := _pick_entry()
	return entry.enemy_scene if entry else null
func _commit_spawn(entry: SpawnData, epoch: int) -> void:
	_pending -= 1
	if epoch != _epoch or not _running or not SpellExecutor.is_authoritative(self) or is_queued_for_deletion(): return
	var spawned := entry.enemy_scene.instantiate()
	if not spawned is Enemy:
		spawned.free(); return
	var enemy := spawned as Enemy
	if entry.enemy_data: enemy.enemy_data = entry.enemy_data
	if enemy.enemy_data and not enemy.enemy_data.validate().is_empty(): enemy.free(); return
	var point := Vector2.ZERO
	var placed := false
	for attempt in placement_attempts:
		point = _get_spawn_position()
		if _position_clear(enemy, point): placed = true; break
	if not placed: enemy.free(); return
	_sequence += 1
	enemy.spawn_id = Enemy.allocate_spawn_id(String(get_path()))
	# Set local coordinates before parenting, so _ready sees the correct world origin.
	enemy.position = get_parent().to_local(point)
	get_parent().add_child(enemy)
	if enemy.is_queued_for_deletion(): return
	_active_enemies.append(enemy)
	_spawned_total += 1
	enemy.enemy_died.connect(_forget.bind(enemy), CONNECT_ONE_SHOT)
	enemy.tree_exiting.connect(_forget.bind(enemy), CONNECT_ONE_SHOT)
	enemy_spawned.emit(enemy)
func _forget(enemy: Enemy) -> void:
	_active_enemies.erase(enemy)
func _position_clear(enemy: Enemy, point: Vector2) -> bool:
	var collision := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = get_parent().global_transform * Transform2D(enemy.rotation, enemy.scale, enemy.skew, get_parent().to_local(point)) * collision.transform
	query.collision_mask = spawn_blocking_mask
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
func _get_spawn_position() -> Vector2:
	return global_position + (Vector2(randf_range(-spawn_area_width / 2, spawn_area_width / 2), randf_range(-spawn_area_height / 2, spawn_area_height / 2)) if use_area_spawning else Vector2.ZERO)
func _draw() -> void:
	if use_area_spawning: draw_rect(Rect2(-Vector2(spawn_area_width, spawn_area_height)/2, Vector2(spawn_area_width, spawn_area_height)), Color(1, .4, 0, .4), false)
