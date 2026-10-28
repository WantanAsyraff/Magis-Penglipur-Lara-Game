extends Node
## Scripted rendering fixtures; no campaign saves or progression writes.
const FOLDER := "res://docs/previews/snappy-combat/"
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit(2)
		return
	await get_tree().process_frame
	var room: BossPrototypeRoom = load("res://scenes/combat/boss-prototype-room.tscn").instantiate()
	add_child(room)
	await room.initialized
	room.menu.hide()
	room.player.set_physics_process(false)
	room.boss.set_physics_process(false)
	room.get_node("StartTrigger").monitoring = false
	room.player.position = Vector2(850,366)
	room.boss.position = Vector2(1450,380)
	var other: Enemy = load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate()
	other.position = Vector2(1150,414)
	room.actors.add_child(other)
	other.set_physics_process(false)
	Player_Global_Data.combat_mode = true
	room.player.combat_mode = true
	room.player.pushback.set_physics_process(false)
	room.player.pushback.remaining = 2.6
	var heat: SpellData = load("res://data/magis/spells/phys-heat-engine.tres")
	SpellExecutor.new().execute(SpellCastContext.new(room.player,heat),room.player)
	room.player.hitbox.set_physics_process(false)
	var hud: StatusEffectsHUD = room.player.camera.get_node("UI/StatusEffectsHUD")
	hud.bind_player(room.player)
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	DirAccess.make_dir_recursive_absolute(FOLDER)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		get_window().content_scale_size = resolution
		room.player.target_lock.locked_target = null
		room.player._update_aim_direction()
		hud.refresh()
		await shot("pushback-"+str(resolution.x))
		var event := InputEventKey.new()
		event.physical_keycode = KEY_Q
		event.keycode = KEY_Q
		event.pressed = true
		get_viewport().push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		get_viewport().push_input(event,true)
		await shot("target-lock-next-"+str(resolution.x))
		Player_Global_Data.learned_spells.assign(Spell_Library.all_spells.values())
		for pair in [["spell-archives-menu",SpellCategoryFilter.Category.SUPPORT],["spell-equipment",SpellCategoryFilter.Category.BUFF]]:
			var menu: Control = load("res://scenes/ui/spell-equipment/"+pair[0]+".tscn").instantiate()
			layer.add_child(menu)
			var filter: SpellCategoryFilter = menu.get_node("%CategoryFilter")
			filter.select(pair[1])
			filter.item_selected.emit(pair[1])
			await shot(pair[0]+"-"+str(resolution.x))
			menu.free()
	print("SNAPPY_COMBAT_PREVIEW: 8 actual renderer captures")
	get_tree().quit()

func shot(name: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(FOLDER+name+".png")
	if result != OK: push_error("Screenshot failed: " + error_string(result))
