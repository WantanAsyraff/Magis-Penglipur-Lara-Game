extends Node2D
## Real player, training dummy, floor and physics delivery. Never calls projectile hit handlers.
var checks := 0
var failures := 0
var player: Player
var dummy: TrainingDummy
var received := 0.0
var results: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func wait_physics(seconds: float) -> void:
	var frames := ceili(seconds * Engine.physics_ticks_per_second)
	for i in frames: await get_tree().physics_frame
func _ready() -> void:
	await get_tree().process_frame
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0,320)
	floor_body.collision_layer = 16
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(6000,40)
	floor_body.add_child(shape)
	add_child(floor_body)
	Player_Global_Data.combat_mode = true
	Player_Global_Data.p_moveable = true
	player = load("res://components/characters/player/player.tscn").instantiate()
	player.position = Vector2(0,185)
	add_child(player)
	player.set_physics_process(false)
	player.camera.position_smoothing_enabled = false
	await wait_physics(.1)
	player.camera.force_update_scroll()
	player._enter_casting_stance()
	var original_aim := player.castMarker.position
	var mouse := InputEventMouseMotion.new()
	mouse.position = player.get_global_transform_with_canvas() * Vector2(-250,-80)
	get_viewport().push_input(mouse, true)
	player._update_aim_direction()
	check(player.castMarker.position == original_aim, "Mouse motion no longer changes spell aim")
	player._exit_casting_stance()
	for definition in Spell_Library.all_spells.values():
		await audit(definition)
	await pushing()
	check(results.size() == 42, "All 42 registered spells receive an observed gameplay-outcome check")
	print("LIVE_SPELL_AUDIT: %d checks, %d failures" % [checks,failures])
	for child in get_children(): child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
func audit(spell: SpellData) -> void:
	player.casting.cancel()
	CombatLifecycle.cleanup(player)
	if is_instance_valid(dummy): dummy.queue_free()
	await get_tree().physics_frame
	player.position = Vector2(0,185)
	player.velocity = Vector2.ZERO
	for child in player.get_children():
		if child is SpellMotionImpulse or child is SpellHitTrigger: child.queue_free()
	player.hitbox.clear_all_effects()
	Player_Global_Data.p_curr_health = 200
	Player_Global_Data.p_curr_mana = 400
	Player_Global_Data.learned_spells.assign([spell])
	Player_Global_Data.equipped_spells.assign([spell])
	player.casting.cooldowns.clear()
	player.castMarker.position = Vector2(120,0)
	dummy = load("res://components/NPCs/enemies/dummy/dummy-npc.tscn").instantiate()
	dummy.max_hp = 10000
	var delivery := LegacySpellAdapter.delivery_for(spell)
	var distance := 260.0 if spell.aim_placement else (70.0 if delivery in [SpellData.Delivery.AREA_BURST,SpellData.Delivery.PERSISTENT_AREA,SpellData.Delivery.TRAP] else 180.0)
	dummy.position = Vector2(distance,170)
	add_child(dummy)
	received = 0
	dummy.hitbox.damage_taken.connect(func(amount): received += amount)
	await wait_physics(0.1)
	var start := dummy.global_position
	# Conditions are staged through real statuses, with the same targets used in play.
	for status in ["resonance","brittle","cooled","heated","charged"]: dummy.hitbox.apply_status(status,6,{"amount":1},"",ActiveEffectManager.StackPolicy.REFRESH,1)
	player.hitbox.apply_status("dot",6,{"amount":1,"interval":1.0},"",ActiveEffectManager.StackPolicy.REFRESH,1)
	player.casting.previous_spell = load("res://data/magis/spells/phys-force.tres")
	var hostile: MagicProjectile
	if spell.spell_id in ["phys-vector-reversal","phys-gravitational-lens","phys-time-dilation-zone","phys-phase-cancellation"] or delivery == SpellData.Delivery.SUMMON:
		var source := SpellCastContext.new(dummy, load("res://data/magis/spells/phys-resonate.tres"))
		source.direction = Vector2.UP if spell.spell_id == "phys-gravitational-lens" else Vector2.LEFT
		source.source_position = player.position + Vector2(55,0)
		if spell.aim_placement: source.source_position.x = 260
		SpellDelivery.dispatch(source)
		for child in get_children():
			if child is MagicProjectile and child.source == dummy:
				hostile = child
				hostile.set_physics_process(false)
	player._cast_resolved(spell)
	await wait_physics(spell.cast_time + 0.7)
	if spell.spell_id == "phys-impact-prism": player.hitbox.receive_damage(20,dummy)
	if spell.spell_id == "phys-resonance-threshold":
		for i in 3: dummy.hitbox.receive_damage(1,player)
	var observed := false
	match spell.spell_id:
		"phys-harmonic-stabilization": observed = Player_Global_Data.p_curr_health > 210
		"phys-heat-engine": observed = player.hitbox.effects.has("buff_mana_regen") and player.hitbox.effects.has("buff_cast_speed")
		"phys-impact-prism": observed = player.hitbox.effects.has("buff_damage")
		"phys-inertia-vault", "phys-tunneling-step": observed = player.position.distance_to(Vector2(0,185)) > 50
		"phys-vector-reversal": observed = is_instance_valid(hostile) and hostile.direction.x > 0
		"phys-gravitational-lens": observed = is_instance_valid(hostile) and hostile.direction != Vector2.UP
		"phys-time-dilation-zone": observed = is_instance_valid(hostile) and hostile.local_speed_factor < 1
		"phys-phase-cancellation": observed = not is_instance_valid(hostile) or hostile.is_queued_for_deletion()
		"phys-vortex-well", "phys-angular-vortex", "phys-gravitational-well", "phys-buoyancy-field", "phys-pressure-jet", "phys-magnetic-tether": observed = dummy.position.distance_to(start) > 3
		"phys-momentum-anchor": observed = dummy.hitbox.get_slow_factor() >= 0.75
		"phys-torque-lock": observed = dummy.hitbox.is_silenced() and dummy.hitbox.get_slow_factor() >= 0.85
		"phys-brittle-fracture": observed = dummy.hitbox.effects.has("brittle") and dummy.hitbox.effects.get_entries().any(func(e): return e.key == "brittle" and e.source != "")
		"phys-optical-trap": observed = dummy.hitbox.is_stunned()
		"phys-entropy-leak": observed = dummy.hitbox.effects.has("dot") and dummy.hitbox.effects.has("mana_drain")
		"phys-sonic-pulse": observed = dummy.position.distance_to(start) > 3
		_:
			if delivery == SpellData.Delivery.SUMMON:
				for child in get_children():
					if child is SpellConstruct and child.context.caster == player: observed = true
				if not spell.construct_solid: observed = observed and (not is_instance_valid(hostile) or hostile.is_queued_for_deletion() or hostile.direction.x > 0)
			else: observed = received > (3 if spell.spell_id == "phys-resonance-threshold" else 0)
	check(observed, "Observed real delivery / effect: " + spell.spell_name)
	results.append(spell.spell_id)
func pushing() -> void:
	player.casting.cancel()
	CombatLifecycle.cleanup(player)
	dummy.queue_free()
	await get_tree().physics_frame
	# Bunga's pivot is lower than the player's; radial force points into the floor.
	var enemy: Enemy = load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate()
	enemy.position = Vector2(70,231)
	add_child(enemy)
	enemy.set_physics_process(false)
	player.position = Vector2(0,185)
	player.hitbox.clear_all_effects()
	player.pushback.remaining = 0
	var force_spell: SpellData = load("res://data/magis/spells/phys-force.tres")
	Player_Global_Data.learned_spells.assign([force_spell])
	Player_Global_Data.equipped_spells.assign([force_spell])
	Player_Global_Data.p_curr_mana = 400
	player.casting.cooldowns.clear()
	player.castMarker.position = Vector2(120,0)
	player._cast_resolved(force_spell)
	await wait_physics(.6)
	check(enemy.current_health < enemy.max_health, "Point-blank projectile hits a real enemy instead of spawning past it")
	for child in enemy.get_children():
		if child is SpellMotionImpulse: child.queue_free()
	enemy.position = Vector2(220,231)
	enemy.velocity = Vector2.ZERO
	await wait_physics(.1)
	var original := enemy.position
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = true
	get_viewport().push_input(event)
	await wait_physics(.35)
	check(player.pushback.remaining > 0 and enemy.position.x > original.x + 250, "Physical E strongly displaces a grounded production monster while sliding along the floor")
	event.pressed = false
	get_viewport().push_input(event)
