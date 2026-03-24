# EnemyCombat.gd
# Attach as a child node of Enemy.
# No Timer node needed — cooldown is tracked with a float, same pattern as EnemyPatrol.
# Call tick(delta) from Enemy._physics_process every frame.
#
# Requires a RayCast2D named "RayCast2D(Aim)" marked unique (%) under Enemy.
# It is temporarily aimed at the player before each ranged shot to confirm LoS.

class_name EnemyCombat
extends Node

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal attack_finished   # fired when cooldown ends — Enemy uses this to return to CHASE

# ─────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────
@export var attack_type: Enemy.AttackType = Enemy.AttackType.MELEE
@export var melee_damage: float = 15.0
@export var attack_cooldown: float = 1.2
@export var melee_range: float = 40.0
@export var ranged_trigger_distance: float = 200.0
@export var retreat_threshold: float = 80.0
@export var ranged_spell: SpellData = null

# ─────────────────────────────────────────
# NODE REFS
# ─────────────────────────────────────────
## Sibling under Enemy — mark unique (%) in the scene tree.
## Any target_position in the editor is fine; code overrides it at runtime.
@onready var raycast_aim: RayCast2D = %"RayCast2D(Aim)"

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var can_attack: bool = true
var _cooldown_timer: float = 0.0

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────

## Call from Enemy._physics_process every frame.
func tick(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			can_attack = true
			attack_finished.emit()

# ─────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────

## Returns true if the enemy should enter ATTACK state given current distance.
func should_attack(dist: float, player: Node) -> bool:
	if not can_attack or player == null:
		return false
	match attack_type:
		Enemy.AttackType.MELEE:
			return dist <= melee_range
		Enemy.AttackType.RANGED:
			return dist <= ranged_trigger_distance and dist > retreat_threshold
		Enemy.AttackType.BOTH:
			if dist <= melee_range:
				return true
			return ranged_spell != null and dist <= ranged_trigger_distance and dist > retreat_threshold
	return false

## Fire the attack. Call once from Enemy when entering ATTACK state.
func execute_attack(enemy: CharacterBody2D, player: Node) -> void:
	if player == null:
		return
	can_attack = false
	_cooldown_timer = attack_cooldown

	var dist := enemy.global_position.distance_to(player.global_position)
	print("[EnemyCombat] Attack — type: %s | dist: %.1f" % [Enemy.AttackType.keys()[attack_type], dist])

	match attack_type:
		Enemy.AttackType.MELEE:
			_do_melee(enemy, player)
		Enemy.AttackType.RANGED:
			_do_ranged(enemy, player)
		Enemy.AttackType.BOTH:
			if dist <= melee_range:
				_do_melee(enemy, player)
			elif ranged_spell != null and dist <= ranged_trigger_distance:
				_do_ranged(enemy, player)

## Desired velocity.x while holding the ATTACK state (no re-firing).
func attack_hold_velocity(current_vx: float) -> float:
	match attack_type:
		Enemy.AttackType.RANGED, Enemy.AttackType.BOTH:
			return move_toward(current_vx, 0.0, get_parent().chase_speed)
		_:
			return current_vx  # melee keeps momentum

## Chase-state movement velocity given current distance and direction to player.
func chase_velocity(dist: float, direction: Vector2, current_vx: float) -> float:
	var spd: float = get_parent().chase_speed
	match attack_type:
		Enemy.AttackType.MELEE:
			return direction.x * spd
		Enemy.AttackType.RANGED, Enemy.AttackType.BOTH:
			if dist < retreat_threshold:
				return -direction.x * spd
			elif dist > ranged_trigger_distance:
				return direction.x * spd
			else:
				return move_toward(current_vx, 0.0, spd)
	return 0.0

## Facing direction to use during chase (-1/1). Handles retreat flip.
func chase_facing(dist: float, direction_x: float) -> float:
	match attack_type:
		Enemy.AttackType.RANGED, Enemy.AttackType.BOTH:
			if dist < retreat_threshold:
				return -direction_x
	return direction_x

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────
func _do_melee(enemy: CharacterBody2D, player: Node) -> void:
	var player_hitbox := player.get_node_or_null("HitboxComponent") as HitboxComponent
	if player_hitbox == null:
		push_warning("EnemyCombat: Player has no HitboxComponent!")
		return
	var dir = (player.global_position - enemy.global_position).normalized()
	var fake_spell := SpellData.new()
	fake_spell.projectile_damage = melee_damage
	fake_spell.knockback_force = 120.0
	player_hitbox.receive_hit(fake_spell, dir)
	print("[EnemyCombat] Melee hit for: ", melee_damage)

func _do_ranged(enemy: CharacterBody2D, player: Node) -> void:
	if ranged_spell == null:
		return

	# Confirm clear LoS before firing — don't shoot into a wall
	if not _has_ranged_los(enemy, player):
		print("[EnemyCombat] Ranged blocked — no LoS to player")
		return

	var dir = (player.global_position - enemy.global_position).normalized()
	var scene_to_use: PackedScene = ranged_spell.spell_scene if ranged_spell.spell_scene \
		else preload("res://components/projectiles/magis-projectile.tscn")
	var inst = scene_to_use.instantiate()
	inst.spell_data = ranged_spell
	inst.source = enemy
	inst.position = enemy.global_position + dir * 40.0
	inst.direction = dir
	enemy.get_parent().add_child(inst)

## Aims RayCast2D(Aim) at the player and checks for an unobstructed path.
func _has_ranged_los(enemy: CharacterBody2D, player: Node) -> bool:
	raycast_aim.target_position = enemy.to_local(player.global_position)
	raycast_aim.force_raycast_update()
	return not raycast_aim.is_colliding() or raycast_aim.get_collider() == player
