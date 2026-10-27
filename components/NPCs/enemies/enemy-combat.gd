class_name EnemyCombat extends Node
signal attack_finished
signal ability_started(ability: EnemyAbilityData)
signal ability_completed(ability: EnemyAbilityData)
# Legacy scene exports remain for EnemyDefinitionAdapter and existing inherited scenes.
@export var attack_type: Enemy.AttackType = Enemy.AttackType.MELEE
@export var melee_damage: float = 15
@export var attack_cooldown: float = 1.2
@export var melee_range: float = 40
@export var ranged_trigger_distance: float = 200
@export var retreat_threshold: float = 80
@export var ranged_spell: SpellData
var casting: SpellCastingComponent
var loadout: Array[EnemyAbilityData] = []
var cooldowns: Dictionary = {}
var can_attack: bool = true
var pending: EnemyAbilityData
var current: EnemyAbilityData
var victim: Node2D
var remaining: float = 0
var recovery: float = 0
var cooldown_multiplier: float = 1
func configure(data: EnemyData) -> void:
	loadout = data.abilities.duplicate()
	cooldown_multiplier = data.cooldown_multiplier
	casting = SpellCastingComponent.new()
	casting.name = "SpellCastingComponent"
	get_parent().add_child(casting)
	casting.cast_completed.connect(_spell_completed)
	casting.cast_failed.connect(_spell_failed)
func busy() -> bool:
	return pending != null or recovery > 0 or (casting != null and casting.state != SpellCastingComponent.State.IDLE)
func tick(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	for key in cooldowns.keys(): cooldowns[key] = maxf(0, float(cooldowns[key]) - delta)
	var enemy := get_parent()
	if enemy.hitbox.is_stunned() or (enemy.hitbox.is_silenced() and pending and pending.kind == EnemyAbilityData.Kind.SPELL):
		cancel("Status interruption")
	if recovery > 0:
		recovery -= delta
		if recovery <= 0: attack_finished.emit()
	if pending:
		remaining -= delta
		if remaining <= 0: _release()
	can_attack = not busy()
func target_for(ability: EnemyAbilityData, hostile: Node2D) -> Node2D:
	var enemy := get_parent() as Node2D
	if ability.kind == EnemyAbilityData.Kind.MELEE: return hostile
	if LegacySpellAdapter.delivery_for(ability.spell) == SpellData.Delivery.SELF: return enemy
	if ability.spell.targeting == SpellData.Targeting.ALLIES:
		var best: Node2D
		var ratio := 1.0
		for node in get_tree().get_nodes_in_group("combat_target"):
			if node is Node2D and not node.get_meta("combat_dead", false) and CombatFactions.relation(enemy, node) > 0 and node.has_method("get_health_ratio") and node.get_health_ratio() < ratio and enemy.global_position.distance_to(node.global_position) <= ability.max_range:
				best = node; ratio = node.get_health_ratio()
		return best
	return hostile
func can_use(ability: EnemyAbilityData, target: Node2D, check_busy: bool = true) -> bool:
	var enemy := get_parent() as Node2D
	if not SpellExecutor.is_authoritative(enemy) or ability not in loadout or enemy.get_meta("combat_dead", false) or enemy.current_state == Enemy.State.HURT or enemy.hitbox.is_stunned() or (check_busy and busy()): return false
	if cooldowns.get(ability.ability_id, 0.0) > 0 and check_busy: return false
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.get_meta("combat_dead", false): return false
	if target != enemy:
		var distance := enemy.global_position.distance_to(target.global_position)
		if distance < ability.min_range or distance > ability.max_range: return false
		if ability.requires_los and not _has_ranged_los(enemy, target): return false
	if ability.kind == EnemyAbilityData.Kind.SPELL:
		if enemy.hitbox.is_silenced(): return false
		var spell := ability.spell
		if spell == null or (casting.cooldowns.get(spell.spell_id, 0.0) > 0 and check_busy): return false
		if enemy.spell_mana < spell.upfront_cost + spell.mana_per_second * spell.channel_duration: return false
		if target != enemy and not SpellDelivery.can_target(SpellCastContext.new(enemy, spell), target): return false
	else:
		if CombatFactions.relation(enemy, target) >= 0: return false
	return true
func start(ability: EnemyAbilityData, target: Node2D) -> bool:
	if not can_use(ability, target): return false
	pending = ability
	current = ability
	victim = target
	remaining = ability.windup
	cooldowns[ability.ability_id] = ability.cooldown * cooldown_multiplier
	can_attack = false
	get_parent()._set_state(Enemy.State.ATTACK)
	SpellFeedback.flash(get_parent(), Color(1, .6, .25))
	ability_started.emit(ability)
	if remaining <= 0: _release()
	return true
func _release() -> void:
	var ability := pending
	pending = null
	if ability == null or not can_use(ability, victim, false): _finish(); return
	var enemy := get_parent() as Node2D
	var direction := (victim.global_position - enemy.global_position).normalized()
	if direction == Vector2.ZERO: direction = Vector2.RIGHT if enemy._facing_right else Vector2.LEFT
	if ability.kind == EnemyAbilityData.Kind.MELEE:
		CombatRequest.apply(enemy, victim, ability.effects, direction)
		ability_completed.emit(ability)
		_finish()
	else:
		var targets: Array[Node2D] = [victim]
		if not casting.request_cast(ability.spell, enemy.global_position + direction * 40, direction, targets): _finish()
func _spell_completed(_context: SpellCastContext) -> void:
	if current: ability_completed.emit(current)
	_finish()
func _spell_failed(_reason: String) -> void:
	_finish()
func _finish() -> void:
	recovery = current.recovery if current else 0
	current = null
	victim = null
	if recovery <= 0: attack_finished.emit()
func cancel(reason: String = "Interrupted") -> void:
	pending = null
	current = null
	victim = null
	recovery = 0
	if casting: casting.cancel(reason)
func should_attack(_dist: float, target: Node) -> bool:
	for ability in loadout:
		if can_use(ability, target as Node2D): return true
	return false
func execute_attack(_enemy: CharacterBody2D, target: Node) -> void:
	for ability in loadout:
		if start(ability, target as Node2D): return
func attack_hold_velocity(current_vx: float) -> float:
	return move_toward(current_vx, 0, get_parent().chase_speed)
func chase_velocity(distance: float, direction: Vector2, _current_vx: float) -> float:
	return direction.x * get_parent().chase_speed * (-1 if distance < retreat_threshold else 1)
func chase_facing(_distance: float, direction_x: float) -> float:
	return direction_x
func _has_ranged_los(enemy: CharacterBody2D, target: Node2D) -> bool:
	if not is_instance_valid(target): return false
	var query := PhysicsRayQueryParameters2D.create(enemy.global_position, target.global_position, 16, [enemy.get_rid()])
	return enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
