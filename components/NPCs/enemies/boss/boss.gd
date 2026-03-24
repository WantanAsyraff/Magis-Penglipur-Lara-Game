# Boss.gd
# Framework for a multi-phase boss with weighted random attack selection.
# Requires: HitboxComponent, AnimatedSprite2D, CollisionShape2D,
#           DetectionArea (Area2D), RayCast2D, AttackTimer (Timer), HurtTimer (Timer)
#
# HOW TO SET UP:
#   1. Create BossAttackData .tres files for each attack.
#   2. Create BossPhaseData .tres files for each phase.
#      - Phase 1: enter_at_health_ratio = 1.0
#      - Phase 2: enter_at_health_ratio = 0.6  (enters at 60% HP)
#      - Phase 3: enter_at_health_ratio = 0.3  (enters at 30% HP)
#   3. Assign phases array in order (phase 1 first) in the inspector.

class_name Boss
extends CharacterBody2D

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal boss_died()
signal boss_hurt(amount: float)
signal phase_changed(phase_index: int, phase_data: BossPhaseData)
signal attack_started(attack: BossAttackData)
signal attack_finished(attack: BossAttackData)

# ─────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────
enum State { IDLE, CHASE, ATTACK, HURT, PHASE_TRANSITION, DEATH }

# ─────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────
@export_group("Identity")
@export var boss_name: String = "Boss"

# ─────────────────────────────────────────
# STATS
# ─────────────────────────────────────────
@export_group("Stats")
@export var max_health: float = 500.0
@export var hurt_duration: float = 0.3
@export var damage_reduction: float = 0.0
@export var damage_multiplier: float = 1.0
@export var receives_status_effects: bool = true

# ─────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────
@export_group("Detection")
@export var detection_radius: float = 300.0
@export var sight_memory: float = 3.0

# ─────────────────────────────────────────
# PHASES
# ─────────────────────────────────────────
@export_group("Phases")
## Assign phases in order. First phase enter_at_health_ratio should be 1.0.
@export var phases: Array[BossPhaseData] = []

# ─────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var raycast: RayCast2D = $RayCast2D
@onready var attack_timer: Timer = $AttackTimer
@onready var hurt_timer: Timer = $HurtTimer

# ─────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────
var current_state: State = State.IDLE
var current_health: float = 0.0
var current_phase_index: int = 0
var current_phase: BossPhaseData = null
var current_attack: BossAttackData = null

var _player: Node = null
var _can_attack: bool = true
var _sight_memory_timer: float = 0.0
var _facing_right: bool = true
var _is_invincible: bool = false

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	assert(phases.size() > 0, "Boss needs at least one BossPhaseData assigned!")
	current_health = max_health

	hitbox.receives_status_effects = receives_status_effects
	hitbox.has_mana = false
	hitbox.receives_knockback = false  # Bosses typically don't get knocked back
	hitbox.damage_reduction = damage_reduction
	hitbox.damage_multiplier = damage_multiplier
	hitbox.damage_taken.connect(_on_damage_taken)

	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	_enter_phase(0)
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
	_on_state_entered(new_state)

func _on_state_entered(state: State) -> void:
	match state:
		State.IDLE:
			_play_animation("idle")
		State.CHASE:
			_play_animation("walk")
		State.ATTACK:
			_play_animation("attack")
			_execute_current_attack()
		State.HURT:
			_play_animation("hurt")
			hurt_timer.wait_time = hurt_duration
			hurt_timer.start()
		State.PHASE_TRANSITION:
			_play_animation(current_phase.transition_animation if current_phase.transition_animation != "" else "idle")
		State.DEATH:
			_on_death()

func _run_state(delta: float) -> void:
	match current_state:
		State.IDLE:         _state_idle()
		State.CHASE:        _state_chase()
		State.ATTACK:       _state_attack_hold()
		State.HURT:         pass
		State.PHASE_TRANSITION: pass
		State.DEATH:        pass

# ─────────────────────────────────────────
# STATES
# ─────────────────────────────────────────
func _state_idle() -> void:
	velocity.x = move_toward(velocity.x, 0, current_phase.move_speed if current_phase else 80.0)
	if _player != null:
		_set_state(State.CHASE)

func _state_chase() -> void:
	if _player == null:
		_set_state(State.IDLE)
		return
	if not _has_line_of_sight() and _sight_memory_timer <= 0.0:
		_set_state(State.IDLE)
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity.x = direction.x * current_phase.chase_speed
	_update_facing(direction.x)

	if _can_attack and current_phase and current_phase.attacks.size() > 0:
		var dist := global_position.distance_to(_player.global_position)
		var chosen := _pick_attack_in_range(dist)
		print("[Boss] Chase dist: %.1f | can_attack: %s | chosen: %s" % [dist, _can_attack, chosen.attack_name if chosen else "none"])
		if chosen:
			current_attack = chosen
			_set_state(State.ATTACK)

func _state_attack_hold() -> void:
	# Melee dash keeps momentum — others hold position
	if current_attack and current_attack.kind == BossAttackData.AttackKind.MELEE_DASH:
		pass
	else:
		velocity.x = move_toward(velocity.x, 0, current_phase.chase_speed if current_phase else 160.0)

# ─────────────────────────────────────────
# PHASE MANAGEMENT
# ─────────────────────────────────────────
func _enter_phase(index: int) -> void:
	if index >= phases.size():
		return
	current_phase_index = index
	current_phase = phases[index]
	phase_changed.emit(index, current_phase)
	print("[Boss] Entering phase %d: %s" % [index, current_phase.phase_name])

func _check_phase_transition() -> void:
	# Walk through phases in order — find the deepest phase we qualify for
	var health_ratio := current_health / max_health
	var target_phase := current_phase_index

	for i in range(phases.size()):
		if health_ratio <= phases[i].enter_at_health_ratio and i > current_phase_index:
			target_phase = i

	if target_phase != current_phase_index:
		_trigger_phase_transition(target_phase)

func _trigger_phase_transition(new_index: int) -> void:
	_set_state(State.PHASE_TRANSITION)
	_enter_phase(new_index)

	if current_phase.invincible_on_transition:
		_is_invincible = true
		await get_tree().create_timer(current_phase.transition_invincible_duration).timeout
		_is_invincible = false

	if current_phase.transition_animation != "":
		_play_animation(current_phase.transition_animation)
		await sprite.animation_finished

	if _player != null:
		_set_state(State.CHASE)
	else:
		_set_state(State.IDLE)

# ─────────────────────────────────────────
# ATTACK SELECTION — WEIGHTED RANDOM
# ─────────────────────────────────────────
func _pick_attack() -> BossAttackData:
	if current_phase == null or current_phase.attacks.is_empty():
		return null

	var total_weight: float = 0.0
	for atk in current_phase.attacks:
		total_weight += atk.weight

	var roll := randf() * total_weight
	var cumulative: float = 0.0
	for atk in current_phase.attacks:
		cumulative += atk.weight
		if roll <= cumulative:
			return atk

	return current_phase.attacks[-1]

# Only considers attacks whose range is satisfied by current distance.
# Falls back to any available attack if nothing in range (e.g. ranged attacks have no range gate).
func _pick_attack_in_range(dist: float) -> BossAttackData:
	if current_phase == null or current_phase.attacks.is_empty():
		return null

	# Filter to attacks valid at this distance
	var valid: Array[BossAttackData] = []
	for atk in current_phase.attacks:
		match atk.kind:
			BossAttackData.AttackKind.MELEE_SLAM:
				if dist <= atk.melee_range:
					valid.append(atk)
			BossAttackData.AttackKind.MELEE_DASH:
				# Dash can trigger from further away — use ranged_trigger if set, else melee_range * 3
				var dash_trigger := atk.melee_range * 3.0
				if dist <= dash_trigger:
					valid.append(atk)
			BossAttackData.AttackKind.RANGED_BURST:
				# Ranged has no minimum distance gate — always valid
				valid.append(atk)
			BossAttackData.AttackKind.AOE_SLAM:
				if dist <= atk.aoe_radius * 1.5:
					valid.append(atk)
			BossAttackData.AttackKind.SUMMON:
				# Summon always valid
				valid.append(atk)

	if valid.is_empty():
		return null

	# Weighted random over valid pool only
	var total_weight: float = 0.0
	for atk in valid:
		total_weight += atk.weight

	var roll := randf() * total_weight
	var cumulative: float = 0.0
	for atk in valid:
		cumulative += atk.weight
		if roll <= cumulative:
			return atk

	return valid[-1]

# ─────────────────────────────────────────
# ATTACK EXECUTION
# ─────────────────────────────────────────
func _execute_current_attack() -> void:
	if current_attack == null or _player == null:
		_set_state(State.CHASE)
		return

	_can_attack = false
	attack_started.emit(current_attack)
	print("[Boss] Executing: %s | kind: %s" % [current_attack.attack_name, BossAttackData.AttackKind.keys()[current_attack.kind]])

	match current_attack.kind:
		BossAttackData.AttackKind.MELEE_SLAM:
			await _do_melee_slam()
		BossAttackData.AttackKind.MELEE_DASH:
			await _do_melee_dash()
		BossAttackData.AttackKind.RANGED_BURST:
			await _do_ranged_burst()
		BossAttackData.AttackKind.AOE_SLAM:
			await _do_aoe_slam()
		BossAttackData.AttackKind.SUMMON:
			await _do_summon()

	print("[Boss] Attack finished: ", current_attack.attack_name)
	attack_finished.emit(current_attack)
	attack_timer.wait_time = current_attack.cooldown
	attack_timer.start()

# ─────────────────────────────────────────
# ATTACK IMPLEMENTATIONS
# ─────────────────────────────────────────
func _do_melee_slam() -> void:
	await get_tree().create_timer(current_attack.windup).timeout
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= current_attack.melee_range:
		var player_hitbox := _player.get_node_or_null("HitboxComponent") as HitboxComponent
		if player_hitbox:
			var dir: Vector2 = (_player.global_position - global_position).normalized()
			var fake_spell := SpellData.new()
			fake_spell.projectile_damage = current_attack.melee_damage
			fake_spell.knockback_force = 200.0
			player_hitbox.receive_hit(fake_spell, dir)
			print("[Boss] Melee slam hit for: ", current_attack.melee_damage)

func _do_melee_dash() -> void:
	if _player == null:
		return
	var dash_dir: Vector2 = (_player.global_position - global_position).normalized()
	var dash_speed := current_phase.chase_speed * current_attack.dash_speed_multiplier
	var elapsed := 0.0

	while elapsed < current_attack.dash_duration:
		velocity.x = dash_dir.x * dash_speed
		velocity.y = dash_dir.y * dash_speed * 0.3
		elapsed += get_physics_process_delta_time()
		await get_tree().physics_frame

	velocity = Vector2.ZERO

	if _player != null:
		var dist := global_position.distance_to(_player.global_position)
		if dist <= current_attack.melee_range * 1.5:
			var player_hitbox := _player.get_node_or_null("HitboxComponent") as HitboxComponent
			if player_hitbox:
				var dir: Vector2 = (_player.global_position - global_position).normalized()
				var fake_spell := SpellData.new()
				fake_spell.projectile_damage = current_attack.melee_damage
				fake_spell.knockback_force = 350.0
				player_hitbox.receive_hit(fake_spell, dir)
				print("[Boss] Dash hit for: ", current_attack.melee_damage)

func _do_ranged_burst() -> void:
	if current_attack.ranged_spell == null or _player == null:
		push_warning("Boss ranged burst: no ranged_spell assigned on attack: " + current_attack.attack_name)
		return

	await get_tree().create_timer(current_attack.windup).timeout

	var base_dir: Vector2 = (_player.global_position - global_position).normalized()
	var count := current_attack.burst_count
	var spread := current_attack.burst_spread

	for i in count:
		if _player == null:
			break
		var angle_offset := 0.0
		if count > 1:
			angle_offset = deg_to_rad(-spread / 2.0 + (spread / (count - 1)) * i)
		var fire_dir: Vector2 = base_dir.rotated(angle_offset)

		var scene_to_use: PackedScene = current_attack.ranged_spell.spell_scene if current_attack.ranged_spell.spell_scene \
			else preload("res://components/projectiles/magis-projectile.tscn")
		var inst = scene_to_use.instantiate()
		inst.spell_data = current_attack.ranged_spell
		inst.source = self
		inst.position = global_position + fire_dir * 60.0
		inst.direction = fire_dir
		get_parent().add_child(inst)

		if i < count - 1:
			await get_tree().create_timer(current_attack.burst_interval).timeout

func _do_aoe_slam() -> void:
	print("[Boss] AOE warning — ", current_attack.aoe_warning_duration, "s")
	await get_tree().create_timer(current_attack.aoe_warning_duration).timeout

	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = current_attack.aoe_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)

	var results := space.intersect_shape(query)
	for result in results:
		var body: Node2D = result.collider
		if body == self:
			continue
		if body.is_in_group("player"):
			var player_hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
			if player_hitbox:
				var dir: Vector2 = (body.global_position - global_position).normalized()
				var fake_spell := SpellData.new()
				fake_spell.projectile_damage = current_attack.aoe_damage
				fake_spell.knockback_force = current_attack.aoe_knockback
				player_hitbox.receive_hit(fake_spell, dir)
				print("[Boss] AOE hit player for: ", current_attack.aoe_damage)

func _do_summon() -> void:
	if current_attack.minion_scene == null:
		push_warning("Boss summon: no minion_scene assigned on attack: " + current_attack.attack_name)
		return

	await get_tree().create_timer(current_attack.windup).timeout

	for i in current_attack.minion_count:
		var angle := (TAU / current_attack.minion_count) * i
		var offset := Vector2(cos(angle), sin(angle)) * current_attack.spawn_radius
		var minion = current_attack.minion_scene.instantiate()
		minion.global_position = global_position + offset
		get_parent().add_child(minion)
		print("[Boss] Spawned minion at: ", minion.global_position)

# ─────────────────────────────────────────
# DEATH
# ─────────────────────────────────────────
func _on_death() -> void:
	boss_died.emit()
	hitbox.clear_all_effects()
	set_physics_process(false)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()

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
		pass

# ─────────────────────────────────────────
# HITBOX CALLBACKS
# ─────────────────────────────────────────
func _on_damage_taken(amount: float) -> void:
	if _is_invincible:
		return
	current_health = maxf(current_health - amount, 0.0)
	boss_hurt.emit(amount)
	print("[Boss] Took %.1f damage — HP: %.1f/%.1f" % [amount, current_health, max_health])

	if current_health <= 0.0:
		if current_state != State.DEATH:
			_set_state(State.DEATH)
		return

	_check_phase_transition()

	if current_state != State.HURT and current_state != State.PHASE_TRANSITION and current_state != State.DEATH:
		_set_state(State.HURT)

# ─────────────────────────────────────────
# TIMER CALLBACKS
# ─────────────────────────────────────────
func _on_attack_timer_timeout() -> void:
	_can_attack = true
	if current_state == State.ATTACK:
		if _player != null:
			_set_state(State.CHASE)
		else:
			_set_state(State.IDLE)

func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		if _player != null:
			_set_state(State.CHASE)
		else:
			_set_state(State.IDLE)

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
	if not _is_invincible:
		hitbox.receive_hit(spell, direction)
