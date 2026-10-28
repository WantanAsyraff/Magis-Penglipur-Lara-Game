extends Node2D
const Actor = preload("res://tests/spell-regression.gd").TestActor
var checks := 0
var failures := 0
var player: Player
var enemies: Array[Node2D] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+label)
func enemy(at: Vector2, team: StringName = &"enemy") -> Node2D:
	var node := Actor.new()
	node.position = at
	node.set_meta("faction_id",team)
	node.set_meta("spell_team",team)
	node.collision_layer = 2
	node.collision_mask = 16
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(30,60)
	node.add_child(shape)
	add_child(node)
	enemies.append(node)
	return node
func press_q(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.keycode = KEY_Q
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	event.echo = false
	get_viewport().push_input(event,true)
func settle() -> void:
	for i in 4: await get_tree().process_frame
func _ready() -> void:
	await get_tree().process_frame
	Player_Global_Data.combat_mode = true
	Player_Global_Data.p_moveable = true
	Player_Global_Data.p_curr_health = 200
	Player_Global_Data.p_curr_mana = 400
	var known: SpellData = load("res://data/magis/spells/phys-force.tres")
	Player_Global_Data.learned_spells.assign([known])
	Player_Global_Data.equipped_spells.assign([known])
	player = load("res://components/characters/player/player.tscn").instantiate()
	add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	Player_Manager.local_player_changed.emit(player)
	player.set_physics_process(false)
	player.target_lock.set_physics_process(false)
	player.casting.set_physics_process(false)
	player.hitbox.set_physics_process(false)
	var near := enemy(Vector2(180,0))
	var middle := enemy(Vector2(-300,0))
	var far := enemy(Vector2(500,0))
	var ally := enemy(Vector2(30,0),&"player")
	var neutral := enemy(Vector2(40,0),&"neutral")
	var distant := enemy(Vector2(2000,0))
	await get_tree().physics_frame
	player._update_aim_direction()
	check(player.target_lock.locked_target == near, "Nearest live hostile is acquired automatically")
	check(player.target_lock.candidates() == [near,middle,far], "Allies, neutrals and out-of-range enemies are excluded; candidates sort by distance")
	press_q()
	check(player.target_lock.locked_target == middle, "Physical Q selects the next-nearest enemy")
	check(player.castMarker.position.x < 0, "Aim follows a selected enemy behind the player")
	press_q(true)
	check(player.target_lock.locked_target == middle, "Held-key repeat never skips multiple enemies")
	press_q()
	check(player.target_lock.locked_target == far, "Q advances through distance order")
	press_q()
	check(player.target_lock.locked_target == near, "Q wraps back to the nearest enemy")
	press_q()
	near.position = Vector2(50,0)
	player._update_aim_direction()
	check(player.target_lock.locked_target == middle, "Selected lock remains stable when another enemy becomes closer")
	var mouse := InputEventMouseMotion.new()
	mouse.position = Vector2(1900,20)
	var original_position := player.global_position
	player.velocity = Vector2(100,0)
	get_viewport().push_input(mouse,true)
	player.velocity = Vector2.ZERO
	check(player.global_position == original_position, "Mouse events cannot step player movement outside physics")
	player._update_aim_direction()
	check(player.target_lock.locked_target == middle and player.castMarker.position.x < 0, "Mouse movement cannot alter locked aiming")
	check(Player_Global_Data.p_moveable, "Cycling targets does not lock movement")
	middle.set_meta("combat_dead",true)
	player._update_aim_direction()
	check(player.target_lock.locked_target == near, "Death reacquires the closest eligible target")
	near.position = Vector2(2200,0)
	player._update_aim_direction()
	check(player.target_lock.locked_target == far, "Leaving lock range reacquires another enemy")
	far.hide()
	player._update_aim_direction()
	check(player.target_lock.locked_target == null, "Hidden enemies cannot retain a lock")
	far.show()
	far.position = Vector2(180,0)
	var wall := StaticBody2D.new()
	wall.position = Vector2(90,0)
	wall.collision_layer = 16
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(20,200)
	wall.add_child(shape)
	add_child(wall)
	await get_tree().physics_frame
	player._update_aim_direction()
	check(player.target_lock.locked_target == null, "Terrain blocks auto-lock and Q candidates")
	wall.free()
	await get_tree().physics_frame
	player._update_aim_direction()
	check(player.target_lock.locked_target == far, "Removing terrain makes the target eligible again")
	player._enter_casting_stance()
	player._add_sequence("up")
	var prefix := player.spell_string.duplicate()
	press_q()
	check(prefix == ["up"] and player.spell_string == prefix and player._in_casting_stance, "Q leaves the current incantation intact")
	player._exit_casting_stance()
	await casts(far)
	far.free()
	player._update_aim_direction()
	check(player.target_lock.locked_target == null, "Freed targets are discarded safely")
	get_tree().paused = true
	check(not player.target_lock.can_cycle(), "Pause blocks target switching")
	get_tree().paused = false
	await hud()
	player.combat_mode = false
	player._update_aim_direction()
	check(player.target_lock.locked_target == null, "Combat exit clears targeting")
	print("TARGET_LOCK_HUD: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
func casts(target: Node2D) -> void:
	var alternate := enemy(Vector2(-350,0))
	var spell: SpellData = load("res://data/magis/spells/phys-force.tres")
	Player_Global_Data.learned_spells.assign([spell])
	Player_Global_Data.equipped_spells.assign([spell])
	player._cast_resolved(spell)
	check(player.casting.context.targets == [target], "An offensive cast records the selected target")
	press_q()
	check(player.target_lock.locked_target == alternate, "Q can switch the current lock while a spell prepares")
	target.position = Vector2(180,-100)
	player.casting._physics_process(spell.cast_time + .01)
	check(player.casting.context.direction.dot(Vector2(180,-100).normalized()) > .99, "Preparation tracks movement of the selected enemy before dispatch")
	check(player.casting.context.targets == [target], "Already accepted casts keep their original enemy after Q switches")
	press_q()
	var direct: SpellData = load("res://data/magis/spells/phys-torque-lock.tres")
	Player_Global_Data.learned_spells.assign([direct])
	Player_Global_Data.equipped_spells.assign([direct])
	player._cast_resolved(direct)
	player.casting._physics_process(direct.cast_time + .01)
	check(target.get_node("HitboxComponent").is_silenced(), "A direct spell applies to the selected locked target")
	var beam: SpellData = load("res://data/magis/spells/phys-refraction-beam.tres")
	Player_Global_Data.learned_spells.assign([beam])
	Player_Global_Data.equipped_spells.assign([beam])
	player._cast_resolved(beam)
	player.casting._physics_process(beam.cast_time+.01)
	var area: SpellAreaDelivery
	for child in get_children():
		if child is SpellAreaDelivery and child.context.spell == beam: area = child
	target.position = Vector2(-180,-120)
	if area: area._physics_process(.01)
	check(area != null and area.context.direction.dot(Vector2(-180,-120).normalized()) > .99, "Active beams follow the recorded enemy's movement")
	if area: area.queue_free()
	Player_Global_Data.learned_spells.assign([direct])
	Player_Global_Data.equipped_spells.assign([direct])
	player.casting.cooldowns.erase(direct.spell_id)
	target.position = Vector2(600,0)
	var mana_before: float = Player_Global_Data.p_curr_mana
	var reasons: Array[String] = []
	player.casting.cast_failed.connect(func(reason): reasons.append(reason))
	player._cast_resolved(direct)
	check(not reasons.is_empty() and reasons.back() == "Invalid target" and Player_Global_Data.p_curr_mana == mana_before, "Auto-lock preserves individual spell range and never charges for an out-of-range direct cast")
	target.position = Vector2(180,-100)
	var phone := player.get_tree().get_first_node_in_group("phone_ui")
	if phone:
		phone.phone_selected = true
		var before := player.target_lock.locked_target
		press_q()
		check(player.target_lock.locked_target == before and not player.target_lock.can_cycle(), "Phone menus intercept target switching")
		phone.phone_selected = false
	alternate.free()
func hud() -> void:
	var display: StatusEffectsHUD = player.camera.get_node("UI/StatusEffectsHUD")
	player.hitbox.effects.apply("buff_speed",10,{"amount":10},"test",ActiveEffectManager.StackPolicy.REFRESH,1,true)
	display.bind_player(player)
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_size = Vector2i.ZERO
	for resolution in [Vector2i(800,600),Vector2i(1280,720),Vector2i(1920,1080)]:
		window.size = resolution
		await settle()
		display.refresh()
		await settle()
		var stats: Control = player.camera.combatUI.get_node("PanelContainer")
		var icon := display.icons[0]
		check(icon.size == Vector2(52,52), "%s buff glyphs and panels render at 52 pixels" % resolution)
		check(icon.get_global_rect().position.x > stats.get_global_rect().end.x and icon.get_global_rect().position.y < stats.get_global_rect().end.y, "%s icons sit beside the health/mana panel on its right" % resolution)
		var fits := true
		for i in 12: player.hitbox.effects.apply("test_%d" % i,10,{})
		display.refresh()
		await settle()
		for item in display.icons:
			if item.visible: fits = fits and item.get_global_rect().end.x <= resolution.x and item.get_global_rect().end.y <= resolution.y
		fits = fits and display.overflow.get_global_rect().end.y <= resolution.y
		check(fits and display.overflow.visible, "%s larger icons wrap within the viewport with overflow" % resolution)
		player.hitbox.clear_all_effects()
		player.hitbox.effects.apply("buff_speed",10,{"amount":10},"test",ActiveEffectManager.StackPolicy.REFRESH,1,true)
