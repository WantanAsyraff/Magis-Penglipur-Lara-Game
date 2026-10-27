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
@export var spell_mana: float = 400
var casting: SpellCastingComponent
var perception: EnemyDetection
var _attack_epoch: int = 0
var _transition_epoch: int = 0
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
	set_meta("spell_team", &"enemy")
	set_meta("faction_id", &"enemy")
	casting = SpellCastingComponent.new()
	add_child(casting)
	perception = EnemyDetection.new()
	add_child(perception)
	var perception_data := EnemyPerceptionData.new()
	perception_data.detection_range = detection_radius
	perception_data.sight_memory = sight_memory
	perception.configure(perception_data)
	perception.connect_area(detection_area)

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
	if not SpellExecutor.is_authoritative(self) or current_state == State.DEATH: return
	perception.tick(delta)
	_player = perception.player
	if hitbox.is_stunned():
		if current_attack: _attack_epoch += 1; current_attack = null; _can_attack = true
		casting.cancel("Boss stunned")
		velocity.x = 0
		_apply_gravity(delta)
		move_and_slide()
		return
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
	if is_instance_valid(_player):
		_set_state(State.CHASE)

func _state_chase() -> void:
	if not is_instance_valid(_player):
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
	hitbox.damage_reduction = current_phase.defense if current_phase.defense >= 0 else damage_reduction
	hitbox.damage_multiplier = current_phase.incoming_multiplier if current_phase.incoming_multiplier >= 0 else damage_multiplier
	hitbox.status_resistances = current_phase.status_resistances.duplicate()
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
	_attack_epoch += 1
	_transition_epoch += 1
	var token := _transition_epoch
	casting.cancel("Phase transition")
	current_attack = null
	_can_attack = true
	_set_state(State.PHASE_TRANSITION)
	_enter_phase(new_index)
	var phase := current_phase
	if phase.invincible_on_transition:
		_is_invincible = true
		hitbox.set_invincible(true)
		await get_tree().create_timer(maxf(phase.transition_invincible_duration, 0.01)).timeout
		if token != _transition_epoch or current_state == State.DEATH: return
		_is_invincible = false
		hitbox.set_invincible(false)
	if phase.transition_animation != "" and sprite.sprite_frames and sprite.sprite_frames.has_animation(phase.transition_animation):
		_play_animation(phase.transition_animation)
		# Bounded wait also handles inherited looping animations.
		await get_tree().create_timer(0.5).timeout
		if token != _transition_epoch or current_state == State.DEATH: return
	_set_state(State.CHASE if is_instance_valid(_player) else State.IDLE)

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
	if current_attack == null or not is_instance_valid(_player) or not SpellExecutor.is_authoritative(self):
		_set_state(State.CHASE); return
	_can_attack = false
	_attack_epoch += 1
	var token := _attack_epoch
	var attack := current_attack
	attack_started.emit(attack)
	SpellFeedback.flash(self, Color(1, 0.3, .2))
	match attack.kind:
		BossAttackData.AttackKind.MELEE_SLAM: await _do_melee_slam()
		BossAttackData.AttackKind.MELEE_DASH: await _do_melee_dash()
		BossAttackData.AttackKind.RANGED_BURST: await _do_ranged_burst()
		BossAttackData.AttackKind.AOE_SLAM: await _do_aoe_slam()
		BossAttackData.AttackKind.SUMMON: await _do_summon()
	if not _attack_valid(token): return
	attack_finished.emit(attack)
	attack_timer.start(maxf(attack.cooldown, 0.05))

# ─────────────────────────────────────────
# ATTACK IMPLEMENTATIONS
# ─────────────────────────────────────────
func _do_melee_slam() -> void:
	var attack := current_attack
	var token := _attack_epoch
	await get_tree().create_timer(maxf(attack.windup, .01)).timeout
	if not _attack_valid(token): return
	if not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= attack.melee_range:
		var player_hitbox := _player.get_node_or_null("HitboxComponent") as HitboxComponent
		if player_hitbox:
			var dir: Vector2 = (_player.global_position - global_position).normalized()
			CombatRequest.strike(self, _player, attack.melee_damage, 200)
			print("[Boss] Melee slam hit for: ", attack.melee_damage)

func _do_melee_dash() -> void:
	var attack := current_attack
	var token := _attack_epoch
	if not is_instance_valid(_player):
		return
	var dash_dir: Vector2 = (_player.global_position - global_position).normalized()
	var dash_speed := current_phase.chase_speed * attack.dash_speed_multiplier
	var elapsed := 0.0

	while elapsed < attack.dash_duration:
		if not _attack_valid(token): return
		velocity.x = dash_dir.x * dash_speed
		velocity.y = dash_dir.y * dash_speed * 0.3
		elapsed += get_physics_process_delta_time()
		await get_tree().physics_frame

	velocity = Vector2.ZERO

	if is_instance_valid(_player):
		var dist := global_position.distance_to(_player.global_position)
		if dist <= attack.melee_range * 1.5:
			var player_hitbox := _player.get_node_or_null("HitboxComponent") as HitboxComponent
			if player_hitbox:
				var dir: Vector2 = (_player.global_position - global_position).normalized()
				CombatRequest.strike(self, _player, attack.melee_damage, 350)
				print("[Boss] Dash hit for: ", attack.melee_damage)

func _do_ranged_burst() -> void:
	var attack := current_attack
	var token := _attack_epoch
	if attack.ranged_spell == null: return
	await get_tree().create_timer(maxf(attack.windup, .01)).timeout
	if not _attack_valid(token) or not is_instance_valid(_player): return
	var definition := attack.ranged_spell.duplicate() as SpellData
	definition.cast_time = 0 # BossAttackData owns the windup for the projectile burst.
	var count := clampi(attack.burst_count, 1, 32)
	definition.upfront_cost = ceili(float(definition.upfront_cost) / count)
	for i in count:
		if not _attack_valid(token) or not is_instance_valid(_player): return
		var heading: Vector2 = (_player.global_position - global_position).normalized()
		if count > 1: heading = heading.rotated(deg_to_rad(-attack.burst_spread / 2 + attack.burst_spread * i / (count - 1)))
		var targets: Array[Node2D] = [_player]
		if not casting.request_cast(definition, global_position + heading * 60, heading, targets): return
		if i < count - 1: await get_tree().create_timer(maxf(attack.burst_interval, .01)).timeout

func _do_aoe_slam() -> void:
	var attack := current_attack
	var token := _attack_epoch
	print("[Boss] AOE warning — ", attack.aoe_warning_duration, "s")
	await get_tree().create_timer(maxf(attack.aoe_warning_duration, .01)).timeout
	if not _attack_valid(token): return

	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = attack.aoe_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)

	var results := space.intersect_shape(query)
	for result in results:
		var body: Node2D = result.collider
		if body == self:
			continue
		if CombatFactions.relation(self, body) < 0:
			var player_hitbox := body.get_node_or_null("HitboxComponent") as HitboxComponent
			if player_hitbox:
				var dir: Vector2 = (body.global_position - global_position).normalized()
				CombatRequest.strike(self, body, attack.aoe_damage, attack.aoe_knockback)
				print("[Boss] AOE hit player for: ", attack.aoe_damage)

func _do_summon() -> void:
	var attack := current_attack
	var token := _attack_epoch
	if attack.minion_scene == null:
		push_warning("Boss summon: no minion_scene assigned on attack: " + attack.attack_name)
		return

	await get_tree().create_timer(maxf(attack.windup, .01)).timeout
	if not _attack_valid(token): return

	for i in mini(attack.minion_count, 12):
		if not _attack_valid(token) or _owned_minions() >= 12: break
		var angle := (TAU / attack.minion_count) * i
		var offset := Vector2(cos(angle), sin(angle)) * attack.spawn_radius
		var minion = attack.minion_scene.instantiate()
		if not minion is Node2D: minion.free(); continue
		minion.position = get_parent().to_local(global_position + offset)
		CombatLifecycle.own(minion, self)
		get_parent().add_child(minion)
		print("[Boss] Spawned minion at: ", minion.global_position)

# ─────────────────────────────────────────
# DEATH
# ─────────────────────────────────────────
func _on_death() -> void:
	if get_meta("combat_dead", false) or not SpellExecutor.is_authoritative(self): return
	set_meta("combat_dead", true)
	_attack_epoch += 1
	_transition_epoch += 1
	casting.cancel("Boss died")
	attack_timer.stop()
	hurt_timer.stop()
	CombatLifecycle.cleanup(self)
	boss_died.emit()
	hitbox.clear_all_effects()
	set_physics_process(false)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await get_tree().create_timer(.5).timeout
	queue_free()

# ─────────────────────────────────────────
# DETECTION & SIGHT
# ─────────────────────────────────────────
func _has_line_of_sight() -> bool:
	return perception.has_line_of_sight()

func _legacy_line_of_sight() -> bool:
	if not is_instance_valid(_player):
		return false
	raycast.target_position = to_local(_player.global_position)
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		return true
	return raycast.get_collider() == _player

func _update_sight_memory(delta: float) -> void:
	if is_instance_valid(_player) and _has_line_of_sight():
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
	if not SpellExecutor.is_authoritative(self) or current_state == State.DEATH or _is_invincible or amount <= 0:
		return
	_attack_epoch += 1
	_can_attack = true
	casting.cancel("Boss interrupted by damage")
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
		if is_instance_valid(_player):
			_set_state(State.CHASE)
		else:
			_set_state(State.IDLE)

func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		if is_instance_valid(_player):
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

func _attack_valid(token: int) -> bool:
	return SpellExecutor.is_authoritative(self) and token == _attack_epoch and current_state != State.DEATH and not hitbox.is_stunned()
func _owned_minions() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("combat_owned"):
		if node.get_meta("combat_owner", null) == self and node is Enemy and not node.is_queued_for_deletion(): count += 1
	return count
func consume_spell_mana(amount: float) -> bool:
	if not is_finite(amount) or amount < 0 or amount > spell_mana: return false
	spell_mana -= amount
	return true
func restore_spell_mana(amount: float) -> void:
	spell_mana += maxf(amount, 0)
func _exit_tree() -> void:
	CombatLifecycle.cleanup(self)
