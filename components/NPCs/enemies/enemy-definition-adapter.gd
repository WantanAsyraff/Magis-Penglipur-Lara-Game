class_name EnemyDefinitionAdapter extends RefCounted
## Runtime-only definitions for unmigrated scenes and NPCSpellcasterData assets.
static func from_scene(enemy: Node) -> EnemyData:
	var data := _base()
	data.enemy_id = StringName(enemy.enemy_name.to_snake_case())
	data.enemy_name = enemy.enemy_name
	data.stats.max_health = enemy.max_health
	data.stats.max_mana = enemy.spell_mana
	data.stats.move_speed = enemy.move_speed
	data.stats.chase_speed = enemy.chase_speed
	data.stats.defense = enemy.damage_reduction
	data.stats.incoming_multiplier = enemy.damage_multiplier
	data.ai_profile = load("res://data/npc/enemies/ai-profiles/balanced-fighter.tres")
	var combat := enemy.get_node("EnemyCombat")
	if combat.attack_type != Enemy.AttackType.RANGED:
		var melee := EnemyAbilityData.new()
		melee.ability_id = &"legacy_melee"
		melee.kind = EnemyAbilityData.Kind.MELEE
		melee.max_range = combat.melee_range
		melee.cooldown = combat.attack_cooldown
		var damage := DamageEffect.new()
		damage.amount = combat.melee_damage
		var push := KnockbackEffect.new()
		push.force = 120
		melee.effects = [damage, push]
		data.abilities.append(melee)
	if combat.ranged_spell:
		var ability := EnemyAbilityData.new()
		ability.ability_id = &"legacy_ranged"
		ability.spell = combat.ranged_spell
		ability.max_range = combat.ranged_trigger_distance
		ability.min_range = combat.retreat_threshold
		ability.cooldown = combat.attack_cooldown
		data.abilities.append(ability)
	var loot := enemy.get_node_or_null("EnemyLootComponent") as EnemyLootComponent
	if loot: data.loot = loot.loot_table.duplicate()
	var observer := enemy.get_node_or_null("EnemyQuestObserverComponent") as EnemyQuestObserver
	if observer: data.quest_enemy_id = observer.enemy_id
	return data
static func from_spellcaster(old: NPCSpellcasterData) -> EnemyData:
	var data := _base()
	data.enemy_id = StringName(old.caster_id)
	data.enemy_name = old.caster_name
	data.stats.max_health = old.max_hp
	data.stats.max_mana = old.max_mana
	data.stats.health_regen = old.hp_regen_rate
	data.stats.mana_regen = old.mana_regen_rate
	data.stats.regen_delay = old.mana_regen_delay
	data.stats.defense = old.base_defense
	data.stats.move_speed = old.move_speed
	data.stats.chase_speed = old.move_speed
	data.stats.status_resistances = {"stun": old.stun_resistance, "dot": old.dot_resistance, "slow": old.impairment_resistance}
	data.ai_profile = (load("res://data/npc/enemies/ai-profiles/cautious-spellcaster.tres") as EnemyAIProfile).duplicate()
	data.ai_profile.preferred_range = old.preferred_range
	data.ai_profile.retreat_range = old.too_close_threshold
	data.experience_reward = old.exp_reward
	for spell in old.spell_pool:
		if spell == null: continue
		var kind: String = SpellData.SpellType.keys()[spell.spell_type]
		if kind in old.forbidden_spell_types: continue
		var ability := EnemyAbilityData.new()
		ability.ability_id = StringName(spell.spell_id)
		ability.spell = spell
		ability.max_range = spell.target_range
		ability.weight = 2 if kind in old.preferred_spell_types else 1
		if spell.spell_category == SpellData.SpellCategory.HEALING: ability.role = EnemyAbilityData.Role.HEAL
		elif spell.spell_category == SpellData.SpellCategory.BUFF: ability.role = EnemyAbilityData.Role.DEFENSE
		elif spell.delivery == SpellData.Delivery.SUMMON: ability.role = EnemyAbilityData.Role.SUMMON
		data.abilities.append(ability)
	return data
static func _base() -> EnemyData:
	var data := EnemyData.new()
	data.stats = EnemyStatsData.new()
	data.perception = EnemyPerceptionData.new()
	return data
