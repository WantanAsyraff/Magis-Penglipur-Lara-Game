extends Node2D
const Actor = preload("res://tests/spell-regression.gd").TestActor
var checks := 0
var failures := 0
var player: Player
var target: Node2D
var moving := false
var moving_time := 0.0
class BodyOutline extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-15,-30,30,60),Color.CYAN,false,2)
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func enemy(point: Vector2) -> Node2D:
	var node := Actor.new()
	node.position = point
	node.set_meta("faction_id",&"enemy")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(30,60)
	node.add_child(shape)
	add_child(node)
	return node
func wall() -> StaticBody2D:
	var node := StaticBody2D.new()
	node.position = Vector2(150,0)
	node.collision_layer = 16
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(20,200)
	node.add_child(shape)
	add_child(node)
	return node
func _physics_process(delta: float) -> void:
	if moving:
		moving_time += delta
		player.position += Vector2(60,10)*delta
		target.position = player.position + Vector2(300+sin(moving_time)*80,sin(moving_time*1.3)*30)
		player.camera.force_update_scroll()
func _ready() -> void:
	await get_tree().process_frame
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	await get_tree().process_frame
	Player_Global_Data.combat_mode = true
	Player_Global_Data.p_curr_health = 200
	player = load("res://components/characters/player/player.tscn").instantiate()
	add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	player.set_physics_process(false)
	player.camera.position_smoothing_enabled = false
	player.camera.make_current()
	player.target_lock.set_physics_process(false)
	var lock := player.target_lock
	var first := enemy(Vector2(180,0))
	target = enemy(Vector2(300,0))
	lock.refresh()
	check(lock.locked_target == first,"Nearest target acquired before stability cases")
	first.position.x = lock.target_range+1
	for i in 10: lock.refresh()
	lock._physics_process(.05)
	check(lock.locked_target == first,"Brief range-boundary flicker retains the selected target")
	first.position.x = 180
	lock._physics_process(.016)
	first.position.x = lock.target_range+1
	lock._physics_process(.1)
	for i in 10: lock.refresh()
	check(lock.locked_target == first,"Repeated aim and draw refreshes cannot consume the loss grace timer")
	lock._physics_process(.06)
	check(lock.locked_target == target,"Sustained range loss reacquires after the grace period")
	first.position.x = 180
	lock.refresh()
	check(lock.locked_target == target,"A returning closer enemy does not steal the lock")
	lock.cycle_target()
	check(lock.locked_target == first,"Q-style cycling remains immediate during retention")
	first.set_meta("combat_dead",true)
	lock.refresh()
	check(lock.locked_target == target,"Dead targets are replaced immediately without grace")
	first.free()
	var blocker := wall()
	await get_tree().physics_frame
	lock._physics_process(.05)
	check(lock.locked_target == target and not lock.eligible(target),"Brief obstruction retains selection while strict cast eligibility remains blocked")
	var spell: SpellData = load("res://data/magis/spells/phys-torque-lock.tres")
	Player_Global_Data.learned_spells.assign([spell])
	Player_Global_Data.equipped_spells.assign([spell])
	var mana_before: float = Player_Global_Data.p_curr_mana
	var errors: Array[String] = []
	player.casting.cast_failed.connect(func(reason): errors.append(reason))
	player._cast_resolved(spell)
	check(not errors.is_empty() and errors.back() == "Invalid target" and Player_Global_Data.p_curr_mana == mana_before,"Retained but obstructed targets cannot receive a new direct cast or consume its mana")
	blocker.free()
	await get_tree().physics_frame
	lock._physics_process(.016)
	check(lock.locked_target == target,"Cleared obstruction restores the same lock without flicker")
	blocker = wall()
	await get_tree().physics_frame
	lock._physics_process(PlayerTargetLock.LOSS_GRACE)
	check(lock.locked_target == null,"Sustained obstruction drops the lock")
	blocker.free()
	await get_tree().physics_frame
	lock.refresh()
	check(lock.reticle.get_parent() == target and lock.reticle.transform == Transform2D.IDENTITY and lock.reticle.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_INHERIT,"Reticle shares the enemy transform and native interpolation, independently of the player")
	var original_ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 10
	target.scale = Vector2(1.5,2)
	player.reset_physics_interpolation()
	target.reset_physics_interpolation()
	moving = true
	lock.set_physics_process(true)
	var outline := BodyOutline.new()
	target.add_child(outline)
	var accurate := true
	var rendered_checks := 0
	for i in 60:
		await get_tree().create_timer(.01).timeout
		var marker := lock.reticle
		accurate = accurate and marker.get_parent() == target and marker.transform == Transform2D.IDENTITY
		accurate = accurate and marker.visual_bounds() == Rect2(-15,-30,30,60)
		if DisplayServer.get_name() != "headless" and i % 10 == 0:
			await RenderingServer.frame_post_draw
			var picture := get_viewport().get_texture().get_image()
			accurate = accurate and stable_pixels(picture,target)
			rendered_checks += 1
	moving = false
	Engine.physics_ticks_per_second = original_ticks
	check(accurate,"At 10 Hz physics the reticle remains aligned with a scaled moving enemy while player and camera move")
	if DisplayServer.get_name() != "headless": check(rendered_checks == 6,"Six actual rendered frames preserve marker/body alignment between slow physics ticks")
	print("TARGET_LOCK_STABILITY: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func stable_pixels(picture: Image, body: Node2D) -> bool:
	var point := body.get_global_transform_with_canvas().origin
	var region := Rect2i(Vector2i(point)-Vector2i(120,150),Vector2i(240,300)).intersection(Rect2i(Vector2i.ZERO,picture.get_size()))
	var cyan_min := Vector2i(99999,99999)
	var cyan_max := Vector2i(-99999,-99999)
	for y in range(region.position.y,region.end.y):
		for x in range(region.position.x,region.end.x):
			var color := picture.get_pixel(x,y)
			if color.r < .15 and color.g > .85 and color.b > .85:
				cyan_min = cyan_min.min(Vector2i(x,y)); cyan_max = cyan_max.max(Vector2i(x,y))
	if cyan_max.x < cyan_min.x:
		print("RENDER_DIAGNOSTIC body missing ",point," ",region)
		picture.save_png("res://.godot/target-jitter-failure.png")
		return false
	var gold_min := Vector2i(99999,99999)
	var gold_max := Vector2i(-99999,-99999)
	for y in range(maxi(region.position.y,cyan_min.y-19),region.end.y):
		for x in range(region.position.x,region.end.x):
			var color := picture.get_pixel(x,y)
			if color.r > .9 and color.g > .65 and color.b < .5:
				gold_min = gold_min.min(Vector2i(x,y)); gold_max = gold_max.max(Vector2i(x,y))
	# Native target scale is 1.5 x 2, camera zoom .7: 12 local units -> 12.6 / 16.8 pixels.
	var result := absi((cyan_min.x-gold_min.x)-13) <= 2 and absi((gold_max.x-cyan_max.x)-13) <= 2 and absi((gold_max.y-cyan_max.y)-17) <= 2
	if not result:
		print("RENDER_DIAGNOSTIC ",cyan_min-gold_min," ",gold_max-cyan_max," point=",point)
		picture.save_png("res://.godot/target-jitter-failure.png")
	return result
