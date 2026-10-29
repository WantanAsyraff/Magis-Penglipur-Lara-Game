extends RefCounted
# Renderer evidence uses the same physical interaction/casting events as the gameplay suite.
static func frames(lab: EnvironmentLab, count: int) -> void:
	for i in count: await lab.get_tree().physics_frame
static func tap(lab: EnvironmentLab, code: int, down: bool = true) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = down
	lab.get_viewport().push_input(event,true)
static func press(lab: EnvironmentLab, code: int) -> void:
	tap(lab,code); tap(lab,code,false)
static func use(lab: EnvironmentLab, prop: Node2D) -> void:
	lab.player.global_position = prop.global_position+Vector2(-65,0); lab.player.velocity = Vector2.ZERO
	await frames(lab,4); press(lab,KEY_F); await frames(lab,4)
static func chill(lab: EnvironmentLab, prop: Node2D) -> void:
	lab.player.environment_target.clear(); lab.player.global_position = prop.global_position+Vector2(-180,0); lab.player.velocity = Vector2.ZERO
	await frames(lab,4); press(lab,KEY_R); tap(lab,KEY_O)
	for direction in lab.LOADOUT[0].spell_incantation: press(lab,{"up":KEY_I,"down":KEY_K,"left":KEY_J,"right":KEY_L}[direction])
	tap(lab,KEY_O,false); await frames(lab,100); press(lab,KEY_O)
static func shot(lab: EnvironmentLab, folder: String, name_: String) -> void:
	await frames(lab,5); await RenderingServer.frame_post_draw
	var result := lab.get_viewport().get_texture().get_image().save_png(folder+name_+".png")
	if result != OK: push_error("Capture failed: "+name_)
static func capture(lab: EnvironmentLab) -> void:
	if DisplayServer.get_name() == "headless": lab.get_tree().quit(1); return
	var size := Vector2i(1280,720) if "--720" in OS.get_cmdline_user_args() else Vector2i(1920,1080)
	lab.get_window().size = size; lab.get_window().content_scale_size = size
	lab.get_node("LabCamera").zoom = Vector2.ONE*size.x/1920.0
	var folder := "res://docs/previews/environment/%dx%d/" % [size.x,size.y]
	DirAccess.make_dir_recursive_absolute(folder)
	lab.player.hitbox.set_invincible(true)
	for index in range(1,13):
		lab.visit(index); lab.reset_station(); await frames(lab,5)
		var station := lab.get_node("Stations/Station%02d" % index)
		match index:
			1,2:
				await use(lab,station.get_node("Fuse")); await use(lab,station.get_node("Switch"))
			3:
				await use(lab,station.get_node("Valve")); await use(lab,station.get_node("Tap")); await frames(lab,60)
			4:
				await use(lab,station.get_node("Power")); await use(lab,station.get_node("Valve")); await frames(lab,600)
			5: await use(lab,station.get_node("Power")); await frames(lab,40)
			6:
				await chill(lab,station.get_node("Debris")); await chill(lab,station.get_node("Debris")); await frames(lab,100)
			7:
				lab.player.global_position = station.global_position+Vector2(610,440)
				Input.action_press("move_right")
				for i in 240:
					await frames(lab,1)
					if station.get_node("Crate").position.x >= 970: break
				Input.action_release("move_right"); await frames(lab,20)
			8:
				await chill(lab,station.get_node("Receiver"))
				lab.player.global_position = station.get_node("Platform").global_position+Vector2(0,-48); await frames(lab,30)
			9:
				await use(lab,station.get_node("Start")); lab.player.global_position = station.get_node("Turret").global_position+Vector2(-450,0); await frames(lab,55)
			10: await chill(lab,station.get_node("Barrier"))
			11:
				await chill(lab,station.get_node("ReceiverA")); await chill(lab,station.get_node("ReceiverB"))
			12:
				await use(lab,station.get_node("Power")); lab.player.global_position = station.get_node("Platform").global_position+Vector2(0,-48); await frames(lab,50)
		await shot(lab,folder,"station-%02d" % index)
		if index in [2,4,8,9]: await shot(lab,folder,"puzzle-"+{2:"A",4:"B",8:"C",9:"D"}[index])
	print("ENVIRONMENT_PREVIEW: 16 renderer captures at ",size)
	lab.get_tree().quit()
