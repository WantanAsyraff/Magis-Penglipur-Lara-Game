# Enemy.gd
# Slim state machine orchestrator.
#
# Required scene tree layout:
# ┣ Enemy (CharacterBody2D)  ← this script
# ┣━ HitboxComponent
# ┣━ AnimatedSprite2D
# ┣━ CollisionShape2D
# ┣━ DetectionArea (Area2D)
# ┣━ AttackArea (Area2D)
# ┣━ RayCast2D(Right)        ← mark unique (%)  target: Vector2(24, 30)
# ┣━ RayCast2D(Left)         ← mark unique (%)  target: Vector2(-24, 30)
# ┣━ AttackTimer (Timer)     ← owned by EnemyCombat
# ┣━ HurtTimer  (Timer)      ← owned by Enemy
# ┣━ EnemyDetection          ← EnemyDetection.gd
# ┣━ EnemyPatrol             ← EnemyPatrol.gd
# ┗━ EnemyCombat             ← EnemyCombat.gd

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
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEATH, RETURN }
enum AttackType { MELEE, RANGED, BOTH }

# ─────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────
@export_group("Identity")
@export var enemy_name: String = "Unknown Enemy"

# ─────────────────────────────────────────
# STATS  (read by components via get_parent())
# ─────────────────────────────────────────
@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var hurt_duration: float = 0.4
@export var damage_reduction: float = 0.0
@export var damage_multiplier: float = 1.0
@export var receives_status_effects: bool = true

# ─────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────
@onready var hitbox: HitboxComponent   = %HitboxComponent
@onready var sprite: AnimatedSprite2D  = %AnimatedSprite2D
@onready var hurt_timer: Timer         = %HurtTimer
@onready var detection: EnemyDetection = %EnemyDetection
@onready var patrol: EnemyPatrol       = %EnemyPatrol
@onready var combat: EnemyCombat       = %EnemyCombat

# ─────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────
var current_state: State = State.IDLE
var current_health: float = 0.0
@export var spell_mana: float = 400.0
var _facing_right: bool = true

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	current_health = max_health
	hitbox.receives_status_effects = receives_status_effects
	hitbox.has_mana = false
	hitbox.receives_knockback = true
	hitbox.damage_reduction = damage_reduction
	hitbox.damage_multiplier = damage_multiplier
	hitbox.damage_taken.connect(_on_damage_taken)
	hitbox.healed.connect(func(amount): current_health = minf(current_health + amount, max_health))
	hitbox.died.connect(_on_died)

	hurt_timer.wait_time = hurt_duration
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	combat.attack_finished.connect(_on_attack_finished)
	detection.connect_area(%DetectionArea)

	_set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self):
		return
	_apply_gravity(delta)
	detection.tick(delta)
	patrol.tick(delta, self)
	combat.tick(delta)
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
		State.PATROL, State.RETURN, State.CHASE:
			_play_animation("walk")
		State.ATTACK:
			_play_animation("attack")
			combat.execute_attack(self, detection.player)
		State.HURT:
			_play_animation("hurt")
			hurt_timer.start()
		State.DEATH:
			enemy_died.emit()
			hitbox.clear_all_effects()
			set_physics_process(false)
			if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
				sprite.play("death")
				await sprite.animation_finished
			queue_free()

func _run_state(delta: float) -> void:
	match current_state:
		State.IDLE:   _state_idle()
		State.PATROL: _state_patrol()
		State.RETURN: _state_return()
		State.CHASE:  _state_chase()
		State.ATTACK: _state_attack_hold()
		State.HURT, State.DEATH: pass

# ─────────────────────────────────────────
# STATES
# ─────────────────────────────────────────
func _state_idle() -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed)
	if detection.player == null:
		_set_state(State.PATROL)

func _state_patrol() -> void:
	if detection.player != null and detection.has_line_of_sight():
		_set_state(State.CHASE)
		return
	velocity.x = patrol.patrol_tick(self, _facing_right)
	_update_facing(float(patrol.get_patrol_direction()))

func _state_return() -> void:
	if detection.player != null and detection.has_line_of_sight():
		_set_state(State.CHASE)
		return
	var vx := patrol.return_tick(self, _facing_right)
	if is_nan(vx):
		velocity.x = 0.0
		_set_state(State.IDLE)
		return
	velocity.x = vx
	_update_facing(float(sign(patrol.home_position.x - global_position.x)))

func _state_chase() -> void:
	var player := detection.player
	if player == null:
		_set_state(State.RETURN)
		return
	if not detection.has_line_of_sight() and not detection.has_memory():
		_set_state(State.RETURN)
		return

	var dist      = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	if combat.should_attack(dist, player):
		_set_state(State.ATTACK)
		return

	velocity.x = combat.chase_velocity(dist, direction, velocity.x)
	_update_facing(combat.chase_facing(dist, direction.x))

func _state_attack_hold() -> void:
	velocity.x = combat.attack_hold_velocity(velocity.x)

# ─────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────
func _on_attack_finished() -> void:
	if current_state == State.ATTACK:
		_set_state(State.CHASE if detection.player != null else State.RETURN)

func _on_damage_taken(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	enemy_hurt.emit(amount)
	if current_state == State.DEATH:
		return
	if current_health <= 0.0:
		_set_state(State.DEATH)
	elif current_state != State.HURT:
		_set_state(State.HURT)

func _on_died() -> void:
	enemy_died.emit()

func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		_set_state(State.CHASE if (detection.player != null and detection.has_line_of_sight()) else State.RETURN)

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

func get_health_ratio() -> float:
	return current_health / max_health

func apply_spell_hit(spell: SpellData, direction: Vector2) -> void:
	hitbox.receive_hit(spell, direction)

func consume_spell_mana(amount: float) -> bool:
	if not is_finite(amount) or amount < 0 or spell_mana < amount:
		return false
	spell_mana -= amount
	return true
func restore_spell_mana(amount: float) -> void:
	spell_mana += amount
