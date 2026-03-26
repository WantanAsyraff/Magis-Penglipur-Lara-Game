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

@onready var timer: Timer = Timer.new()

# Track active enemies spawned by THIS spawner
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
	# 1. Clean up the tracking list (remove freed/dead enemies)
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e))
	
	# 2. Check if we are at the limit
	if _active_enemies.size() >= max_enemies:
		return

	# 3. Pick a random enemy based on weight
	var enemy_scene = _get_random_enemy_scene()
	if not enemy_scene:
		return

	# 4. Instantiate and Position
	var enemy_instance = enemy_scene.instantiate() as Enemy
	if enemy_instance:
		# Add to the scene tree (usually a sibling or a dedicated "Enemies" node)
		get_parent().add_child.call_deferred(enemy_instance)
		enemy_instance.global_position = global_position
		_active_enemies.append(enemy_instance)

func _get_random_enemy_scene() -> PackedScene:
	if spawn_pool.is_empty() or _total_weight <= 0:
		return null
		
	var roll = randf() * _total_weight
	var current_sum = 0.0
	
	for entry in spawn_pool:
		current_sum += entry.spawn_weight
		if roll <= current_sum:
			return entry.enemy_scene
			
	return spawn_pool[0].enemy_scene # Fallback
