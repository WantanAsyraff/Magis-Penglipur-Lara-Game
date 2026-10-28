extends RefCounted
const FOLDER := "res://docs/previews/combat-save-v1/"
static func capture(driver: Node) -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Captures require an actual rendering display")
		return
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var tree := driver.get_tree()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		driver.get_window().size = resolution
		driver.get_window().content_scale_size = resolution
		await SaveManager.load_slot(3)
		SaveManager._autosave_pending = false
		var player := Player_Manager.get_local_player() as Player
		player.set_physics_process(false)
		Player_Global_Data.combat_mode = true
		player.camera.position_smoothing_enabled = false
		player.camera.global_position = player.global_position
		player.camera.reset_smoothing()
		var tag := str(resolution.x)
		player.hitbox.effects.apply("buff_speed",12,{"amount":.1},"preview",ActiveEffectManager.StackPolicy.STACK,3,true)
		player.hitbox.effects.apply("buff_speed",9,{"amount":.1},"preview2",ActiveEffectManager.StackPolicy.STACK,3,true)
		player.hitbox.effects.apply("hot",8,{"amount":2},"preview",ActiveEffectManager.StackPolicy.STACK,3,true)
		await _shot(driver,"01-buffs-stacks-"+tag)
		player.hitbox._apply_slow(.2,10)
		player.hitbox._apply_dot(1,1,8)
		await _shot(driver,"02-debuffs-"+tag)
		player._enter_casting_stance()
		await _shot(driver,"03-minimal-assistant-"+tag)
		var direction := player.incantations.get_valid_next_keys()[0]
		player._add_sequence(direction)
		await _shot(driver,"04-accepted-input-particles-"+tag,.055)
		# A second actual camera view makes the intentionally tiny burst inspectable.
		player.camera.zoom = Vector2(1.6,1.6)
		player._add_sequence(player.incantations.get_valid_next_keys()[0])
		await _shot(driver,"04b-particle-closeup-"+tag,.1)
		player.camera.zoom = Vector2(.7,.7)
		player.hitbox.effects.tick(100)
		await _shot(driver,"05-expired-"+tag)
		player._exit_casting_stance()
		player.camera._toggle_pause()
		var pause := player.camera.get_node("UI/PauseMenu")
		pause._save_now()
		await _shot(driver,"06-manual-save-confirmation-"+tag)
		tree.paused = false
		# Ensure screenshots never overwrite the fresh-process fixture's expected state.
		GameSaveStore.write(SaveManager.path_for(3),driver.fixture,false)
		tree.change_scene_to_file("res://scenes/ui/menus/intro-menus/new-game-menu.tscn")
		await _shot(driver,"07-new-game-"+tag)
		tree.change_scene_to_file("res://scenes/ui/menus/intro-menus/load-menu.tscn")
		await _shot(driver,"08-load-slots-"+tag)
		await SaveManager.load_slot(3)
		Player_Manager.get_local_player().set_physics_process(false)
		await _shot(driver,"09-restored-scene-"+tag)
		Player_Global_Data.p_curr_health = 0
		await SaveManager.recover_after_death()
		Player_Manager.get_local_player().set_physics_process(false)
		await _shot(driver,"10-checkpoint-recovery-"+tag)
	print("SAVE_V1_PREVIEW: 22 actual renderer captures saved to "+FOLDER)

static func _shot(driver: Node, name: String, delay: float = .2) -> void:
	await driver.get_tree().create_timer(delay,true).timeout
	await RenderingServer.frame_post_draw
	var error := driver.get_viewport().get_texture().get_image().save_png(FOLDER+name+".png")
	if error != OK: push_error("Capture failed: "+error_string(error))
