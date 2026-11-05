extends Node
var lab: Node2D
var caption: Label
var folder := "res://docs/previews/environment-destruction/"
var resolution_tag := ""
var shots := 0
func _ready() -> void:
	if DisplayServer.get_name() == "headless": get_tree().quit(2); return
	await get_tree().process_frame
	lab = load("res://scenes/spell-testing/destruction-lab.tscn").instantiate(); lab.debug_mode = false; add_child(lab)
	lab.player.set_physics_process(false); lab.player.hitbox.set_invincible(true)
	lab.player.get_node("PlayerDeathComponent").set_process(false)
	lab.player.camera.get_node("UI").visible = false
	lab.overview.enabled = true; lab.overview.make_current()
	var layer := CanvasLayer.new(); layer.layer = 100; add_child(layer)
	caption = Label.new(); caption.position = Vector2(24,24); caption.add_theme_font_size_override("font_size",20); layer.add_child(caption)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution; get_window().content_scale_size = resolution
		resolution_tag = "%dx%d" % [resolution.x,resolution.y]
		DirAccess.make_dir_recursive_absolute(folder+resolution_tag)
		lab.reset_props(); await get_tree().create_timer(0.1).timeout
		lab.overview.position = Vector2(0,-60); lab.overview.zoom = Vector2.ONE * (float(resolution.x) / 2600.0)
		await capture("01-all-presets","Eight shared-framework presets · intact states")
		var crate: DestructibleObject = lab.props[0]
		# Inspector-equivalent private 50 HP variant gives three readable Force-hit stages.
		crate.config = crate.config.duplicate(true); crate.config.max_health = 50; crate.config.behaviors.clear()
		var crate_component := crate.get_node("DestructibleComponent") as DestructibleComponent
		crate_component.config = crate.config; crate_component.reset_destructible()
		lab.overview.position = crate.global_position + Vector2(-70,-50); lab.overview.zoom = Vector2.ONE * 1.6
		await fire(crate,lab.LOADOUT[0]); await capture("02-damaged","Real Force impact · 50 HP crate · damaged state")
		await fire(crate,lab.LOADOUT[0]); await capture("03-critical","Second Force impact · critical state")
		await fire(crate,lab.LOADOUT[0]); await capture("04-break","Third Force impact · reusable destruction animation")
		await get_tree().create_timer(0.5).timeout
		await capture("05-destroyed","Destroyed state · collision disabled")
		for spec in [[4,"06-explosion","Explosion delivers radial damage"],[6,"07-shrapnel","Physical shrapnel · bounded seeded distribution"],[5,"08-poison","Temporary poison field · real periodic damage"],[7,"09-minions","Enemy V2 minions · preserved AI and faction"]]:
			lab.reset_props(); await get_tree().create_timer(0.1).timeout
			var target: DestructibleObject = lab.props[spec[0]]
			lab.overview.position = target.global_position + Vector2(0,-50); lab.overview.zoom = Vector2.ONE
			for attempt in 12:
				if (target.get_node("DestructibleComponent") as DestructibleComponent).is_destroyed(): break
				await fire(target,lab.LOADOUT[0])
			await get_tree().create_timer(0.12 if spec[0] != 7 else 0.65).timeout
			await capture(spec[1],spec[2])
			if spec[0] == 5:
				await get_tree().create_timer(6.7).timeout
				await capture("10-poison-expired","Poison expires · scene-owned lifetime cleanup")
		lab.reset_props(); await get_tree().create_timer(0.1).timeout
		lab.overview.position = Vector2(-400,-270); lab.overview.zoom = Vector2.ONE * (float(resolution.x) / 2000.0)
		var started := Time.get_ticks_msec()
		var first: DestructibleObject = lab.props[8]
		for attempt in 12:
			if (first.get_node("DestructibleComponent") as DestructibleComponent).is_destroyed(): break
			await fire(first,lab.LOADOUT[0])
		await get_tree().create_timer(0.12).timeout
		await capture("11-chain-reaction","Twelve barrels · deferred bounded chain reaction")
		await get_tree().create_timer(1.0).timeout
		var broken := 0
		for index in range(8,20):
			if (lab.props[index].get_node("DestructibleComponent") as DestructibleComponent).is_destroyed(): broken += 1
		print("DESTRUCTION_VISUAL_BENCH: ",resolution_tag," broken=",broken," elapsed_ms_including_casts_waits=",Time.get_ticks_msec()-started," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000," physics_ms=",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	print("DESTRUCTION_PREVIEW: ",shots," rendered captures")
	get_tree().quit()
func fire(target: DestructibleObject, spell: SpellData) -> void:
	var player: Player = lab.player
	player.position = target.global_position + Vector2(-170,0)
	player.casting.cancel(); player.casting.cooldowns.clear(); Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
	player.environment_target.selected = target
	var c := target.get_node("DestructibleComponent") as DestructibleComponent
	var previous := c.health
	var accepted := player.casting.request_cast(spell,player.global_position,Vector2.RIGHT,[target])
	if not accepted: push_error("Preview cast rejected"); get_tree().quit(1); return
	for frame in 100:
		await get_tree().physics_frame
		if c.health < previous: return
	push_error("Preview projectile did not reach its target"); get_tree().quit(1)
func capture(name: String, title: String) -> void:
	caption.text = title
	lab.overview.reset_smoothing(); lab.overview.force_update_scroll()
	for frame in 3: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(folder+resolution_tag+"/"+name+".png")
	if error != OK: push_error("Cannot save destruction preview")
	shots += 1
