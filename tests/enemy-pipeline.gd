extends Node
const Actor = preload("res://tests/spell-regression.gd").TestActor
const BASE = preload("res://components/NPCs/enemies/Enemy.tscn")
const POHON = preload("res://components/NPCs/enemies/zalam-manifestations/pohon/pohon.tscn")
const BUNGA = preload("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn")
var checks := 0
var failures := 0
var completed := false
var box: Node2D
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func reset() -> void:
	if is_instance_valid(box): box.free()
	box = Node2D.new()
	add_child(box)
func actor(point: Vector2, faction: StringName = &"player") -> CharacterBody2D:
	var node := Actor.new()
	if faction == &"player": node.add_to_group("player")
	node.set_meta("faction_id", faction)
	node.set_meta("spell_team", faction)
	box.add_child(node)
	node.position = point
	node.health = 100000
	node.mana = 10000
	node.collision_layer = 1 if faction == &"player" else 2
	var collision := CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 10
	node.add_child(collision)
	return node
func enemy(scene: PackedScene = BASE, data: EnemyData = null, point: Vector2 = Vector2.ZERO) -> Enemy:
	var node := scene.instantiate() as Enemy
	node.enemy_data = data if data else node.enemy_data
	node.position = point
	box.add_child(node)
	node.set_physics_process(false)
	node.hitbox.set_physics_process(false)
	return node
func wall(point: Vector2, dimensions: Vector2) -> StaticBody2D:
	var node := StaticBody2D.new()
	node.collision_layer = 16
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	node.add_child(collision)
	box.add_child(node)
	node.position = point
	return node
func frames() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
func quiet_loot(e: Enemy) -> void:
	e.get_node("EnemyLootComponent").loot_table.clear()
func _ready() -> void:
	await get_tree().process_frame
	await run()
	check(completed, "Enemy suite reached its final assertion")
	print("ENEMY_PIPELINE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func run() -> void:
	reset()
	var ids := {}
	for file in ["pohon", "bunga", "training-guardian"]:
		var data := load("res://data/npc/enemies/definitions/" + file + ".tres") as EnemyData
		check(data != null and data.validate().is_empty() and not ids.has(data.enemy_id), "Valid unique EnemyData: " + file)
		ids[data.enemy_id] = true
	for file in ["aggressive-melee", "defensive-ranged", "balanced-fighter", "cautious-spellcaster", "support-oriented", "heavy-guardian"]:
		var profile := load("res://data/npc/enemies/ai-profiles/" + file + ".tres") as EnemyAIProfile
		check(profile != null and profile.validate().is_empty() and profile.actions.size() == 14, "Fourteen actions configured in profile: " + file)
	var p := enemy(POHON)
	var b := enemy(BUNGA, null, Vector2(2000, 0))
	check(p.definition.enemy_id == &"pohon" and p.max_health == 50 and p.move_speed == 500 and p.chase_speed == 800, "Pohon preserved identity, health and speeds")
	check(b.definition.enemy_id == &"bunga" and b.max_health == 40 and b.combat.loadout.size() == 3, "Bunga migrated with original melee plus ranged/defensive additions")
	check(p.ai.get_script() == b.ai.get_script() and p.combat.casting is SpellCastingComponent, "Both share AI and Magis casting implementations")
	var p2 := enemy(POHON, null, Vector2(4000, 0))
	p.combat.cooldowns[&"pohon_branch"] = 10
	p.detection.threat[123] = 10
	p.hitbox.effects.apply("slow", 5, {"factor": .5})
	check(p2.combat.cooldowns.is_empty() and p2.detection.threat.is_empty() and not p2.hitbox.effects.has("slow"), "Cooldowns, memory and statuses are instance-local")
	check(p.enemy_data.stats.max_health == 50 and p2.enemy_data == p.enemy_data, "Shared definitions remain immutable")
	# Profiles choose meaningfully different actions with identical body and loadout.
	reset()
	var data := (load("res://data/npc/enemies/definitions/bunga.tres") as EnemyData).duplicate() as EnemyData
	data.ai_profile = load("res://data/npc/enemies/ai-profiles/aggressive-melee.tres")
	var aggressive := enemy(BASE, data)
	var victim := actor(Vector2(80, 0))
	aggressive.detection.scan()
	aggressive.ai.decide()
	check(aggressive.ai.selected.kind == EnemyAIAction.Kind.MELEE and aggressive.combat.pending != null, "Aggressive profile commits to melee at close range")
	aggressive.combat.cancel()
	data = data.duplicate() as EnemyData
	data.ai_profile = load("res://data/npc/enemies/ai-profiles/defensive-ranged.tres")
	var defensive := enemy(BASE, data)
	defensive.detection.scan()
	defensive.ai.decide()
	check(defensive.ai.selected.kind == EnemyAIAction.Kind.RETREAT, "Same loadout with defensive profile retreats instead")
	var decisions := defensive.ai.decision_count
	defensive.ai._until_decision = .2
	defensive.ai.tick(.01)
	check(defensive.ai.decision_count == decisions, "Decision cadence prevents per-frame switching")
	# Perception: multi-target threat, neutral filtering, occlusion and finite memory.
	reset()
	b = enemy(BUNGA)
	victim = actor(Vector2(200, 0))
	var second := actor(Vector2(350, 0))
	var neutral := actor(Vector2(20, 0), &"neutral")
	b.detection.scan()
	check(b.detection.player == victim, "Nearest eligible target selected; neutral ignored")
	b.detection.record_hit(second, 100)
	b.detection.scan()
	check(b.detection.player == second, "Threat can prioritize another player")
	var last := b.detection.last_known_position
	var obstacle := wall(Vector2(100, 0), Vector2(30, 400))
	await frames()
	b.detection.scan()
	second.position = Vector2(1000, 0)
	check(not b.detection.has_line_of_sight() and b.detection.has_memory() and b.detection.last_known_position == last, "LOS blocked; last seen point retained without wall tracking")
	b.detection.tick(3)
	check(b.detection.player == null and not b.detection.has_memory(), "Target forgotten after memory expires")
	obstacle.queue_free()
	await frames()
	b.detection.scan()
	check(b.detection.player == victim, "Target reacquired after occlusion clears")
	victim.queue_free()
	await frames()
	b.detection.tick(.3)
	check(b.detection.player == null, "Deleted targets rejected safely")
	var ally_npc := actor(Vector2(180, 0), &"player")
	ally_npc.remove_from_group("player")
	b.detection.scan()
	check(b.detection.player == ally_npc, "Eligible NPC outside player group can be perceived")
	b.set_meta("faction_relations", {&"player": 1})
	b.detection.scan()
	check(not b.detection.valid_target(ally_npc) and CombatFactions.relation(b, neutral) == 0, "Allied override and neutral relations are explicit")
	# Ordinary melee uses an effect request, checks windup, and respects cooldown.
	reset()
	b = enemy(BUNGA)
	victim = actor(Vector2(100, 0))
	var melee := b.combat.loadout[0]
	check(b.combat.start(melee, victim) and victim.total_damage == 0, "Melee windup does not apply immediate damage")
	b.combat.tick(.3)
	check(victim.total_damage == 8 and b.combat.casting.state == SpellCastingComponent.State.IDLE, "Melee resolves eight damage through shared hitbox without a spell cast")
	check(not b.combat.start(melee, victim), "Ability cooldown prevents repeated attacks")
	b.combat.tick(2)
	check(b.combat.start(melee, victim), "Melee available when cooldown ends")
	victim.position.x = 1000
	b.combat.tick(.3)
	check(victim.total_damage == 8, "Melee revalidates range after windup")
	var context := SpellCastContext.new(b)
	var damage := DamageEffect.new()
	damage.amount = 2
	check(SpellExecutor.execute_effects(context, victim, [damage]) and context.spell == null and victim.total_damage == 10, "Executor supports non-magical context without fake SpellData")
	# Ranged cast initializes and moves at world coordinates.
	reset()
	p = enemy(POHON)
	victim = actor(Vector2(600, 0))
	var branch := p.combat.loadout[1]
	check(p.combat.start(branch, victim), "Pohon accepts configured Branch Projectile")
	p.combat.tick(.3)
	var projectile: MagicProjectile
	for node in get_tree().get_nodes_in_group("spell_projectile"):
		if node.source == p: projectile = node
	check(projectile != null and projectile._started and projectile.global_position == Vector2(40, 0) and projectile.collision_mask == 17, "Enemy projectile starts with correct origin and hostile mask")
	projectile.set_physics_process(false)
	projectile._physics_process(.1)
	check(projectile.global_position.x == 120, "Enemy projectile movement initialized")
	projectile._on_body_entered(p)
	check(not projectile._finished, "Projectile ignores its caster")
	projectile._on_body_entered(victim)
	check(victim.total_damage == 12 and projectile.is_queued_for_deletion(), "Projectile executes impact and cleans up")
	check(not p.can_cast_spell(load("res://data/magis/spells/phys-terminal.tres")), "Enemy cannot use a spell outside its loadout")
	# Mana, silence, stun and resistance flow through the shared services.
	reset()
	b = enemy(BUNGA)
	victim = actor(Vector2(300, 0))
	var seed := b.combat.loadout[1]
	b.spell_mana = 0
	check(not b.combat.start(seed, victim), "No-mana actor rejects a mana-costing ability")
	b.spell_mana = 60
	b.combat.start(seed, victim)
	b.combat.tick(.3)
	check(b.combat.casting.state == SpellCastingComponent.State.PREPARING and b.spell_mana == 56, "Shared casting reserves enemy mana")
	b.hitbox._apply_silence(1)
	b.combat.casting._physics_process(.1)
	check(b.combat.casting.state == SpellCastingComponent.State.IDLE and b.spell_mana == 60, "Silence cancels preparation and refunds undelivered mana")
	b.hitbox.clear_all_effects()
	victim.position = Vector2(100, 0)
	b.hitbox._apply_stun(1)
	check(not b.combat.can_use(b.combat.loadout[0], victim), "Stun blocks attacks")
	b.hitbox.effects.tick(2)
	check(not b.hitbox.is_stunned(), "Control status expires")
	b.hitbox.status_resistances["stun"] = 1
	b.hitbox._apply_stun(1)
	check(not b.hitbox.is_stunned(), "Configured status immunity applies to legacy and modular APIs")
	b.hitbox.status_resistances["slow"] = .5
	b.hitbox._apply_slow(.5, 4)
	b.hitbox.effects.tick(2.1)
	check(not b.hitbox.effects.has("slow"), "Partial resistance shortens status lifetime")
	# Every existing Physics delivery is usable by an explicitly configured enemy.
	reset()
	data = (load("res://data/npc/enemies/definitions/training-guardian.tres") as EnemyData).duplicate(true) as EnemyData
	data.stats.max_health = 100000
	data.stats.max_mana = 100000
	data.abilities.clear()
	for definition in Spell_Library.all_spells.values():
		var ability := EnemyAbilityData.new()
		ability.ability_id = StringName(definition.spell_id)
		ability.spell = definition
		ability.windup = 0
		ability.recovery = 0
		ability.max_range = 1000
		ability.requires_los = false
		data.abilities.append(ability)
	b = enemy(BASE, data)
	victim = actor(Vector2(220, 0))
	victim.set_meta("structural", true)
	victim.set_meta("magnetic", true)
	for ability in b.combat.loadout:
		b.combat.cancel()
		b.combat.cooldowns.clear()
		b.combat.casting.cooldowns.clear()
		b.position = Vector2.ZERO
		b.current_state = Enemy.State.IDLE
		b.hitbox.clear_all_effects()
		victim.hitbox.clear_all_effects()
		var paid: float = b.spell_mana
		var accepted := b.combat.start(ability, b.combat.target_for(ability, victim))
		b.combat.casting._physics_process(ability.spell.cast_time + .01)
		if ability.spell.is_channelled: b.combat.casting._physics_process(ability.spell.channel_duration)
		check(accepted and b.spell_mana < paid and b.combat.casting.cooldowns.has(ability.spell.spell_id), "Enemy shared execution: " + ability.spell.spell_name)
		CombatLifecycle.cleanup(b)
		await frames()
	# Zero-HP transition resolves rewards, quest and owned effects exactly once.
	reset()
	data = (load("res://data/npc/enemies/definitions/bunga.tres") as EnemyData).duplicate(true) as EnemyData
	var drop := LootData.new()
	drop.item = ItemData.new()
	drop.item.item_id = "enemy_test_drop"
	drop.drop_chance = 1
	data.loot = [drop]
	data.experience_reward = 7
	data.quest_enemy_id = "bunga"
	b = enemy(BASE, data)
	victim = actor(Vector2(500, 0))
	var deaths := [0]
	b.enemy_died.connect(func(): deaths[0] += 1)
	var objective := QuestObjectiveData.new()
	objective.objective_id = "enemy_test_kill"
	objective.type = QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY
	objective.target_id = "bunga"
	objective.required_amount = 10
	var quest := QuestData.new()
	quest.quest_id = "enemy_regression_quest"
	quest.objectives = [objective]
	var instance := QuestInstance.new(quest, "enemy_test_npc", 60)
	instance.status = QuestInstance.Status.ACTIVE
	QuestManager._active_instances[instance.instance_id] = instance
	var xp: float = Player_Global_Data.player_exp
	var owned := Node2D.new()
	box.add_child(owned)
	CombatLifecycle.own(owned, b)
	b.hitbox.receive_damage(10000, victim)
	b.hitbox.died.emit()
	b._on_died()
	b.hitbox.receive_damage(10000, victim)
	check(deaths[0] == 1 and b.current_state == Enemy.State.DEATH, "Death event emitted exactly once")
	check(instance.objective_progress.get("enemy_test_kill", 0) == 1, "Quest kill recorded exactly once")
	check(Player_Global_Data.player_exp == xp + 7, "Configured experience granted once")
	var drops := 0
	for node in box.get_children():
		if node is DroppedItem: drops += 1
	check(drops == 1 and b.get_node("EnemyLootComponent")._resolved, "Guaranteed loot spawned once before enemy cleanup")
	check(owned.is_queued_for_deletion() and b.hitbox.effects.entries.is_empty(), "Death cleans owned entities and active statuses")
	QuestManager._active_instances.erase(instance.instance_id)
	Player_Global_Data.player_exp = xp
	# Spawners reserve slots, parent before registering, support definitions and reject solids.
	reset()
	box.position = Vector2(300, 200)
	box.scale = Vector2(1.5, 1.5)
	for scene in [POHON, BUNGA]:
		var spawner := EnemySpawner.new()
		spawner.autostart = false
		spawner.max_enemies = 1
		spawner.respawn = false
		var entry := SpawnData.new()
		entry.enemy_scene = scene
		entry.spawn_weight = 10
		spawner.spawn_pool = [entry]
		spawner.position = Vector2(0 if scene == POHON else 1000, 0)
		box.add_child(spawner)
		spawner.enemy_spawned.connect(func(e): e.set_physics_process(false))
		var expected := spawner.global_position
		for i in 4: spawner._try_spawn()
		check(spawner._pending == 1, "Spawner reserves a single pending population slot")
		await frames()
		check(spawner._active_enemies.size() == 1 and spawner._active_enemies[0].global_position == expected and spawner._active_enemies[0].is_inside_tree(), "Spawner initializes scene at world point under transformed parent")
		var spawned := spawner._active_enemies[0]
		spawned.set_physics_process(false)
		quiet_loot(spawned)
		spawned.die()
		check(spawner._active_enemies.is_empty(), "Death immediately releases active spawn tracking")
		spawner._try_spawn()
		check(spawner._pending == 0, "One-shot spawner does not respawn a defeated enemy")
		spawner.queue_free()
		await frames()
	reset()
	var blocked := wall(Vector2.ZERO, Vector2(1000, 1000))
	await frames()
	var spawner := EnemySpawner.new()
	spawner.autostart = false
	spawner.max_enemies = 1
	var entry := SpawnData.new()
	entry.enemy_scene = BASE
	entry.enemy_data = load("res://data/npc/enemies/definitions/training-guardian.tres")
	spawner.spawn_pool = [entry]
	box.add_child(spawner)
	spawner._try_spawn()
	await frames()
	check(spawner._active_enemies.is_empty(), "Spawn inside solid geometry rejected")
	blocked.queue_free()
	await frames()
	spawner._try_spawn()
	spawner.stop_spawning()
	await frames()
	check(spawner._active_enemies.is_empty() and spawner._pending == 0, "Stopping cancels queued spawns safely")
	spawner.start_spawning()
	spawner.timer.stop()
	spawner._try_spawn()
	await frames()
	check(spawner._active_enemies.size() == 1 and spawner._active_enemies[0].definition.enemy_id == &"training-guardian", "SpawnData definition override creates resource-only third enemy")
	var spawned := spawner._active_enemies[0]
	spawned.set_physics_process(false)
	quiet_loot(spawned)
	spawned.die()
	await frames()
	spawner._try_spawn()
	await frames()
	check(spawner._active_enemies.size() == 1, "Respawn-enabled pool replaces defeated instance")
	# Legacy definitions, repaired references and training dummy remain usable.
	var old := load("res://data/npc/enemies/dudeman-test.tres") as NPCSpellcasterData
	var adapted := EnemyDefinitionAdapter.from_spellcaster(old)
	check(adapted.validate().is_empty() and adapted.abilities.size() == 5 and old.spell_pool.size() == 5, "NPCSpellcasterData adapts without resource mutation")
	for file in ["attack1", "attack2", "phase-test"]:
		check(load("res://data/npc/enemies/boss/test-boss/" + file + ".tres") != null, "Restored boss reference: " + file)
	reset()
	var dummy := load("res://components/NPCs/enemies/dummy/dummy-npc.tscn").instantiate() as TrainingDummy
	box.add_child(dummy)
	dummy.set_physics_process(false)
	var hp := dummy.current_hp
	dummy.take_damage(3)
	check(dummy.current_hp == hp - 3, "Training dummy public damage API preserved")
	# Boss phases, shared melee, initialized bursts, summons and death cleanup.
	reset()
	var phase := BossPhaseData.new()
	phase.transition_animation = ""
	var attack := BossAttackData.new()
	attack.windup = .01
	attack.melee_damage = 11
	attack.melee_range = 200
	phase.attacks = [attack]
	var phase2 := BossPhaseData.new()
	phase2.enter_at_health_ratio = .5
	phase2.invincible_on_transition = false
	phase2.transition_animation = ""
	phase2.defense = 2
	phase2.attacks = [attack]
	var boss := load("res://components/NPCs/enemies/boss/boss.tscn").instantiate() as Boss
	boss.phases = [phase, phase2]
	boss.max_health = 100
	box.add_child(boss)
	boss.set_physics_process(false)
	victim = actor(Vector2(100, 0))
	boss._player = victim
	boss.current_state = Boss.State.ATTACK
	boss.current_attack = attack
	await boss._do_melee_slam()
	check(victim.total_damage == 11, "Boss melee shares ordinary combat resolution")
	attack = attack.duplicate() as BossAttackData
	attack.kind = BossAttackData.AttackKind.RANGED_BURST
	attack.burst_count = 2
	attack.burst_interval = .01
	attack.ranged_spell = load("res://data/magis/enemy-spells/pohon-branch.tres")
	boss.current_attack = attack
	await boss._do_ranged_burst()
	var projectiles := 0
	for node in get_tree().get_nodes_in_group("spell_projectile"):
		if node.source == boss and node._started: projectiles += 1
	check(projectiles == 2, "Boss burst uses shared casting and initializes every projectile")
	attack.kind = BossAttackData.AttackKind.SUMMON
	attack.minion_scene = BASE
	attack.minion_count = 2
	await boss._do_summon()
	check(boss._owned_minions() == 2, "Boss summons remain configurable and owned")
	CombatLifecycle.cleanup(boss)
	await frames()
	attack.kind = BossAttackData.AttackKind.AOE_SLAM
	attack.aoe_warning_duration = .01
	attack.aoe_radius = 250
	attack.aoe_damage = 9
	var before_hit: float = victim.total_damage
	await boss._do_aoe_slam()
	check(victim.total_damage == before_hit + 9, "Boss area slam resolves shared damage after warning")
	attack.kind = BossAttackData.AttackKind.MELEE_DASH
	attack.dash_duration = .03
	before_hit = victim.total_damage
	await boss._do_melee_dash()
	check(victim.total_damage == before_hit + 11, "Boss dash retains its shared contact strike")
	attack.kind = BossAttackData.AttackKind.MELEE_SLAM
	attack.windup = .1
	before_hit = victim.total_damage
	boss._do_melee_slam()
	boss._attack_epoch += 1
	await get_tree().create_timer(.15).timeout
	check(victim.total_damage == before_hit, "Cancelled boss windup cannot apply a late hit")
	boss.hitbox.receive_damage(60, victim)
	check(boss.current_phase_index == 1 and boss.hitbox.damage_reduction == 2, "Boss health threshold changes phase and mitigation")
	var boss_deaths := [0]
	boss.boss_died.connect(func(): boss_deaths[0] += 1)
	boss.hitbox.receive_damage(1000, victim)
	boss._on_death()
	check(boss_deaths[0] == 1 and boss.get_meta("combat_dead", false), "Boss death resolves once")
	var cleaned := true
	for node in get_tree().get_nodes_in_group("combat_owned"):
		if node.get_meta("combat_owner", null) == boss: cleaned = cleaned and node.is_queued_for_deletion()
	check(cleaned, "Boss death cleans its projectiles and minions")
	# Each non-attack intent has an executable movement/recovery path.
	reset()
	b = enemy(BUNGA)
	victim = actor(Vector2(400, 0))
	b.detection.scan()
	var profile := EnemyAIProfile.new()
	var action := EnemyAIAction.new()
	action.action_id = &"action_test"
	action.kind = EnemyAIAction.Kind.CHASE
	profile.actions = [action]
	b.ai.configure(profile)
	b.ai.decide()
	b.movement.tick(.1)
	check(b.ai.selected == action and b.velocity.x > 0, "Chase intent executes movement toward visible target")
	for kind in [EnemyAIAction.Kind.INVESTIGATE, EnemyAIAction.Kind.REPOSITION]:
		action.kind = kind
		b.detection.visible = false
		b.detection.blackboard.visible = false
		b.detection._sight_memory_timer = 2
		b.detection.last_known_position = Vector2(300, 0)
		b.ai.decide()
		b.movement.tick(.1)
		check(b.ai.selected.kind == kind and b.velocity.x > 0, "Memory movement executes intent %d" % kind)
	action.kind = EnemyAIAction.Kind.MAINTAIN_RANGE
	b.detection.scan()
	b.ai.decide()
	b.movement.tick(.1)
	check(b.velocity.x > 0, "Preferred range approaches distant target")
	victim.position.x = profile.preferred_range
	b.detection.scan()
	b.ai.decide()
	b.movement.tick(.1)
	check(b.velocity.x == 0, "Preferred range holds within tolerance")
	action.kind = EnemyAIAction.Kind.FLEE
	b.current_health = 3
	b.ai.decide()
	b.movement.tick(.1)
	check(b.ai.selected.kind == EnemyAIAction.Kind.FLEE and b.velocity.x < 0, "Low-health flee moves away from threat")
	b.current_health = b.max_health
	action.kind = EnemyAIAction.Kind.RECOVER
	b.spell_mana = 0
	b.ai.decide()
	b.stats.regen_remaining = 0
	b.stats.tick(3)
	check(b.ai.selected.kind == EnemyAIAction.Kind.RECOVER and b.spell_mana > 0, "Recovery waits for configured mana regeneration without inventing healing")
	b.spell_mana = 60
	action.kind = EnemyAIAction.Kind.DEFEND
	victim.position.x = 100
	b.detection.scan()
	b.ai.decide()
	b.combat.tick(.3)
	b.combat.casting._physics_process(.2)
	check(victim.hitbox.effects.has("slow") and victim.velocity.x > 0, "Defend action executes configured repulse ability")
	b.combat.cancel()
	b.combat.cooldowns.clear()
	action.kind = EnemyAIAction.Kind.CAST
	victim.position.x = 300
	b.detection.scan()
	b.ai.decide()
	check(b.combat.pending != null and b.combat.pending.kind == EnemyAbilityData.Kind.SPELL, "Cast action selects an available configured spell")
	b.combat.cancel()
	# A healer uses a configured heal; a summon action uses a configured construct.
	reset()
	data = (load("res://data/npc/enemies/definitions/training-guardian.tres") as EnemyData).duplicate(true) as EnemyData
	data.stats.max_mana = 100
	var heal := EnemyAbilityData.new()
	heal.ability_id = &"test_heal"
	heal.role = EnemyAbilityData.Role.HEAL
	heal.spell = load("res://data/magis/spells/phys-harmonic-stabilization.tres")
	var summon := EnemyAbilityData.new()
	summon.ability_id = &"test_summon"
	summon.role = EnemyAbilityData.Role.SUMMON
	summon.spell = load("res://data/magis/spells/phys-gyroscopic-shield.tres")
	data.abilities = [heal, summon]
	b = enemy(BASE, data)
	victim = actor(Vector2(200, 0))
	b.current_health = 10
	profile = EnemyAIProfile.new()
	action = EnemyAIAction.new()
	action.action_id = &"heal"
	action.kind = EnemyAIAction.Kind.RECOVER
	profile.actions = [action]
	b.ai.configure(profile)
	b.detection.scan()
	b.ai.decide()
	b.combat.tick(.3)
	b.combat.casting._physics_process(1)
	check(b.current_health == 32, "Recovery uses shared healing when healing is in the loadout")
	b.combat.tick(1)
	action.kind = EnemyAIAction.Kind.SUMMON
	b.ai.interrupt()
	b.ai.decide()
	b.combat.tick(.3)
	b.combat.casting._physics_process(1)
	var summoned := false
	for node in get_tree().get_nodes_in_group("combat_owned"):
		if node is SpellConstruct and node.get_meta("combat_owner", null) == b: summoned = true
	check(summoned, "Summon action dispatches configured shared summon delivery")
	# Damage scaling must not accidentally scale healing.
	reset()
	data = (load("res://data/npc/enemies/definitions/training-guardian.tres") as EnemyData).duplicate(true) as EnemyData
	data.stats.max_health = 100
	data.stats.max_mana = 100
	data.stats.defense = 3
	data.stats.incoming_multiplier = .5
	data.stats.outgoing_multiplier = 2
	data.abilities = [heal]
	b = enemy(BASE, data)
	victim = actor(Vector2(100, 0))
	CombatRequest.strike(b, victim, 10)
	check(victim.total_damage == 20, "Outgoing damage multiplier applies to shared attacks")
	check(b.damage_reduction == 3 and b.damage_multiplier == .5, "Legacy stat views reflect configured mitigation")
	b.current_health = 50
	b.combat.start(heal, b)
	b.combat.tick(.3)
	b.combat.casting._physics_process(1)
	var healed_health := b.current_health
	b.hitbox.receive_hit(load("res://data/magis/spells/phys-force.tres"))
	check(healed_health == 72 and b.current_health == 65, "Outgoing multiplier leaves healing and incoming legacy damage unchanged")
	# Without targets, idle and patrol remain valid; patrol can actually traverse terrain.
	reset()
	b = enemy(BASE, load("res://data/npc/enemies/definitions/training-guardian.tres"))
	wall(Vector2(0, 150), Vector2(3000, 30))
	b.set_physics_process(true)
	for i in 80: await get_tree().physics_frame
	check(b.ai.selected != null and b.ai.selected.kind == EnemyAIAction.Kind.PATROL and absf(b.position.x) > 1, "Patrol runs on a real floor with no targets")
	b.set_physics_process(false)
	b.patrol._direction_lock = 1
	b.hitbox._apply_slow(.5, 5)
	b.movement.tick(.1)
	check(is_equal_approx(absf(b.velocity.x), b.move_speed * .5), "Patrol respects the same slow modifiers as chase")
	b.hitbox.clear_all_effects()
	profile = EnemyAIProfile.new()
	action = EnemyAIAction.new()
	action.action_id = &"idle"
	profile.actions = [action]
	b.ai.configure(profile)
	b.ai.decide()
	b.movement.tick(.1)
	check(b.current_state == Enemy.State.IDLE and b.velocity.x == 0, "Idle intent halts movement without a target")
	# Non-authoritative peers cannot drive perception, decisions, spawning or effects.
	reset()
	b = enemy(BUNGA)
	victim = actor(Vector2(100, 0))
	var peer := ENetMultiplayerPeer.new()
	check(peer.create_client("127.0.0.1", 19996) == OK, "Authority-test client created")
	multiplayer.multiplayer_peer = peer
	var scans := b.detection.scan_count
	decisions = b.ai.decision_count
	b.detection.tick(1)
	b.ai.tick(1)
	var before := b.current_health
	b.hitbox.receive_damage(10, victim)
	check(b.detection.scan_count == scans and b.ai.decision_count == decisions and b.current_health == before, "Client cannot simulate perception, AI or damage")
	check(not b.combat.start(b.combat.loadout[0], victim), "Client cannot launch enemy ability")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer.close()
	box.free()
	completed = true
