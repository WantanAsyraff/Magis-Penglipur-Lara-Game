class_name EnemyAIController extends Node
signal intent_changed(action_id: StringName)
var profile: EnemyAIProfile
var selected: EnemyAIAction
var scores: Dictionary = {}
var action_cooldowns: Dictionary = {}
var _until_decision: float = 0
var _commitment: float = 0
var decision_count: int = 0
func configure(value: EnemyAIProfile) -> void:
	profile = value
func tick(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	for key in action_cooldowns.keys(): action_cooldowns[key] = maxf(0, float(action_cooldowns[key]) - delta)
	_commitment = maxf(0, _commitment - delta)
	_until_decision -= delta
	if enemy.hitbox.is_stunned(): interrupt(); enemy.movement.intent = EnemyAIAction.Kind.IDLE; return
	if enemy.current_state in [Enemy.State.DEATH, Enemy.State.HURT] or enemy.combat.busy(): return
	if _until_decision > 0: return
	_until_decision = profile.decision_interval
	decide()
func interrupt() -> void:
	_commitment = 0
	_until_decision = 0
	selected = null
func decide() -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	var bb: Dictionary = enemy.detection.blackboard
	bb.health_ratio = enemy.get_health_ratio()
	bb.mana_ratio = enemy.spell_mana / maxf(enemy.stats.config.max_mana, 1)
	bb.recent_damage = enemy.stats.recently_received_damage
	bb.available_abilities = []
	for ability in enemy.combat.loadout:
		if enemy.combat.can_use(ability, enemy.combat.target_for(ability, enemy.detection.player)): bb.available_abilities.append(ability.ability_id)
	decision_count += 1
	var best: EnemyAIAction
	var best_score := -1.0
	scores.clear()
	for action in profile.actions:
		var score := score_action(action, bb)
		scores[action.action_id] = score
		if score > best_score: best = action; best_score = score
	if best == null or best_score <= 0: return
	if selected and selected != best and _commitment > 0 and float(scores.get(selected.action_id, 0)) > 0 and best_score < float(scores.get(selected.action_id, 0)) * (1 + profile.switch_margin): return
	if selected != best:
		selected = best
		_commitment = profile.commitment
		intent_changed.emit(best.action_id)
	bb.intent = best.action_id
	enemy.movement.intent = best.kind
	var ability := ability_for(best)
	if ability:
		if enemy.combat.start(ability, enemy.combat.target_for(ability, enemy.detection.player)):
			action_cooldowns[best.action_id] = best.cooldown
	else:
		var state := Enemy.State.CHASE
		if best.kind == EnemyAIAction.Kind.IDLE: state = Enemy.State.IDLE
		elif best.kind == EnemyAIAction.Kind.PATROL: state = Enemy.State.PATROL
		elif best.kind == EnemyAIAction.Kind.INVESTIGATE: state = Enemy.State.RETURN
		enemy._set_state(state)
func score_action(action: EnemyAIAction, bb: Dictionary) -> float:
	if action_cooldowns.get(action.action_id, 0.0) > 0: return 0
	var health: float = bb.get("health_ratio", 1)
	var mana: float = bb.get("mana_ratio", 1)
	if health > action.max_health_ratio or mana > action.max_mana_ratio: return 0
	var visible: bool = bb.get("visible", false)
	var distance: float = bb.get("distance", INF)
	var enemy := get_parent()
	var eligible := false
	match action.kind:
		EnemyAIAction.Kind.IDLE, EnemyAIAction.Kind.PATROL: eligible = not visible and not enemy.detection.has_memory()
		EnemyAIAction.Kind.INVESTIGATE: eligible = not visible and enemy.detection.has_memory()
		EnemyAIAction.Kind.CHASE: eligible = visible and distance > preferred_distance() + profile.range_tolerance
		EnemyAIAction.Kind.RETREAT: eligible = visible and distance < profile.retreat_range
		EnemyAIAction.Kind.MAINTAIN_RANGE: eligible = visible
		EnemyAIAction.Kind.REPOSITION: eligible = not visible and enemy.detection.has_memory()
		EnemyAIAction.Kind.FLEE: eligible = visible and health <= profile.flee_health_ratio
		EnemyAIAction.Kind.RECOVER:
			eligible = ability_for(action) != null or (mana < 0.3 and enemy.stats.config.mana_regen > 0)
		EnemyAIAction.Kind.DEFEND: eligible = visible and distance < profile.retreat_range * 1.5 and ability_for(action) != null
		_: eligible = ability_for(action) != null and (visible or action.kind == EnemyAIAction.Kind.SUMMON)
	if not eligible: return 0
	return action.utility * (1 + (1 - health) * action.low_health_weight + (1 - mana) * action.low_mana_weight + minf(bb.get("threat", 0) / 100.0, 1) * action.threat_weight)
func ability_for(action: EnemyAIAction) -> EnemyAbilityData:
	var enemy := get_parent()
	var best: EnemyAbilityData
	for ability in enemy.combat.loadout:
		if action.ability_id != &"" and action.ability_id != ability.ability_id: continue
		var fits := false
		match action.kind:
			EnemyAIAction.Kind.MELEE: fits = ability.kind == EnemyAbilityData.Kind.MELEE
			EnemyAIAction.Kind.RANGED: fits = ability.kind == EnemyAbilityData.Kind.SPELL and ability.role == EnemyAbilityData.Role.OFFENSE and LegacySpellAdapter.delivery_for(ability.spell) in [SpellData.Delivery.PROJECTILE, SpellData.Delivery.BEAM]
			EnemyAIAction.Kind.CAST: fits = ability.kind == EnemyAbilityData.Kind.SPELL and ability.role == EnemyAbilityData.Role.OFFENSE
			EnemyAIAction.Kind.DEFEND: fits = ability.role == EnemyAbilityData.Role.DEFENSE
			EnemyAIAction.Kind.RECOVER: fits = ability.role == EnemyAbilityData.Role.HEAL
			EnemyAIAction.Kind.SUMMON: fits = ability.role == EnemyAbilityData.Role.SUMMON
		if not fits: continue
		var target: Node2D = enemy.combat.target_for(ability, enemy.detection.player)
		if ability.role == EnemyAbilityData.Role.HEAL and target and target.has_method("get_health_ratio") and target.get_health_ratio() >= 0.8: continue
		if enemy.combat.can_use(ability, target) and (best == null or ability.weight > best.weight): best = ability
	return best

func preferred_distance() -> float:
	var reach := 0.0
	for ability in get_parent().combat.loadout:
		if ability.role == EnemyAbilityData.Role.OFFENSE and ability.kind == EnemyAbilityData.Kind.SPELL: return profile.preferred_range
		if ability.kind == EnemyAbilityData.Kind.MELEE: reach = maxf(reach, ability.max_range)
	return minf(profile.preferred_range, maxf(0, reach * 0.6 - profile.range_tolerance))
