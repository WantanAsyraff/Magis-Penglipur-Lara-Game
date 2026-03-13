# Enemy.gd
# Generic enemy template. Configure via exports per enemy type.
# Requires: HitboxComponent child node, AnimatedSprite2D, CollisionShape2D,
#           DetectionArea (Area2D), AttackArea (Area2D), RayCast2D

class_name Enemy
extends CharacterBody2D

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal enemy_died()
signal enemy_hurt(amount: float)
signal state_changed(new_state: State)

# ─────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEATH }
enum AttackType { MELEE, RANGED, BOTH }

# ─────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────
@export_group("Identity")
## Display name used in UI and debug.
@export var enemy_name: String = "Unknown Enemy"
## Optional SpellData for ranged attacks.
@export var ranged_spell: SpellData = null

# ─────────────────────────────────────────
# STATS
# ─────────────────────────────────────────
@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 140.0

## Melee damage dealt on attack hit.
@export var melee_damage: float = 15.0

## How long between attacks in seconds.
@export var attack_cooldown: float = 1.2

## How long the hurt state lasts.
@export var hurt_duration: float = 0.4

# ─────────────────────────────────────────
# COMBAT
# ─────────────────────────────────────────
@export_group("Combat")
@export var attack_type: AttackType = AttackType.MELEE

## Melee attack reach in pixels.
@export var melee_range: float = 40.0

## Ranged attack fires when player is within this distance.
@export var ranged_trigger_distance: float = 200.0

## Preferred distance the enemy tries to maintain from the player when ranged.
@export var preferred_distance: float = 150.0

## How close the player can get before the enemy actively retreats.
@export var retreat_threshold: float = 80.0

## Damage reduction and multiplier passed to HitboxComponent.
@export var damage_reduction: float = 0.0
@export var damage_multiplier: float = 1.0

## If true, this enemy can receive status effects.
@export var receives_status_effects: bool = true

# ─────────────────────────────────────────
# PATROL
# ─────────────────────────────────────────
@export_group("Patrol")
## Set these in editor for fixed patrol. If empty, uses auto left-right.
@export var patrol_points: Array[Vector2] = []

## Auto patrol range in pixels (used when no patrol points set).
@export var patrol_range: float = 120.0

# ─────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────
@export_group("Detection")
## Radius of the detection Area2D. Mirror this in the editor node.
@export var detection_radius: float = 180.0

## How long the enemy remembers the player after losing sight (seconds).
@export var sight_memory: float = 2.5

# ─────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var raycast: RayCast2D = $RayCast2D
@onready var attack_timer: Timer = $AttackTimer
@onready var hurt_timer: Timer = $HurtTimer

# ─────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────
var current_state: State = State.IDLE
var current_health: float = 0.0
var _player: Node = null
var _can_attack: bool = true
var _sight_memory_timer: float = 0.0
var _facing_right: bool = true

# Patrol
var _patrol_index: int = 0
var _auto_patrol_origin: Vector2 = Vector2.ZERO
var _auto_patrol_direction: int = 1  # 1 = right, -1 = left

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	current_health = max_health
	_auto_patrol_origin = global_position

	# Hitbox setup
	hitbox.receives_status_effects = receives_status_effects
	hitbox.has_mana = false
	hitbox.receives_knockback = true
	hitbox.damage_reduction = damage_reduction
	hitbox.damage_multiplier = damage_multiplier
	hitbox.damage_taken.connect(_on_damage_taken)
	hitbox.died.connect(_on_died)

	# Timers
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	hurt_timer.wait_time = hurt_duration
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	# Detection
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	_set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_update_sight_memory(delta)
	_run_state(delta)
	move_and_slide()

# ─────────────────────────────────────────
# STATE MACHINE
# ─────────────────────────────────────────
func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)
	_on_state_entered(new_state)

func _on_state_entered(state: State) -> void:
	match state:
		State.IDLE:
			_play_animation("idle")
		State.PATROL:
			_play_animation("walk")
		State.CHASE:
			_play_animation("walk")
		State.ATTACK:
			_play_animation("attack")
			# ── Fire once on entry, then wait for timer to return to CHASE ──
			_execute_attack()
		State.HURT:
			_play_animation("hurt")
			hurt_timer.start()
		State.DEATH:
			_play_animation("death")
			hitbox.clear_all_effects()
			set_physics_process(false)
			await sprite.animation_finished
			queue_free()

func _run_state(delta: float) -> void:
	match current_state:
		State.IDLE:    _state_idle()
		State.PATROL:  _state_patrol(delta)
		State.CHASE:   _state_chase()
		State.ATTACK:  _state_attack_hold()  # Just holds position — no re-firing
		State.HURT:    pass
		State.DEATH:   pass

# ─────────────────────────────────────────
# STATES
# ─────────────────────────────────────────
func _state_idle() -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed)
	if _player == null:
		_set_state(State.PATROL)

func _state_patrol(delta: float) -> void:
	if _player != null and _has_line_of_sight():
		_set_state(State.CHASE)
		return

	if patrol_points.size() > 0:
		_patrol_fixed()
	else:
		_patrol_auto()

func _state_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	if not _has_line_of_sight():
		if _sight_memory_timer <= 0.0:
			_set_state(State.PATROL)
			return

	var dist: float = global_position.distance_to(_player.global_position)
	var direction: Vector2 = (_player.global_position - global_position).normalized()

	# Check attack trigger
	var should_attack := false
	match attack_type:
		AttackType.MELEE:
			should_attack = dist <= melee_range
		AttackType.RANGED:
			should_attack = dist <= ranged_trigger_distance and dist > retreat_threshold
		AttackType.BOTH:
			if dist <= melee_range:
				should_attack = true
			elif dist <= ranged_trigger_distance and dist > retreat_threshold:
				should_attack = ranged_spell != null

	if should_attack and _can_attack:
		_set_state(State.ATTACK)
		return

	# Movement logic
	match attack_type:
		AttackType.MELEE:
			velocity.x = direction.x * chase_speed
			_update_facing(direction.x)

		AttackType.RANGED:
			if dist < retreat_threshold:
				velocity.x = -direction.x * chase_speed
				_update_facing(direction.x)
			elif dist > ranged_trigger_distance:
				velocity.x = direction.x * chase_speed
				_update_facing(direction.x)
			else:
				velocity.x = move_toward(velocity.x, 0, chase_speed)

		AttackType.BOTH:
			if dist < retreat_threshold:
				velocity.x = -direction.x * chase_speed
				_update_facing(direction.x)
			elif dist > ranged_trigger_distance:
				velocity.x = direction.x * chase_speed
				_update_facing(direction.x)
			else:
				velocity.x = move_toward(velocity.x, 0, chase_speed)

# Called every frame while in ATTACK state — only holds position, no re-firing.
# _execute_attack() already ran once in _on_state_entered(State.ATTACK).
# The attack_timer timeout will call _on_attack_timer_timeout() which returns
# the enemy to CHASE, completing the attack cycle.
func _state_attack_hold() -> void:
	match attack_type:
		AttackType.RANGED, AttackType.BOTH:
			velocity.x = move_toward(velocity.x, 0, chase_speed)
		AttackType.MELEE:
			pass  # Melee can keep momentum

# ─────────────────────────────────────────
# PATROL HELPERS
# ─────────────────────────────────────────
func _patrol_fixed() -> void:
	if patrol_points.is_empty():
		return
	var target := patrol_points[_patrol_index]
	var direction := (target - global_position).normalized()
	velocity.x = direction.x * move_speed
	_update_facing(direction.x)

	if global_position.distance_to(target) < 8.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		velocity.x = 0.0

func _patrol_auto() -> void:
	velocity.x = _auto_patrol_direction * move_speed
	_update_facing(float(_auto_patrol_direction))

	var dist_from_origin := global_position.x - _auto_patrol_origin.x
	if abs(dist_from_origin) >= patrol_range:
		_auto_patrol_direction *= -1

# ─────────────────────────────────────────
# ATTACK
# ─────────────────────────────────────────
func _execute_attack() -> void:
	if _player == null:
		return

	_can_attack = false
	attack_timer.start()

	var dist := global_position.distance_to(_player.global_position)

	match attack_type:
		AttackType.MELEE:
			_do_melee_attack()
		AttackType.RANGED:
			_do_ranged_attack()
		AttackType.BOTH:
			if dist <= melee_range:
				_do_melee_attack()
			elif ranged_spell != null and dist <= ranged_trigger_distance:
				_do_ranged_attack()

func _do_melee_attack() -> void:
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= melee_range:
		var player_hitbox := _player.get_node_or_null("HitboxComponent") as HitboxComponent
		if player_hitbox:
			var direction: Vector2 = (_player.global_position - global_position).normalized()
			var fake_spell := SpellData.new()
			fake_spell.projectile_damage = melee_damage
			fake_spell.knockback_force = 120.0
			player_hitbox.receive_hit(fake_spell, direction)

func _do_ranged_attack() -> void:
	if ranged_spell == null or _player == null:
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	var scene_to_use: PackedScene = ranged_spell.spell_scene if ranged_spell.spell_scene else preload("res://components/projectiles/magis-projectile.tscn")

	var inst = scene_to_use.instantiate()
	inst.spell_data = ranged_spell
	inst.position = global_position + direction * 250.0
	inst.direction = direction
	get_parent().add_child(inst)

# ─────────────────────────────────────────
# DETECTION & SIGHT
# ─────────────────────────────────────────
func _has_line_of_sight() -> bool:
	if _player == null:
		return false
	raycast.target_position = to_local(_player.global_position)
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		return true
	return raycast.get_collider() == _player

func _update_sight_memory(delta: float) -> void:
	if _player != null and _has_line_of_sight():
		_sight_memory_timer = sight_memory
	elif _sight_memory_timer > 0.0:
		_sight_memory_timer -= delta

func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_detection_area_body_exited(body: Node) -> void:
	if body == _player:
		pass  # Sight memory handles the delay

# ─────────────────────────────────────────
# HITBOX CALLBACKS
# ─────────────────────────────────────────
func _on_damage_taken(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	enemy_hurt.emit(amount)
	if current_state != State.DEATH and current_state != State.HURT:
		_set_state(State.HURT)

func _on_died() -> void:
	enemy_died.emit()
	_set_state(State.DEATH)

# ─────────────────────────────────────────
# TIMER CALLBACKS
# ─────────────────────────────────────────
func _on_attack_timer_timeout() -> void:
	_can_attack = true
	# Return to chase after cooldown — CHASE will re-enter ATTACK if still in range
	if current_state == State.ATTACK:
		if _player != null:
			_set_state(State.CHASE)
		else:
			_set_state(State.PATROL)

func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		if _player != null and _has_line_of_sight():
			_set_state(State.CHASE)
		else:
			_set_state(State.PATROL)

# ─────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _update_facing(direction_x: float) -> void:
	if direction_x > 0.01:
		_facing_right = true
		sprite.flip_h = false
	elif direction_x < -0.01:
		_facing_right = false
		sprite.flip_h = true

func _play_animation(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

## Returns current health as a 0.0–1.0 ratio. Useful for health bars.
func get_health_ratio() -> float:
	return current_health / max_health

## Call this to apply a spell directly to this enemy (e.g. from AOE).
func apply_spell_hit(spell: SpellData, direction: Vector2) -> void:
	hitbox.receive_hit(spell, direction)
