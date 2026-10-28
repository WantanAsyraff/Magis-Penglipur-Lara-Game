extends Node
const ROOM := preload("res://scenes/combat/boss-prototype-room.tscn")
const DATA := "res://data/npc/enemies/boss/resonance-guardian/"
var checks := 0
var failures := 0
var room: BossPrototypeRoom
var casts: Array[SpellCastContext] = []
var deaths := 0
var transitions: Array[int] = []

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + description)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout

func attack(file: String) -> BossAttackData:
	return load(DATA + file + ".tres") as BossAttackData

func owned(source: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group("combat_owned"):
		if node.get_meta("combat_owner", null) == source and not node.is_queued_for_deletion(): result.append(node)
	return result

func prepare(definition: BossAttackData, boss_position := Vector2(1300, 380), player_position := Vector2(1100, 366)) -> void:
	var boss := room.boss
	boss.set_physics_process(false)
	boss._interrupt_attack("Test fixture")
	boss.attack_timer.stop()
	boss.hurt_timer.stop()
	boss.hitbox.clear_all_effects()
	boss.global_position = boss_position
	room.player.global_position = player_position
	room.player.velocity = Vector2.ZERO
	boss._player = room.player
	boss.current_attack = definition
	boss._can_attack = true
	boss.current_state = Boss.State.IDLE
	boss._set_state(Boss.State.ATTACK)

func _ready() -> void:
	await get_tree().process_frame
	await run()
	if is_instance_valid(room): room.queue_free()
	await get_tree().process_frame
	print("BOSS_PROTOTYPE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func run() -> void:
	var original_learned := Player_Global_Data.learned_spells.duplicate()
	var original_events := QuestManager.seen_events.duplicate()
	var original_spells := Player_Global_Data.equipped_spells.duplicate()
	var original_health := Player_Global_Data.p_curr_health
	var original_mana := Player_Global_Data.p_curr_mana
	var original_xp := Player_Global_Data.player_exp
	var original_money := Player_Global_Data.p_curr_ringgit
	room = ROOM.instantiate() as BossPrototypeRoom
	room.intro_duration = .02
	add_child(room)
	await room.initialized
	check(Player_Global_Data.learned_spells == original_learned, "Training loadout never grants permanent learned spells")
	check(room.state == BossPrototypeRoom.State.READY, "Arena loads into READY with an explicit encounter trigger")
	check(is_instance_valid(room.player) and is_instance_valid(room.boss), "Production player and inherited Boss spawn")
	check(room.player.camera is PlayerCamera and room.get_node("ArenaCamera").is_current(), "Fixed arena framing reuses the existing PlayerCamera HUD")
	check(not room.player.get_node("PlayerDeathComponent").is_processing(), "Prototype owns defeat routing without editing shared player death behavior")
	check(room.boss.phases.size() == 3 and room.boss.max_health == 500, "Guardian has three authored phases and 500 HP")
	check(room.boss.phases[1].enter_at_health_ratio == .65 and room.boss.phases[2].enter_at_health_ratio == .3, "Authored thresholds are 65 and 30 percent")
	check(room.boss.phases[0].chase_speed < room.boss.phases[1].chase_speed and room.boss.phases[1].chase_speed < room.boss.phases[2].chase_speed, "Phase movement escalates from slow to fast")
	for phase in room.boss.phases:
		check(not phase.attacks.is_empty(), "Phase attack pool: " + phase.phase_name)
		for entry in phase.attacks:
			if entry.ranged_spell:
				check(SpellValidator.validate(entry.ranged_spell).is_empty(), "Boss projectile passes shared SpellValidator: " + entry.attack_name)
	check(room.boss.hitbox.is_invincible() and not room.boss.combat_enabled, "READY cannot damage or prematurely start the boss")
	await wait(.15)
	check(room.player.is_on_floor() and room.boss.is_on_floor(), "Both spawns settle safely on the solid floor")
	await room.begin_encounter()
	check(room.state == BossPrototypeRoom.State.ACTIVE and Player_Global_Data.combat_mode, "INTRO activates combat mode and the encounter")
	room.player.set_physics_process(false)
	room.boss.set_physics_process(false)
	room.boss.perception.scan()
	room.boss._physics_process(.016)
	room.boss.set_physics_process(false)
	check(room.boss._player == room.player, "Boss acquires the actual player through shared perception")
	check(not room.boss.hitbox.is_invincible(), "Initial combat has no permanent invulnerability")
	room.boss.casting.cast_completed.connect(func(context): casts.append(context))
	room.boss.boss_died.connect(func(): deaths += 1)
	room.boss.phase_changed.connect(func(index, _phase): transitions.append(index))
	var slam := attack("melee-slam")
	prepare(slam)
	var health := Player_Global_Data.p_curr_health
	check(is_instance_valid(room.boss.telegraph) and room.boss.telegraph.attack == slam, "Melee exposes the same attack resource as its visible warning")
	check(room.boss.telegraph.attack.melee_range == 240 and room.boss.telegraph.attack.melee_arc_degrees == 150, "Melee warning matches the damage range and directional arc")
	await wait(.3)
	check(Player_Global_Data.p_curr_health == health, "Melee does no damage during windup")
	await wait(.5)
	check(Player_Global_Data.p_curr_health == health - slam.melee_damage, "Phase 1 slam resolves shared damage after the warning")
	check(room.boss.current_state == Boss.State.RECOVERY and not room.boss._can_attack, "Resolved attack enters a mandatory recovery window")
	var cooldown := room.boss.attack_timer.time_left
	for i in 4: room.boss.hitbox.receive_damage(1, room.player)
	check(not room.boss._can_attack and room.boss.attack_timer.time_left >= cooldown - .05, "Repeated damage never bypasses the attack recovery gate")
	prepare(slam)
	health = Player_Global_Data.p_curr_health
	room.boss.hitbox._apply_stun(.2)
	room.boss._physics_process(.016)
	check(room.boss.telegraph == null and room.boss.current_attack == null and not room.boss._can_attack, "Stun removes the warning and interrupts with recovery")
	await wait(.85)
	check(Player_Global_Data.p_curr_health == health and room.boss.current_state != Boss.State.ATTACK, "Interrupted windup never lands late damage or leaves ATTACK stuck")
	await wait(.5)
	check(room.boss._can_attack and not room.boss.hitbox.is_stunned(), "Boss safely recovers from stun")
	var paused_casts := casts.size()
	prepare(attack("ranged-shot"), Vector2(1700,380), Vector2(1000,366))
	get_tree().paused = true
	await get_tree().create_timer(1.0, true).timeout
	check(casts.size() == paused_casts and is_instance_valid(room.boss.telegraph), "Pausing freezes a ranged windup instead of firing through the pause menu")
	get_tree().paused = false
	await wait(.9)
	check(casts.size() == paused_casts + 1, "Unpausing resumes the same attack safely")
	CombatLifecycle.cleanup(room.boss)
	var before_casts := casts.size()
	prepare(attack("ranged-shot"), Vector2(1700,380), Vector2(1000,366))
	await wait(.9)
	check(casts.size() == before_casts + 1 and casts.back().caster == room.boss, "Phase 1 single shot executes through SpellCastingComponent")
	check(casts.back().spell.spell_scene == load("res://components/projectiles/enemy-magis-projectile.tscn"), "Ranged attacks use the shared Magis projectile scene")
	check(owned(room.boss).any(func(node): return node is MagicProjectile and node._started), "Shared projectiles are initialized and owned by the boss")
	CombatLifecycle.cleanup(room.boss)
	room.boss._interrupt_attack("Fixture reset")
	room.boss.global_position = Vector2(1500,380)
	room.player.global_position = Vector2(1000,366)
	room.player.castMarker.position = Vector2(120,0)
	var hp := room.boss.current_health
	room.player._cast_resolved(BossPrototypeRoom.LOADOUT[0])
	await wait(.85)
	check(QuestManager.seen_events == original_events, "Prototype casts do not publish campaign quest progress or autosave receipts")
	check(room.boss.current_health < hp, "Production player Magis spell hits the boss's enemy collision layer and reduces HP")
	prepare(slam)
	health = Player_Global_Data.p_curr_health
	hp = room.boss.current_health
	room.boss.hitbox.receive_damage(hp - 320, room.player)
	check(room.boss.current_phase_index == 1 and room.boss.current_state == Boss.State.PHASE_TRANSITION, "65 percent threshold enters Phase 2")
	check(room.boss.current_health == 320 and room.boss.telegraph == null, "Phase change cancels the attack without restoring health")
	check(room.boss.hitbox.is_invincible() and room.health_ui.phase_label.text.contains("Gema"), "Transition protection and HUD phase label agree")
	room.boss.hitbox.receive_damage(1000, room.player)
	check(room.boss.current_health == 320, "Repeated hits during transition cannot chain invalid transitions or kill through protection")
	await wait(1.1)
	check(not room.boss.hitbox.is_invincible() and room.boss.current_state != Boss.State.PHASE_TRANSITION, "Transition protection ends after its configured second")
	check(Player_Global_Data.p_curr_health == health, "Pre-transition delayed attack cannot damage the player later")
	before_casts = casts.size()
	prepare(attack("ranged-double"), Vector2(1700,380), Vector2(1000,366))
	await wait(1.0)
	check(casts.size() == before_casts + 2, "Phase 2 twin burst preserves configured count and interval")
	CombatLifecycle.cleanup(room.boss)
	Player_Global_Data.p_curr_health = 400
	prepare(attack("dash-attack"), Vector2(2200,380), Vector2(2320,366))
	health = Player_Global_Data.p_curr_health
	var dash_start := room.boss.global_position
	check(room.boss.telegraph.dash_length <= 130 and room.boss.telegraph.duration >= .5, "Dash shows a boundary-clipped path and at least half-second warning")
	room.boss.set_physics_process(true)
	await wait(.35)
	check(room.boss.global_position.distance_to(dash_start) < 3 and Player_Global_Data.p_curr_health == health, "Dash warning precedes movement and damage")
	await wait(.36)
	get_tree().paused = true
	var paused_position := room.boss.global_position
	var paused_health := Player_Global_Data.p_curr_health
	await get_tree().create_timer(.3, true).timeout
	check(room.boss.global_position == paused_position and Player_Global_Data.p_curr_health == paused_health, "Pausing an active dash freezes movement and contact damage")
	get_tree().paused = false
	await wait(.75)
	room.boss.set_physics_process(false)
	check(room.boss.global_position.x <= 2331 and room.boss.is_on_wall(), "Dash stops at the arena boundary using real body collision")
	check(Player_Global_Data.p_curr_health == health - attack("dash-attack").melee_damage, "One dash can damage the selected player only once")
	room.boss.hitbox.receive_damage(room.boss.current_health - 145, room.player)
	check(room.boss.current_phase_index == 2 and room.boss.current_health == 145, "30 percent threshold enters Phase 3 without a health refill")
	await wait(1.1)
	check(not room.boss.hitbox.is_invincible(), "Final phase transition protection expires")
	var aoe := attack("aoe-shockwave")
	prepare(aoe)
	health = Player_Global_Data.p_curr_health
	check(room.boss.telegraph.attack.aoe_radius == aoe.aoe_radius and room.boss.telegraph.duration == 1.0, "AoE visibly warns at the actual authored radius for one second")
	await wait(.45)
	check(Player_Global_Data.p_curr_health == health, "AoE warning precedes all damage")
	await wait(.65)
	check(Player_Global_Data.p_curr_health == health - aoe.aoe_damage, "Phase 3 shockwave applies shared damage after the warning expires")
	prepare(aoe)
	await wait(.2)
	room.player.global_position = Vector2(2200,366)
	health = Player_Global_Data.p_curr_health
	await wait(.9)
	check(Player_Global_Data.p_curr_health == health, "Leaving the warning radius avoids the shockwave")
	before_casts = casts.size()
	prepare(attack("ranged-burst"), Vector2(1700,380), Vector2(1000,366))
	await wait(1.1)
	check(casts.size() == before_casts + 3, "Phase 3 burst fires exactly three shared projectiles")
	check(transitions == [1,2], "Thresholds announce each entered phase exactly once")
	CombatLifecycle.cleanup(room.boss)
	prepare(aoe)
	health = Player_Global_Data.p_curr_health
	room.boss.hitbox.receive_damage(10000, room.player)
	room.boss._on_death()
	check(deaths == 1 and room.state == BossPrototypeRoom.State.VICTORY, "Boss dies once and the room enters VICTORY")
	check(room.menu.visible and room.retry_button.visible, "Victory offers retry and exit")
	await wait(1.1)
	check(Player_Global_Data.p_curr_health == health and get_tree().get_nodes_in_group("boss_telegraph").is_empty(), "Death cancels delayed callbacks and all telegraphs")
	check(get_tree().get_nodes_in_group("spell_projectile").is_empty(), "Victory cleans up boss and player projectiles")
	var old_player := room.player
	await room.retry_encounter()
	check(room.state == BossPrototypeRoom.State.ACTIVE and not is_instance_valid(old_player), "Retry replaces old entities and restarts without reloading the scene")
	check(room.boss.current_health == 500 and room.boss.current_phase_index == 0 and room.boss.casting.cooldowns.is_empty(), "Retry resets boss health, phase and cooldowns")
	check(Player_Global_Data.p_curr_health == 400 and Player_Global_Data.p_curr_mana == 400, "Retry restores configured health and mana")
	check(room.boss.global_position.distance_to(room.get_node("BossSpawn").position) < 10, "Retry restores the boss spawn position")
	room.boss.set_physics_process(false)
	room.player.set_physics_process(false)
	room.boss.hitbox.receive_damage(400, room.player)
	check(room.boss.current_phase_index == 2 and room.boss.current_health == 100, "A hit crossing both thresholds selects the deepest valid phase directly")
	await wait(1.1)
	prepare(slam)
	room.player.is_dashing = true
	room.player.hitbox.receive_damage(10000, room.boss)
	check(room.state == BossPrototypeRoom.State.DEFEAT and not room.boss.combat_enabled, "Player defeat safely stops boss execution")
	check(Player_Global_Data.p_moveable and room.retry_button.visible and not Player_Global_Data.is_dashing, "Defeat leaves retry available without locked movement or a stale dash")
	await wait(.85)
	check(room.boss.telegraph == null and owned(room.boss).is_empty(), "Defeat removes active warnings and owned attacks")
	await room.retry_encounter()
	check(room.state == BossPrototypeRoom.State.ACTIVE and room.boss.current_health == 500 and Player_Global_Data.is_alive(), "Retry after defeat produces a fresh playable encounter")
	check(Player_Global_Data.player_exp == original_xp and Player_Global_Data.p_curr_ringgit == original_money, "Repeated encounters grant no repeatable XP or currency")
	room.queue_free()
	await get_tree().process_frame
	check(Player_Global_Data.equipped_spells == original_spells and Player_Global_Data.p_curr_health == original_health and Player_Global_Data.p_curr_mana == original_mana, "Leaving the prototype restores the caller's loadout and resources")
