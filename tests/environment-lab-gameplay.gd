extends Node2D
var checks := 0
var failures := 0
var lab: EnvironmentLab
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func key(code: int, down: bool = true) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = down
	get_viewport().push_input(event,true)
func tap(code: int) -> void:
	key(code); key(code,false)
func prop(index: int, name_: String) -> Node2D:
	return lab.get_node("Stations/Station%02d/" % index+name_)
func place(at: Vector2) -> void:
	lab.player.global_position = at; lab.player.velocity = Vector2.ZERO; lab.player.reset_physics_interpolation()
func use(index: int, name_: String) -> void:
	place(prop(index,name_).global_position+Vector2(-65,0)); await frames(3); tap(KEY_F); await frames(3)
func chill(target: Node2D) -> void:
	lab.player.environment_target.clear(); place(target.global_position+Vector2(-180,0)); await frames(3)
	tap(KEY_R)
	key(KEY_O)
	for direction in lab.LOADOUT[0].spell_incantation:
		tap({"up":KEY_I,"down":KEY_K,"left":KEY_J,"right":KEY_L}[direction])
	key(KEY_O,false)
	await frames(100); tap(KEY_O)
func _ready() -> void:
	await get_tree().process_frame
	var learned := Player_Global_Data.learned_spells.duplicate(); var equipped := Player_Global_Data.equipped_spells.duplicate()
	lab = load("res://scenes/environment-testing/environment-interactions-lab.tscn").instantiate(); add_child(lab)
	await lab.initialized; await frames(4)
	check(lab.get_node("Stations").get_child_count() == 12,"All twelve labelled stations are instantiated")
	check(not SaveManager.unavailable_reason().is_empty(),"Standalone lab cannot write campaign saves")
	lab.visit(2); await use(2,"Fuse"); await use(2,"Switch")
	check(prop(2,"Door").actuator.output and prop(2,"Door").collision.disabled,"Puzzle A: physical F inputs restore fuse, switch and door")
	lab.reset_station(); await frames(4)
	check(not prop(2,"Door").actuator.output and not prop(2,"Switch").actuator.powered,"Station reset restores the entire circuit")
	lab.visit(4)
	await use(4,"Power"); await use(4,"Valve")
	place(lab.get_node("Stations/Station04").global_position+Vector2(150,400))
	await frames(600)
	var source: EnvironmentDevice = prop(4,"Source"); var destination: EnvironmentDevice = prop(4,"Destination")
	var crate: EnvironmentCrate = prop(4,"Crate"); var pool: WaterVolume2D = prop(4,"Pool")
	check(destination.volume > 99 and is_equal_approx(source.volume+destination.volume,100),"Puzzle B: real pump physics fills pool without creating water")
	check(crate.global_position.y < pool.global_position.y-60,"Buoyancy raises the floating crate with the surface")
	check(crate.position.x > 1200,"Water current transports the floating object")
	check(prop(4,"Plate").actuator.output and prop(4,"Door").actuator.output,"Floating crate reaches elevated plate and opens the gate")
	place(pool.global_position+Vector2(0,-60)); await frames(6)
	var swim_start := lab.player.global_position
	var was_immersed := lab.player.water_movement.volumes.has(pool)
	Input.action_press("move_left"); await frames(20); Input.action_release("move_left")
	check(was_immersed and lab.player.global_position.x < swim_start.x-20,"Player traverses actual water through movement controls")
	lab.visit(7); place(prop(7,"Crate").global_position+Vector2(-90,-20)); await frames(4)
	Input.action_press("move_right")
	for i in 240:
		await frames(1)
		if prop(7,"Crate").position.x >= 970: break
	Input.action_release("move_right"); await frames(20)
	check(prop(7,"Plate").actuator.output and prop(7,"Crate").position.x > 900,"Walking contact pushes the weighted physics crate onto its plate")
	lab.visit(5); var fan_crate_start: Vector2 = prop(5,"LightCrate").position
	await use(5,"Power"); await frames(40)
	check(prop(5,"LightCrate").position.distance_to(fan_crate_start) > 50,"Powered fan airflow moves a compatible light physics object")
	lab.visit(8); await frames(6)
	check(not lab.player.water_movement.volumes.has(pool) and Player_Global_Data.p_moveable,"Leaving water clears swimming membership without locking movement")
	await chill(prop(8,"Receiver"))
	check(prop(8,"Receiver").actuator.output,"Physical R + O + incantation keys deliver real Kinetic Chill")
	check(prop(8,"Relay").actuator.output and prop(8,"Platform").actuator.output,"Puzzle C: actual spell powers relay and lift")
	# Start riding from the lower stop, away from receiver geometry.
	var platform: EnvironmentMovingPlatform = prop(12,"Platform")
	lab.visit(12); platform.actuator.receive(false,EnvironmentLink.Port.ENABLE)
	place(platform.global_position+Vector2(0,-48)); await frames(45)
	var player_start := lab.player.global_position; var start := platform.global_position
	platform.actuator.receive(true,EnvironmentLink.Port.ENABLE); await frames(65)
	check(platform.global_position.y < start.y-80,"Platform body moves during actual physics frames")
	check(lab.player.global_position.y < player_start.y-70 and lab.player.is_on_floor(),"Player stands on and rides the moving physics body")
	platform.actuator.receive(false,EnvironmentLink.Port.POWER); await frames(2)
	var held := platform.global_position; await frames(30)
	check(platform.global_position.is_equal_approx(held),"Power loss holds platform halfway through travel")
	platform.actuator.receive(true,EnvironmentLink.Port.POWER); await frames(30)
	check(not platform.global_position.is_equal_approx(held),"Restoring power resumes the interrupted route")
	lab.visit(9); await use(9,"Start")
	place(prop(9,"Turret").global_position+Vector2(-400,0)); await frames(40)
	var hp := Player_Global_Data.p_curr_health
	await frames(100)
	check(prop(9,"Turret").shots_fired > 0 and Player_Global_Data.p_curr_health < hp,"Puzzle D: turret warning leads to actual projectile damage")
	Player_Global_Data.p_curr_health = 3; await frames(150)
	check(Player_Global_Data.p_curr_health == 1,"Training projectiles stop at one HP without killing the player")
	await use(9,"Disable"); var shots: int = prop(9,"Turret").shots_fired
	await frames(140)
	check(not prop(9,"Turret").actuator.output and shots == prop(9,"Turret").shots_fired,"Physical F emergency cut stops future turret attacks")
	lab.reset_room(); await frames(5)
	check(prop(4,"Destination").volume == 0 and not prop(8,"Receiver").actuator.output,"Room reset reproduces both water and spell puzzles")
	lab.free(); await frames(3)
	check(Player_Global_Data.learned_spells == learned and Player_Global_Data.equipped_spells == equipped,"Leaving lab restores the campaign loadout")
	print("ENVIRONMENT_LAB_GAMEPLAY: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
