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
	tap_action("open_phone"); await settle()
	Player_Global_Data.combat_mode = true; await settle()
	tap_action("open_phone"); await get_tree().create_timer(.6).timeout
	check(phone.phone_selected and phone.is_visible_in_tree(),"The phone key cannot create an invisible open phone when combat hides the overworld HUD")
	tap_action("open_phone"); await settle()
	# A hidden phone must never remain selected and swallow combat actions.
	tap_action("open_phone"); await settle(); Player_Global_Data.phone_visible = false; await settle()
	check(not phone.phone_selected,"Story disabling the phone clears its open state")
	tap_action("open_phone"); await settle()
	check(not phone.phone_selected,"The phone key cannot secretly open a story-disabled phone")
	var enemy: Enemy = load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate()
	enemy.position = Vector2(180,0); add_child(enemy); enemy.set_physics_process(false)
	player.position = Vector2.ZERO; player.pushback.remaining = 0; await settle()
	var before := enemy.position
	tap(KEY_E); await get_tree().create_timer(.25).timeout
	check(player.pushback.remaining > 0 and enemy.position.distance_to(before) > 150,"E pushes a real enemy after closing or disabling the phone")
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
	await settle(); player.pushback.remaining = 0; enemy.position = player.position+Vector2(180,0)
	tap(KEY_E); await settle()
	check(interactions == 1,"Physical E interacts with the focused NPC/object after phone close")
	check(player.pushback.remaining == 0,"Nearby NPC/object interaction takes priority over E pushback")
	phone._set_open(true,false); tap_action("interact"); await settle()
	check(interactions == 1,"Phone UI blocks world interactions while genuinely open")
	tap_action("open_phone"); await settle(); tap_action("interact"); await settle()
	check(interactions == 2,"Closing the phone restores world interactions")
	npc.queue_free(); await settle()
	player.pushback.remaining = 0; enemy.position = player.position+Vector2(180,0)
	phone._set_open(true,false); tap(KEY_E); await settle()
	check(player.pushback.remaining == 0,"An actually open phone blocks E without spending push cooldown")
	tap_action("open_phone"); tap(KEY_E); await get_tree().create_timer(.25).timeout
	check(player.pushback.remaining > 0,"Closing the phone immediately restores E pushback")
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
