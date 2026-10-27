extends Node

class TestActor extends CharacterBody2D:
	var mana: float = 100.0
	var health: float = 50.0
	var total_damage: float = 0.0
	var eligible: bool = true
	var hitbox: HitboxComponent
	var casting: SpellCastingComponent
	func _ready() -> void:
		hitbox = HitboxComponent.new()
		hitbox.name = "HitboxComponent"
		add_child(hitbox)
		hitbox.has_mana = true
		hitbox.set_physics_process(false)
		hitbox.damage_taken.connect(func(amount): health -= amount; total_damage += amount)
		hitbox.healed.connect(func(amount): health += amount)
		hitbox.mana_drained.connect(func(amount): mana -= amount)
		casting = SpellCastingComponent.new()
		add_child(casting)
		casting.set_physics_process(false)
	func consume_spell_mana(amount: float) -> bool:
		if amount < 0 or mana < amount:
			return false
		mana -= amount
		return true
	func restore_spell_mana(amount: float) -> void:
		mana += amount
	func can_cast_spell(_spell: SpellData) -> bool:
		return eligible

var failures: int = 0
var checks: int = 0
var actors: Array[TestActor] = []

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print("%s %s" % ["PASS" if condition else "FAIL", label])

func actor(player_team: bool = false) -> TestActor:
	var a := TestActor.new()
	if player_team:
		a.add_to_group("player")
	add_child(a)
	actors.append(a)
	return a

func self_spell(id: String = "test") -> SpellData:
	var spell := SpellData.new()
	spell.spell_id = id
	spell.delivery = SpellData.Delivery.SELF
	var heal := HealEffect.new()
	heal.amount = 5
	spell.effects.append(heal)
	return spell

func _ready() -> void:
	await get_tree().process_frame
	await run_tests()
	print("SPELL_REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func run_tests() -> void:
	check(Spell_Library.all_spells.size() == 42, "01 42 catalogue spells load")
	check(Spell_Library.validation_errors.is_empty(), "01 legacy definitions validate: " + str(Spell_Library.validation_errors))
	var first: SpellData = Spell_Library.all_spells.values()[0]
	var count := Spell_Library.all_spells.size()
	check(not Spell_Library.register_spell(first) and Spell_Library.all_spells.size() == count, "02 duplicate ID rejected without overwrite")
	Spell_Library.validation_errors.clear()
	var resolver := IncantationResolver.new()
	var combos: Array[SpellData] = [load("res://data/magis/spells/phys-strike.tres"), load("res://data/magis/spells/phys-resonate.tres"), load("res://data/magis/spells/phys-shatterwave.tres")]
	resolver.rebuild(combos)
	resolver.push("down")
	resolver.push("left")
	check(resolver.push("down") == combos[0] and resolver.push("left") == combos[1] and resolver.push("down") == combos[2], "03 chained prefix spells resolve intentionally")
	resolver.strategy = IncantationResolver.Strategy.CONFIRMATION
	resolver.clear()
	resolver.push("down")
	resolver.push("left")
	check(resolver.push("down") == null and resolver.confirm() == combos[0], "03 confirmation delays ambiguous prefix")
	resolver.strategy = IncantationResolver.Strategy.DELAYED
	resolver.push("down")
	resolver.push("left")
	resolver.push("down")
	check(resolver.tick(0.1) == null and resolver.tick(0.4) == combos[0], "03 delayed strategy waits for timeout")
	resolver.strategy = IncantationResolver.Strategy.IMMEDIATE
	resolver.push("down")
	resolver.push("left")
	check(resolver.push("down") == combos[0] and resolver.sequence.is_empty(), "03 immediate strategy consumes sequence")
	var a := actor(true)
	var spell := self_spell()
	spell.upfront_cost = 101
	check(not a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT) and a.mana == 100, "04 insufficient mana is unchanged")
	spell.upfront_cost = 10
	a.eligible = false
	check(not a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT), "04 unequipped spell denied")
	a.eligible = true
	for status in ["silence", "stun"]:
		a.hitbox.effects.apply(status, 1, {})
		check(not a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT), "05 casting blocked by " + status)
		a.hitbox.remove_effect(status)
	spell.cast_time = 1
	check(a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT) and a.mana == 90, "06 preparation reserves upfront mana")
	a.casting.cancel()
	check(a.mana == 100 and a.health == 50, "06 interruption refunds upfront without applying heal")
	spell.is_channelled = true
	spell.channel_duration = 2
	spell.mana_per_second = 3
	a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT)
	a.casting._physics_process(1)
	check(a.casting.state == SpellCastingComponent.State.CHANNELING, "06 explicit channel lifecycle")
	a.casting._physics_process(0.5)
	a.casting.cancel()
	check(is_equal_approx(a.mana, 98.5), "06 channel cancellation refunds only upfront mana")
	spell.is_channelled = false
	spell.cast_time = 0
	spell.cooldown = 1
	a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT)
	check(not a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT), "06 cooldown prevents repeat cast")
	a.casting._physics_process(1.1)
	check(a.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT), "06 cooldown expires")
	var target := actor()
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	target.add_child(shape)
	target.collision_layer = 2
	target.position = Vector2(100, 0)
	var projectile_spell: SpellData = load("res://data/magis/spells/phys-terminal.tres").duplicate()
	projectile_spell.projectile_particles = null
	projectile_spell.impact_particles = null
	var proj: MagicProjectile = load("res://components/projectiles/player-magis-projectile.tscn").instantiate()
	proj.spell_data = projectile_spell
	proj.source = a
	add_child(proj)
	proj.start()
	proj.start()
	proj.set_physics_process(false)
	var terrain := StaticBody2D.new()
	terrain.add_to_group("world")
	add_child(terrain)
	await get_tree().physics_frame
	await get_tree().physics_frame
	proj._on_body_entered(terrain)
	proj._on_body_entered(terrain)
	check(target.total_damage == 85, "07 terrain impact applies AOE exactly once")
	terrain.queue_free()
	var hot := HealEffect.new()
	hot.amount = 4
	hot.duration = 3
	hot.tick_interval = 1
	var context := SpellCastContext.new(a, self_spell())
	var initial_hp := a.health
	hot.execute(context, a)
	a.hitbox.effects.tick(3)
	check(a.health == initial_hp + 12 and not a.hitbox.effects.has("hot"), "08 healing ticks through final interval then expires")
	var manager := ActiveEffectManager.new()
	manager.apply("buff_speed", 1, {"amount": 10}, "one", ActiveEffectManager.StackPolicy.STACK, 2, true)
	manager.apply("buff_speed", 2, {"amount": 20}, "two", ActiveEffectManager.StackPolicy.STACK, 2, true)
	check(manager.magnitude("buff_speed") == 30 and not manager.apply("buff_speed", 1, {}, "three", ActiveEffectManager.StackPolicy.STACK, 2, true), "09 independent stacks enforce maximum")
	manager.tick(1.1)
	check(manager.magnitude("buff_speed") == 20, "09 earlier expiry preserves later buff")
	manager.tick(1)
	check(manager.magnitude("buff_speed") == 0, "09 buffs expire without restoring stale base values")
	a.hitbox._apply_stun(3)
	a.hitbox._apply_dot(2, 0, 3)
	a.hitbox.effects.apply("buff_damage", 2, {"amount": 5}, "buff", ActiveEffectManager.StackPolicy.REFRESH, 1, true)
	var dispel := RemoveStatusEffect.new()
	dispel.execute(context, a)
	check(not a.hitbox.is_stunned() and not a.hitbox.effects.has("dot") and a.hitbox.effects.has("buff_damage"), "10 dispel removes debuffs and preserves buffs")
	a.hitbox.clear_all_buffs()
	check(a.hitbox.get_active_effects().is_empty(), "10 purge removes buffs")
	var old_xp := Player_Global_Data.player_exp
	var old_subjects := Player_Global_Data.completed_subjects.duplicate()
	var old_spells := Player_Global_Data.learned_spells.duplicate()
	Player_Global_Data.completed_subjects.clear()
	Player_Global_Data.player_exp = 1000
	var subject := subjectData.new()
	subject.subject_id = "test_subject"
	subject.difficulty_level = 1
	subject.prerequisites = ["test_prereq"]
	check(not Player_Global_Data.purchase_subject(subject) and Player_Global_Data.player_exp == 1000, "11 missing prerequisite prevents purchase")
	Player_Global_Data.completed_subjects.append("test_prereq")
	check(Player_Global_Data.purchase_subject(subject), "11 valid subject purchase succeeds")
	var after_purchase := Player_Global_Data.player_exp
	check(not Player_Global_Data.purchase_subject(subject) and Player_Global_Data.player_exp == after_purchase, "11 repeated purchase cannot deduct XP")
	Player_Global_Data.player_exp = old_xp
	Player_Global_Data.completed_subjects = old_subjects
	Player_Global_Data.learned_spells = old_spells
	var damage := DamageEffect.new()
	damage.amount = 1
	var conditional := ConditionalEffect.new()
	conditional.required_status = "slow"
	conditional.children.append(conditional)
	target.hitbox._apply_slow(0.2, 1)
	var chained: Array[SpellEffectDefinition] = [conditional]
	check(not SpellExecutor.execute_effects(context, target, chained) and context.chain_depth == 0, "12 circular effect execution stops at depth limit")
	conditional.children.clear()
	context.remaining_effect_budget = 1
	var double_damage: Array[SpellEffectDefinition] = [damage, damage]
	var before_damage := target.total_damage
	SpellExecutor.execute_effects(context, target, double_damage)
	check(target.total_damage == before_damage + 1 and context.remaining_effect_budget == 0, "12 effect budget bounds ordered execution")
	var temporary := actor()
	var deleted_context := SpellCastContext.new(temporary, self_spell())
	hot.execute(deleted_context, temporary)
	temporary.queue_free()
	check(not deleted_context.can_execute(), "13 queued caster prevents new effects")
	await get_tree().process_frame
	check(not deleted_context.can_execute(), "13 deleted caster remains safe")
	var legacy: SpellData = load("res://data/magis/spells/phys-strike.tres")
	var legacy_effects := LegacySpellAdapter.effects_for(legacy)
	check(legacy_effects.size() == 3 and legacy.effects.is_empty(), "14 legacy damage knockback and slow adapt without resource mutation")
	var c1 := SpellCastContext.new(a, legacy)
	var c2 := SpellCastContext.new(a, legacy)
	c1.state["visited"] = true
	check(c1.cast_id != c2.cast_id and c2.state.is_empty(), "14 cast contexts isolate runtime state")
	check(preload("res://data/magis/spell-manifest.gd").SPELLS.size() == 42, "15 baked manifest retains 42 exported spell resources")
	var client := ENetMultiplayerPeer.new()
	var err := client.create_client("127.0.0.1", 19998)
	check(err == OK, "16 test client peer created")
	multiplayer.multiplayer_peer = client
	check(not SpellExecutor.is_authoritative(a), "16 client has no gameplay authority")
	var client_context := SpellCastContext.new(a, self_spell())
	check(not SpellExecutor.execute_effects(client_context, a, double_damage), "16 client cannot apply authoritative effects")
	check(not a.casting.request_cast(self_spell("client"), Vector2.ZERO, Vector2.RIGHT), "16 client cannot dispatch authoritative casts")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	client.close()
	# Exercise additional delivery modes with actual scene-tree actors.
	var multi := self_spell("multi")
	multi.effects.clear()
	var direct_damage := DamageEffect.new()
	direct_damage.amount = 3
	var direct_heal := HealEffect.new()
	direct_heal.amount = 2
	multi.effects = [direct_damage, direct_heal]
	multi.delivery = SpellData.Delivery.DIRECT_TARGET
	var direct_context := SpellCastContext.new(a, multi)
	direct_context.targets = [target]
	var target_health := target.health
	check(SpellDelivery.dispatch(direct_context) and target.health == target_health - 1, "18 direct delivery combines ordered damage and healing")
	multi.delivery = SpellData.Delivery.AREA_BURST
	multi.aoe_spell_radius = 500
	var area_context := SpellCastContext.new(a, multi)
	check(SpellDelivery.dispatch(area_context), "18 area burst dispatches reusable effects")
	for mode in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.BEAM, SpellData.Delivery.TRAP]:
		multi.delivery = mode
		var area_cast := SpellCastContext.new(a, multi)
		area_cast.direction = Vector2.RIGHT
		var before := target.total_damage
		SpellDelivery.dispatch(area_cast)
		var delivered: SpellAreaDelivery = get_children().back()
		delivered.set_physics_process(false)
		delivered._physics_process(0.1)
		check(target.total_damage == before + 3, "18 area/beam/trap mode %s delivers effects" % mode)
		delivered.queue_free()
	var queued := actor(true)
	var queue_spell := self_spell("queue")
	queue_spell.upfront_cost = 10
	queue_spell.cast_time = 1
	queued.casting.enqueue_cast(queue_spell, Vector2.ZERO, Vector2.RIGHT)
	queued.casting.enqueue_cast(queue_spell, Vector2.ZERO, Vector2.RIGHT)
	check(queued.mana == 90, "19 queued chain does not precharge next cast")
	queued.casting._physics_process(1)
	queued.casting._physics_process(0.1)
	check(queued.mana == 80 and queued.casting.state == SpellCastingComponent.State.PREPARING, "19 queued chain validates and charges when it starts")
	queued.casting.cancel()
	check(queued.mana == 90, "19 cancellation refunds pending preparation and clears queue")
	var course := CourseData.new()
	course.course_id = "cycle"
	var subject_a := subjectData.new()
	subject_a.subject_id = "a"
	subject_a.prerequisites = ["b"]
	var subject_b := subjectData.new()
	subject_b.subject_id = "b"
	subject_b.prerequisites = ["a"]
	course.subjects = [subject_a, subject_b]
	check(not AcademicValidator.validate_course(course).is_empty(), "20 academic cycle diagnosed without recursion overflow")
	subject_a.comprehension_requirements[&"physics"] = 2
	check(not Player_Global_Data.can_purchase_subject(subject_a), "20 comprehension requirements gate purchase")
	var source_manager := ActiveEffectManager.new()
	source_manager.apply("buff_speed", 3, {"amount": 2}, "source_one", ActiveEffectManager.StackPolicy.STACK, 2, true)
	source_manager.apply("buff_speed", 3, {"amount": 4}, "source_two", ActiveEffectManager.StackPolicy.STACK, 2, true)
	source_manager.remove_source("source_one")
	check(source_manager.magnitude("buff_speed") == 4, "21 source cancellation preserves other stacks")
	# Instantiate production player and enemy scenes, including their child components.
	var real_player := Player_Manager.spawn_player(self, Vector2(10000, -1000)) as Player
	await get_tree().process_frame
	check(real_player != null and real_player.casting != null, "22 production Player scene initializes casting component")
	real_player.set_physics_process(false)
	Player_Global_Data.add_spell(legacy)
	Player_Global_Data.equip_spell(legacy)
	check(real_player.can_cast_spell(legacy), "22 production learned/equipped eligibility")
	var original_mana := Player_Global_Data.p_curr_mana
	real_player._cast_resolved(legacy)
	check(real_player.casting.state == SpellCastingComponent.State.PREPARING, "22 Player delegates preparation to casting service")
	real_player.casting.cancel()
	check(Player_Global_Data.p_curr_mana == original_mana, "22 production Player interruption refunds mana")
	Player_Manager.remove_player(1)
	var real_enemy: Enemy = load("res://components/NPCs/enemies/Enemy.tscn").instantiate()
	add_child(real_enemy)
	real_enemy.set_physics_process(false)
	await get_tree().process_frame
	check(real_enemy.combat.casting != null and real_enemy.combat.casting.is_inside_tree(), "22 production enemy casting component initializes")
	real_enemy.queue_free()
	var server := ENetMultiplayerPeer.new()
	check(server.create_server(19997) == OK, "23 test authority server created")
	multiplayer.multiplayer_peer = server
	var remote: Player = load("res://components/characters/player/player.tscn").instantiate()
	remote.set_multiplayer_authority(2)
	add_child(remote)
	await get_tree().process_frame
	var local_health := Player_Global_Data.p_curr_health
	var local_mana := Player_Global_Data.p_curr_mana
	remote.hitbox._apply_damage(7)
	remote.hitbox.mana_drained.emit(9)
	check(remote._remote_health == 93 and remote._remote_mana == 391, "23 remote actor keeps its own health and mana")
	check(Player_Global_Data.p_curr_health == local_health and Player_Global_Data.p_curr_mana == local_mana, "23 remote hits do not change local singleton stats")
	check(not remote.is_processing_unhandled_input(), "23 remote Player does not process local input")
	remote.queue_free()
	await get_tree().process_frame
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	server.close()
	var duplicate := first.duplicate() as SpellData
	duplicate.spell_id = "duplicate-incantation-test"
	Spell_Library.register_spell(duplicate)
	Spell_Library._build_incantation_map()
	check(not Spell_Library.validation_errors.is_empty(), "24 duplicate incantation diagnosed")
	Spell_Library.all_spells.erase(duplicate.spell_id)
	Spell_Library.validation_errors.clear()
	Spell_Library._build_incantation_map()
	check(not Spell_Library.validation_warnings.is_empty(), "24 prefix ambiguity appears in library diagnostics")
	var invalid_chain := self_spell("invalid-chain")
	var cyclic := ConditionalEffect.new()
	cyclic.children.append(cyclic)
	invalid_chain.effects = [cyclic]
	check(not SpellValidator.validate(invalid_chain).is_empty(), "24 cyclic resource rejected during validation")
	cyclic.children.clear()
	var template := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(template)
	template.free()
	var summon := self_spell("summon")
	summon.delivery = SpellData.Delivery.SUMMON
	summon.summon_scene = packed
	summon.effects.clear()
	var summon_context := SpellCastContext.new(a, summon)
	var children_before := get_child_count()
	check(SpellDelivery.dispatch(summon_context) and get_child_count() == children_before + 1, "25 summon delivery creates configured entity")
	get_children().back().queue_free()
	var spawn := SpawnEntityEffect.new()
	spawn.scene = packed
	check(spawn.validate().is_empty() and spawn.execute(summon_context, target), "25 spawn entity is reusable as an effect")
	get_children().back().queue_free()
	var missed_area := self_spell("empty-area")
	missed_area.delivery = SpellData.Delivery.AREA_BURST
	missed_area.aoe_spell_radius = 1
	var missed_context := SpellCastContext.new(a, missed_area)
	missed_context.source_position = Vector2(20000, 20000)
	check(SpellDelivery.dispatch(missed_context), "25 valid empty area still counts as a completed cast")
	var lab_spell: SpellData = load("res://data/magis/examples/physics-force-v2.tres")
	check(SpellValidator.validate(lab_spell).is_empty() and lab_spell.effects.size() == 3, "25 V2 authoring example validates with three effects")
	var parent_transform := Node2D.new()
	parent_transform.position = Vector2(400, 300)
	parent_transform.scale = Vector2(1.5, 1.5)
	add_child(parent_transform)
	var npc_caster := TestActor.new()
	parent_transform.add_child(npc_caster)
	var enemy_spell: SpellData = load("res://data/magis/enemy-spells/pohon-branch.tres")
	var origin := Vector2(50, 75)
	check(npc_caster.casting.request_cast(enemy_spell, origin, Vector2.LEFT), "26 NPC spell uses shared casting service")
	var npc_projectile := parent_transform.get_children().back() as MagicProjectile
	check(npc_projectile != null and npc_projectile._started and npc_projectile.global_position.is_equal_approx(origin), "26 enemy projectile initializes at global origin under transformed parent")
	parent_transform.queue_free()
	var partial_subject := subjectData.new()
	partial_subject.subject_id = "partially-owned"
	partial_subject.contained_spells = [first, legacy]
	Player_Global_Data.add_spell(first)
	check(not Player_Global_Data.has_completed_subject(partial_subject.subject_id), "26 spell ownership does not imply subject completion")
	var incompatible_template := Node.new()
	var incompatible_scene := PackedScene.new()
	incompatible_scene.pack(incompatible_template)
	incompatible_template.free()
	spawn.scene = incompatible_scene
	summon.summon_scene = incompatible_scene
	check(not spawn.execute(summon_context, target) and not SpellDelivery.dispatch(summon_context), "27 incompatible scene roots fail safely")
	var bad := self_spell()
	bad.effects = [null]
	check(not SpellValidator.validate(bad).is_empty(), "17 malformed effect reference diagnosed")
	var bad_hot := HealEffect.new()
	bad_hot.tick_interval = 0
	check(not bad_hot.validate().is_empty(), "17 zero tick interval rejected")
