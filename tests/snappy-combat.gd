extends Node
const Actor = preload("res://tests/spell-regression.gd").TestActor
var checks := 0
var failures := 0
var completed := false
var player: Player
var casts: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func definition(id: String, keys: Array[String], prepare: float = 0.0) -> SpellData:
	var spell := SpellData.new()
	spell.spell_id = id
	spell.spell_name = id
	spell.spell_incantation = keys
	spell.delivery = SpellData.Delivery.SELF
	spell.cast_time = prepare
	spell.recovery_time = 2.0
	spell.cooldown = 3.0
	spell.upfront_cost = 2
	var heal := HealEffect.new()
	heal.amount = 1
	spell.effects = [heal]
	return spell

func body(point: Vector2, team: StringName = &"enemy") -> CharacterBody2D:
	var actor := Actor.new()
	actor.position = point
	actor.collision_layer = 2
	actor.collision_mask = 19
	actor.set_meta("spell_team", team)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 15
	actor.add_child(shape)
	add_child(actor)
	actor.set_physics_process(false)
	actor.hitbox.receives_knockback = true
	PlayerEnemyCollision.configure(actor)
	return actor

func key(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	player._unhandled_input(event)

func _ready() -> void:
	await get_tree().process_frame
	await run()
	check(completed, "Suite reaches completion")
	print("SNAPPY_COMBAT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func run() -> void:
	Player_Global_Data.combat_mode = true
	Player_Global_Data.p_moveable = true
	Player_Global_Data.p_curr_health = 200
	Player_Global_Data.p_curr_mana = 200
	var a := definition("snappy_a", ["up", "down"], 0.3)
	var b := definition("snappy_b", ["left", "right"])
	var c := definition("snappy_c", ["right", "up"])
	Player_Global_Data.learned_spells.assign([a,b,c])
	Player_Global_Data.equipped_spells.assign([a,b,c])
	var before := body(Vector2(100, 0))
	player = load("res://components/characters/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.casting.set_physics_process(false)
	player.pushback.set_physics_process(false)
	player.hitbox.set_physics_process(false)
	player.hitbox.set_invincible(false)
	player.casting.cast_completed.connect(func(context): casts.append(context.spell.spell_id))
	key("start_incantation")
	key("incantation_up")
	key("incantation_down")
	key("incantation_left")
	key("incantation_right")
	key("incantation_right")
	key("incantation_up")
	check(casts.is_empty() and player.casting._queue.size() == 2, "Same-frame key events buffer both following combos during preparation")
	player.casting._physics_process(0.3)
	check(casts == [a.spell_id,b.spell_id,c.spell_id], "All instant follow-ups dispatch on preparation completion without recovery or frame gaps")
	check(player.casting.state == SpellCastingComponent.State.IDLE and Player_Global_Data.p_curr_mana == 194, "Each chained cast pays exactly once")
	key("incantation_up")
	key("incantation_down")
	check(casts.size() == 3 and Player_Global_Data.p_curr_mana == 194, "Immediate repeated spell still respects its own cooldown without charging mana")
	player.casting._physics_process(3.0)
	player._clear_sequence()
	key("incantation_left")
	key("incantation_right")
	check(casts.size() == 4, "Spell can be reused when its own cooldown expires")
	# Non-player actors retain authored recovery.
	var npc := body(Vector2(1500,0)) as Actor
	check(npc.casting.request_cast(b, npc.global_position, Vector2.RIGHT) and npc.casting.state == SpellCastingComponent.State.RECOVERY, "Enemy casting retains authored recovery time")
	npc.free()
	var after := body(Vector2(200,0))
	check(player.get_collision_exceptions().has(before) and before.get_collision_exceptions().has(player), "Enemy-first spawn excludes player body collision in both directions")
	check(player.get_collision_exceptions().has(after) and after.get_collision_exceptions().has(player), "Player-first spawn excludes player body collision in both directions")
	check(not before.get_collision_exceptions().has(after), "Enemies still collide with each other")
	check(player.collision_layer == 1 and player.collision_mask == 27 and before.collision_layer == 2, "Projectile and terrain collision layers remain intact")
	# Use a compact player shape for deterministic swept-body verification.
	player.get_node("CollisionShape2D").shape = CircleShape2D.new()
	player.get_node("CollisionShape2D").shape.radius = 15
	await get_tree().physics_frame
	check(not player.test_move(player.global_transform, Vector2(250,0)), "Physical player sweep passes through monsters")
	check(before.test_move(before.global_transform, Vector2(150,0)), "Monster sweep still blocks against another monster")
	var wall := StaticBody2D.new()
	wall.position = Vector2(300,0)
	wall.collision_layer = 16
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(20,200)
	wall.add_child(shape)
	add_child(wall)
	await get_tree().physics_frame
	check(player.test_move(player.global_transform, Vector2(350,0)), "Physical player sweep still blocks on terrain")
	var outside := body(Vector2(500,0))
	var health: float = before.health
	key("pushback")
	check(is_equal_approx(player.pushback.remaining,4.0), "Pushback starts its four-second cooldown after hitting nearby enemies")
	var motion: SpellMotionImpulse
	for child in before.get_children():
		if child is SpellMotionImpulse: motion = child
	check(motion != null and motion.impulse.x > 0, "Pushback sends enemies away from the player")
	check(outside.get_children().filter(func(child): return child is SpellMotionImpulse).is_empty(), "Out-of-range enemies are not pushed")
	check(not player.pushback.try_push() and before.health == health, "Cooldown blocks repeated pushes and pushback deals no damage")
	var start := before.global_position
	motion._physics_process(0.05)
	check(before.global_position.x > start.x, "Additive pushback actually moves the enemy despite controller velocity")
	var hud: StatusEffectsHUD = player.camera.get_node("UI/StatusEffectsHUD")
	hud.bind_player(player)
	hud.refresh()
	check(hud.visible and hud.push_label.text.contains("4.0s"), "Bottom-left HUD shows the real pushback cooldown with no status effects")
	player.pushback._physics_process(4.0)
	hud.refresh()
	check(hud.push_label.text.contains("Ready") and hud.push_progress.value == 1.0, "HUD returns to Ready when the cooldown expires")
	player.hitbox._apply_stun(1)
	check(not player.pushback.try_push(), "Stun prevents pushback")
	player.hitbox.clear_all_effects()
	for target in [before,after]: target.get_node("HitboxComponent").receives_knockback = false
	check(not player.pushback.try_push() and player.pushback.remaining == 0, "Immune or absent nearby targets do not spend cooldown")
	before.get_node("HitboxComponent").receives_knockback = true
	before.position = Vector2(180,0)
	wall.position.x = 90
	await get_tree().physics_frame
	check(not player.pushback.try_push(), "Terrain obstructs pushback to otherwise reachable enemies")
	wall.position.x = 300
	await get_tree().physics_frame
	var nearby_npc := Node2D.new()
	nearby_npc.position = Vector2(50,0)
	var detector := DetectionComponent.new()
	nearby_npc.add_child(detector)
	add_child(nearby_npc)
	check(not player.pushback.try_push(), "Nearby NPC interaction takes priority over combat pushback")
	nearby_npc.free()
	var interaction := LockedDoor.new()
	var door_shape := CollisionShape2D.new()
	door_shape.name = "CollisionShape2D"
	interaction.add_child(door_shape)
	var area := Area2D.new()
	area.name = "InteractArea"
	interaction.add_child(area)
	interaction.position = Vector2(2000,0)
	add_child(interaction)
	interaction._player_nearby = player
	check(not player.pushback.try_push(), "Nearby door interaction takes priority over combat pushback")
	interaction.free()
	var neutral := body(Vector2(1500,0), &"ally")
	check(not player.get_collision_exceptions().has(neutral), "Neutral actors retain their player body collision")
	neutral.free()
	for target in [before,after,outside]: target.free()
	wall.free()
	var production_enemy: Enemy = load("res://components/NPCs/enemies/Enemy.tscn").instantiate()
	production_enemy.position = Vector2(220,0)
	add_child(production_enemy)
	check(production_enemy.get_collision_exceptions().has(player), "Production monster automatically registers the player collision exception")
	production_enemy.set_physics_process(false)
	production_enemy.chase_speed = 1600
	var chase_profile := EnemyAIProfile.new()
	var chase := EnemyAIAction.new()
	chase.action_id = &"test_chase"
	chase.kind = EnemyAIAction.Kind.CHASE
	chase_profile.actions = [chase]
	chase_profile.range_tolerance = 0
	production_enemy.ai.configure(chase_profile)
	production_enemy.detection.scan()
	production_enemy.ai.decide()
	player.pushback.remaining = 0
	player._stop_moving_locked = true
	Player_Global_Data.p_moveable = false
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.keycode = KEY_E
	press.pressed = true
	get_viewport().push_input(press)
	var live_motion := production_enemy.get_node_or_null("PlayerPushImpulse") as SpellMotionImpulse
	check(live_motion != null and player.pushback.remaining == 4, "Actual physical E reaches Push through the viewport while Stop Mode is active")
	if live_motion:
		live_motion.set_physics_process(false)
		var original_x := production_enemy.global_position.x
		for i in 4:
			production_enemy._physics_process(0.05)
			live_motion._physics_process(0.05)
		check(production_enemy.global_position.x > original_x + 100, "Running fast chase AI cannot cancel the outward push displacement")
		live_motion.remaining = 0
		production_enemy.movement.intent = EnemyAIAction.Kind.CHASE
		production_enemy.detection.visible = true
		production_enemy.movement.tick(0.016)
		check(production_enemy.velocity.x < 0, "Enemy resumes chasing after pushback ends")
	press.pressed = false
	get_viewport().push_input(press)
	Player_Global_Data.p_moveable = true
	player._stop_moving_locked = false
	production_enemy.free()
	await active_buff_icons()
	var boss: Boss = load("res://components/NPCs/enemies/boss/resonance-guardian.tscn").instantiate()
	add_child(boss)
	check(boss.get_collision_exceptions().has(player) and not boss.hitbox.receives_knockback, "Boss excludes player body collision while retaining pushback immunity")
	boss.free()
	await filters()
	completed = true

func filters() -> void:
	var categories := SpellCategoryFilter.Category
	for pair in [["phys-force",categories.RANGED],["phys-heat-engine",categories.BUFF],["phys-harmonic-stabilization",categories.SUPPORT],["phys-tunneling-step",categories.MOVEMENT],["phys-gyroscopic-shield",categories.DEFENSE],["phys-gravitational-well",categories.AREA],["phys-torque-lock",categories.CONTROL]]:
		var spell: SpellData = load("res://data/magis/spells/" + pair[0] + ".tres")
		check(SpellCategoryFilter.matches_category(spell,pair[1]), "Authored spell correctly classified: " + pair[0])
	check(not SpellCategoryFilter.matches_category(load("res://data/magis/spells/phys-thermal-bloom.tres"),categories.SUPPORT), "Offensive conditional status consumption does not misclassify a spell as support")
	check(not SpellCategoryFilter.matches_category(load("res://data/magis/spells/phys-force.tres"),categories.BUFF), "Ranged damage is excluded from the buff filter")
	Player_Global_Data.learned_spells.assign(Spell_Library.all_spells.values())
	Player_Global_Data.equipped_spells.assign([load("res://data/magis/spells/phys-force.tres")])
	for path in ["spell-archives-menu","spell-equipment"]:
		var menu: Control = load("res://scenes/ui/spell-equipment/" + path + ".tscn").instantiate()
		add_child(menu)
		var filter: SpellCategoryFilter = menu.get_node("%CategoryFilter")
		check(filter.item_count == 9, path + " exposes all nine category choices")
		filter.select(categories.SUPPORT)
		filter.item_selected.emit(categories.SUPPORT)
		await get_tree().process_frame
		var cards := menu.get_node("%LearnedSpells").get_children()
		check(not cards.is_empty() and cards.all(func(card): return filter.matches(card.spell_data)), path + " renders only matching support spells")
		if path == "spell-equipment":
			check(menu.get_node("%SpellEquipmentContainer").get_child_count() == 1, "Filtering leaves equipped spells visible for removal")
		else:
			check(filter.matches(Player_Global_Data.selected_spell), "Archive selects a spell from the filtered category")
		Player_Global_Data.learned_spells.clear()
		Player_Global_Data.spells_updated.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		check(menu.get_node("%LearnedSpells").get_child_count() == 0, path + " handles an empty filtered library")
		menu.free()
		Player_Global_Data.learned_spells.assign(Spell_Library.all_spells.values())

func active_buff_icons() -> void:
	var heat: SpellData = load("res://data/magis/spells/phys-heat-engine.tres")
	Player_Global_Data.learned_spells.assign([heat])
	Player_Global_Data.equipped_spells.assign([heat])
	Player_Global_Data.p_curr_mana = 100
	check(player.casting.request_cast(heat,player.global_position,Vector2.RIGHT), "Existing Heat Engine buff casts through production spell service")
	player.casting._physics_process(heat.cast_time)
	var hud: StatusEffectsHUD = player.camera.get_node("UI/StatusEffectsHUD")
	hud.refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	var rows := hud.grouped_entries()
	check(rows.any(func(row): return row.key == "buff_mana_regen") and rows.any(func(row): return row.key == "buff_cast_speed"), "Existing buff spell exposes both real active effects to the HUD")
	check(hud.effect_row.visible and hud.icons[0].visible and hud.icons[1].visible, "Both active buff icons are visible")
	var viewport := get_viewport().get_visible_rect().size
	check(hud.icons[0].get_global_rect().position.x > player.camera.combatUI.get_node("PanelContainer").get_global_rect().end.x and hud.icons[0].get_global_rect().position.y < viewport.y / 2, "Active buffs sit to the right of health and mana")
	check(hud.push_panel.get_global_rect().position.x < viewport.x / 2, "Push cooldown stays independently anchored at the bottom-left")
	player.hitbox.effects.tick(100)
	hud.refresh()
	check(not hud.effect_row.visible and hud.push_panel.visible, "Expired buffs disappear without hiding the ready Push indicator")
