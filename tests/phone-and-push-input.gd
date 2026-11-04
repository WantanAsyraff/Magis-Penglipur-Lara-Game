extends Node2D
var checks := 0
var failures := 0
var player: Player
var interactions := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func settle() -> void:
	for i in 8: await get_tree().process_frame
func tap(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate(); event.pressed = false; get_viewport().push_input(event,true)
func tap_action(action: String) -> void:
	for binding in InputMap.action_get_events(action):
		if binding is InputEventKey:
			tap(binding.physical_keycode if binding.physical_keycode else binding.keycode); return
func _ready() -> void:
	await settle()
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	QuestManager.persistence_enabled = false
	if "--actual-overworld" in OS.get_cmdline_user_args():
		await actual_overworld()
		print("PHONE_OVERWORLD: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0); return
	Player_Global_Data.p_moveable = true; Player_Global_Data.phone_visible = false; Player_Global_Data.combat_mode = false
	player = load("res://components/characters/player/player.tscn").instantiate(); add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player; player.set_physics_process(false)
	await settle()
	var phone := get_tree().get_first_node_in_group("phone_ui")
	Player_Global_Data.phone_visible = true; await settle()
	check(phone.is_visible_in_tree(),"Phone becomes available after a story enables it")
	tap_action("open_phone"); await get_tree().create_timer(.6).timeout
	check(phone.phone_selected and phone.is_visible_in_tree(),"The configured phone key opens a visible overworld phone")
	var first_app: App = phone.app_list.get_child(0)
	check(first_app.app_pressed.is_connected(phone._on_app_opened),"Apps are connected even when phone was disabled at player spawn")
	check(get_viewport().get_visible_rect().encloses(phone.screen.get_global_rect()),"Open phone fits the active viewport")
	Player_Global_Data.combat_mode = true; await settle()
	check(not phone.phone_selected and not phone.is_visible_in_tree(), "Entering combat closes and hides an already open phone")
	tap_action("open_phone"); await settle()
	phone._set_open(true, false)
	check(not phone.phone_selected and not phone.visible, "Combat blocks both the phone key and direct opening")
	var repertoire := player.camera.combatUI.get_node("Repetoire") as RepetoirePanel
	check(repertoire.is_visible_in_tree() and repertoire.anchor_left == 1.0 and repertoire.offset_right == -24, "Combat repertoire starts visible at the bottom right")
	check(InputMap.action_get_events("toggle_repertoire")[0].physical_keycode == KEY_V, "Repertoire toggle defaults to physical V")
	tap(KEY_V)
	await get_tree().create_timer(0.12).timeout
	check(repertoire.visible and repertoire.slide_progress > 0 and repertoire.slide_progress < 1, "V slides the repertoire outward before hiding it")
	await get_tree().create_timer(0.18).timeout
	check(not repertoire.visible and is_equal_approx(repertoire.slide_progress, 1.0), "V hides the repertoire after its slide finishes")
	tap(KEY_V)
	await get_tree().create_timer(0.12).timeout
	check(repertoire.visible and repertoire.slide_progress > 0 and repertoire.slide_progress < 1, "V slides the repertoire back into view")
	await get_tree().create_timer(0.18).timeout
	check(repertoire.is_visible_in_tree() and is_zero_approx(repertoire.slide_progress), "Repertoire returns to its bottom-right anchor")
	tap(KEY_V)
	await get_tree().create_timer(0.08).timeout
	tap(KEY_V)
	await get_tree().create_timer(0.3).timeout
	check(repertoire.visible and repertoire.repertoire_enabled and is_zero_approx(repertoire.slide_progress), "Rapid V toggles reverse the slide and keep the final requested state")
	check(ControlBindings.CATEGORIES.Interface.any(func(entry): return entry[0] == "toggle_repertoire"), "Repertoire binding appears in Interface settings")
	var saved_toggle := InputMap.action_get_events("toggle_repertoire")
	InputMap.action_erase_events("toggle_repertoire")
	var remapped := InputEventKey.new(); remapped.physical_keycode = KEY_B
	InputMap.action_add_event("toggle_repertoire", remapped)
	tap(KEY_V); await settle()
	check(repertoire.repertoire_enabled, "The old V key stops toggling repertoire after rebinding")
	if is_instance_valid(InventoryOverlay.ui): InventoryOverlay.close()
	await settle()
	tap(KEY_B); await get_tree().create_timer(0.3).timeout
	check(not repertoire.visible, "The remapped key toggles repertoire visibility")
	InputMap.action_erase_events("toggle_repertoire")
	for binding in saved_toggle: InputMap.action_add_event("toggle_repertoire", binding)
	tap(KEY_V); await get_tree().create_timer(0.3).timeout
	player._enter_casting_stance(); await settle()
	player._exit_casting_stance(); await settle()
	check(repertoire.visible, "Repertoire stays visible when casting stance ends")
	Player_Global_Data.combat_mode = false; await settle()
	check(not repertoire.is_visible_in_tree() and phone.visible and not phone.phone_selected, "Leaving combat hides repertoire and restores the closed phone")
	phone._set_open(true, false)
	Player_Global_Data.phone_visible = false; await settle()
	check(not phone.phone_selected, "Story disabling the phone clears its open state")
	tap_action("open_phone"); await settle()
	check(not phone.phone_selected, "The phone key cannot secretly open a story-disabled phone")
	Player_Global_Data.combat_mode = true; await settle()
	var enemy: Enemy = load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate()
	enemy.position = Vector2(180,0); add_child(enemy); enemy.set_physics_process(false)
	player.position = Vector2.ZERO; player.pushback.remaining = 0; await settle()
	var before := enemy.position
	tap(KEY_E); await get_tree().create_timer(.25).timeout
	check(player.pushback.remaining > 0 and enemy.position.distance_to(before) > 150,"E pushes a real enemy after closing or disabling the phone")
	Player_Global_Data.combat_mode = false
	Player_Global_Data.phone_visible = true; await settle()
	phone._set_open(true,false)
	phone._on_app_opened(load("res://scenes/ui/quest-ui/quest-ui.tscn")); await settle()
	var app: Control = phone.current_app_node
	check(app != null and app.can_process(),"An app opens through the real phone after story unlock")
	tap_action("open_phone"); await settle()
	check(not phone.phone_selected and not app.can_process(),"Closing the phone suspends its cached app input")
	tap_action("open_phone"); await settle()
	check(phone.phone_selected and app.can_process(),"Reopening resumes the cached app")
	tap(KEY_ESCAPE); await settle()
	check(phone.current_app_node == null and phone.app_list.visible,"App Back returns to the phone launcher")
	tap(KEY_ESCAPE); await settle()
	check(not phone.phone_selected,"A second Back closes the phone without a hidden selection")
	phone._set_open(true,false); get_tree().paused = true; await settle()
	check(not phone.phone_selected and not phone.visible,"Pause clears the phone state before other systems take input")
	get_tree().paused = false; await settle()
	check(phone.visible and not phone.phone_selected,"Resume restores phone availability without opening it")
	var npc := Node2D.new(); npc.position = player.position+Vector2(30,0); add_child(npc)
	var detector := DetectionComponent.new(); npc.add_child(detector); detector.interacted.connect(func(): interactions += 1)
	Player_Global_Data.combat_mode = true
	await settle(); player.pushback.remaining = 0; enemy.position = player.position+Vector2(180,0)
	tap(KEY_E); await settle()
	check(interactions == 1,"Physical E interacts with the focused NPC/object after phone close")
	check(player.pushback.remaining == 0,"Nearby NPC/object interaction takes priority over E pushback")
	Player_Global_Data.combat_mode = false; await settle()
	phone._set_open(true,false); tap_action("interact"); await settle()
	check(interactions == 1,"Phone UI blocks world interactions while genuinely open")
	tap_action("open_phone"); await settle(); tap_action("interact"); await settle()
	check(interactions == 2,"Closing the phone restores world interactions")
	npc.queue_free(); await settle()
	player.pushback.remaining = 0; enemy.position = player.position+Vector2(180,0)
	phone._set_open(true,false); tap(KEY_E); await settle()
	check(player.pushback.remaining == 0,"An actually open phone blocks E without spending push cooldown")
	Player_Global_Data.combat_mode = true; await settle()
	tap(KEY_E); await get_tree().create_timer(.25).timeout
	check(not phone.phone_selected and player.pushback.remaining > 0,"Entering combat closes the phone and immediately restores E pushback")
	var overlay := get_node_or_null("/root/InventoryOverlay")
	if overlay:
		check(overlay.open(),"Inventory can acquire its modal after phone closes")
		tap_action("open_phone"); await settle()
		check(not phone.phone_selected,"The phone key cannot open a hidden phone behind inventory")
		overlay.close(); await settle()
	if "--capture-phone" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
			get_window().size = resolution; get_window().content_scale_size = resolution; await settle()
			phone._set_open(true,false); await settle()
			check(get_viewport().get_visible_rect().encloses(phone.screen.get_global_rect()),"Phone remains onscreen at "+str(resolution))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://docs/previews/phone-input-%dx%d.png" % [resolution.x,resolution.y])
	print("PHONE_AND_PUSH_INPUT: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)

func actual_overworld() -> void:
	Player_Global_Data.phone_visible = true; Player_Global_Data.p_moveable = true
	get_window().size = Vector2i(1280,720); get_window().content_scale_size = Vector2i(1280,720)
	var world := load("res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-two/FLAC-F2-hallway-room-1.tscn").instantiate() as Node
	add_child(world)
	for i in 120: await get_tree().process_frame
	var phone := get_tree().get_first_node_in_group("phone_ui")
	check(Player_Manager.get_local_player() != null and phone != null,"Actual FLAC overworld initializes its player and phone")
	var viewport_rect := get_viewport().get_visible_rect()
	var preview: Rect2 = phone.screen.get_global_rect().intersection(viewport_rect)
	check(phone.launcher.visible and preview.size.y > 30 and preview.size.y < 150,"Closed overworld phone keeps its original small resting preview")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/previews/phone-overworld-closed.png")
	tap(KEY_F); await get_tree().create_timer(.4).timeout
	check(phone.phone_selected and phone.is_visible_in_tree(),"Physical F opens the phone in the actual FLAC overworld")
	check(get_viewport().get_visible_rect().encloses(phone.screen.get_global_rect()),"Actual overworld phone is fully onscreen")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/previews/phone-overworld-open.png")
	tap(KEY_F); await settle()
	check(not phone.phone_selected and phone.launcher.visible,"F closes the phone back to its resting preview")
	var at: Vector2 = phone.launcher.get_global_rect().intersection(get_viewport().get_visible_rect()).get_center()
	for down in [true,false]:
		var click := InputEventMouseButton.new(); click.position = at; click.global_position = at; click.button_index = MOUSE_BUTTON_LEFT; click.pressed = down
		get_viewport().push_input(click,true)
	await settle()
	check(phone.phone_selected,"Clicking the resting phone preview opens the phone")

	await get_tree().create_timer(.35).timeout
	var crate: App = phone.app_list.get_node("Inventory")
	check(not crate.fullscreen,"Crate app routes through the phone instead of switching world scenes")
	Inventory_Manager.add_item(QuestManager.registry.items.drop_001,2)
	var scene_before := get_tree().current_scene
	var world_before := Player_Manager.get_local_player().global_position
	at = crate.get_global_rect().get_center()
	for down in [true,false]:
		var click := InputEventMouseButton.new(); click.position = at; click.global_position = at; click.button_index = MOUSE_BUTTON_LEFT; click.pressed = down
		get_viewport().push_input(click,true)
	await get_tree().create_timer(.35).timeout
	var overlay := get_node_or_null("/root/InventoryOverlay")
	check(overlay != null and is_instance_valid(overlay.ui) and overlay.ui.visible,"Clicking the actual crate icon opens Inventory V2")
	check(get_tree().paused and get_tree().current_scene == scene_before and Player_Manager.get_local_player().global_position == world_before,"Crate inventory pauses the same overworld and player in place")
	if DisplayServer.get_name() != "headless" and overlay != null and is_instance_valid(overlay.ui):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/previews/phone-crate-inventory.png")
	if overlay: overlay.close()
	await settle()
	check(not get_tree().paused and not phone.phone_selected,"Closing inventory resumes gameplay with the phone at rest")
