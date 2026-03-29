# EnemySpawner.gd
extends Marker2D

@export_group("Pool Configuration")
## List of potential enemies and their weights
@export var spawn_pool: Array[SpawnData] = []
## Maximum number of enemies this spawner can have active at once
@export var max_enemies: int = 5

@export_group("Timing")
## Seconds between spawn attempts
@export var spawn_interval: float = 3.0
## If true, starts spawning immediately on _ready
@export var autostart: bool = true

@export_group("Area Spawning")
## If true, enemies spawn at a random point within a rectangle instead of at this node's position
@export var use_area_spawning: bool = false
## Width of the spawn rectangle (centered on this node)
@export var spawn_area_width: float = 200.0
## Height of the spawn rectangle (centered on this node)
@export var spawn_area_height: float = 200.0

@onready var timer: Timer = Timer.new()

var _active_enemies: Array[Enemy] = []
var _total_weight: float = 0.0

func _ready() -> void:
	_calculate_total_weight()
	_setup_timer()
	if autostart:
		start_spawning()

func _setup_timer() -> void:
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.timeout.connect(_try_spawn)

func start_spawning() -> void:
	timer.start()

func stop_spawning() -> void:
	timer.stop()

func _calculate_total_weight() -> void:
	_total_weight = 0.0
	for entry in spawn_pool:
		_total_weight += entry.spawn_weight

func _try_spawn() -> void:
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e))

	if _active_enemies.size() >= max_enemies:
		return

	var enemy_scene = _get_random_enemy_scene()
	if not enemy_scene:
		return

	var enemy_instance = enemy_scene.instantiate() as Enemy
	if enemy_instance:
		get_parent().add_child.call_deferred(enemy_instance)
		enemy_instance.global_position = _get_spawn_position()
		_active_enemies.append(enemy_instance)

## Returns a spawn position — either this node's position, or a random point in the rectangle.
func _get_spawn_position() -> Vector2:
	if not use_area_spawning:
		return global_position

	var half_w := spawn_area_width * 0.5
	var half_h := spawn_area_height * 0.5
	var offset := Vector2(
		randf_range(-half_w, half_w),
		randf_range(-half_h, half_h)
	)
	return global_position + offset

func _get_random_enemy_scene() -> PackedScene:
	if spawn_pool.is_empty() or _total_weight <= 0:
		return null

	var roll := randf() * _total_weight
	var current_sum := 0.0

	for entry in spawn_pool:
		current_sum += entry.spawn_weight
		if roll <= current_sum:
			return entry.enemy_scene

	return spawn_pool[0].enemy_scene


# --- Editor Gizmo ---
func _draw() -> void:
	if not use_area_spawning:
		return
	# Draw the rectangle outline in the editor viewport so you can see the spawn zone.
	var rect := Rect2(
		Vector2(-spawn_area_width * 0.5, -spawn_area_height * 0.5),
		Vector2(spawn_area_width, spawn_area_height)
	)
	draw_rect(rect, Color(1.0, 0.4, 0.0, 0.35), true)   # filled, semi-transparent
	draw_rect(rect, Color(1.0, 0.4, 0.0, 0.85), false)  # outline, opaque
