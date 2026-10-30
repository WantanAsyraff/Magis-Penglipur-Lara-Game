extends Node
var checks := 0
var failures := 0
var phone: Control
var capture := false
var folder := "res://docs/previews/profile-music/"
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func frames(count: int = 8) -> void:
	for i in count: await get_tree().process_frame
func click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new(); event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		get_viewport().push_input(event,true)
	await frames()
func escape() -> void:
	var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.physical_keycode = KEY_ESCAPE; event.pressed = true
	Input.parse_input_event(event); await frames(1); event = event.duplicate(); event.pressed = false; Input.parse_input_event(event); await frames()
func shot(name_: String) -> void:
	if not capture: return
	await get_tree().create_timer(.2).timeout; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+name_+".png")
func launch(icon_name: String) -> Control:
	phone._set_open(true,false); await frames()
	await click(phone.app_list.get_node(icon_name))
	return ModalService.holder as Control
func _ready() -> void:
	await frames()
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	capture = "--capture-apps" in OS.get_cmdline_user_args()
	if capture: DirAccess.make_dir_recursive_absolute(folder)
	QuestManager.persistence_enabled = false
	Player_Global_Data.phone_visible = true; Player_Global_Data.p_moveable = true
	Player_Global_Data.p_name = "Yan"; Player_Global_Data.p_role = "Magis student"; Player_Global_Data.p_mood = "Curious"
	Player_Global_Data.player_level = 8; Player_Global_Data.player_exp = 1430; Player_Global_Data.p_curr_ringgit = 124.5
	Player_Global_Data.current_field = "Physics"; Player_Global_Data.current_major = "Mechanics"; Player_Global_Data.current_minor = "Thermodynamics"
	Player_Global_Data.learned_spells.assign(Spell_Library.all_spells.values().slice(0,12)); Player_Global_Data.equipped_spells.assign(Player_Global_Data.learned_spells.slice(0,3))
	var world := load("res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-two/FLAC-F2-hallway-room-1.tscn").instantiate() as Node
	get_tree().current_scene = null; get_tree().root.add_child(world); get_tree().current_scene = world
	for i in 90: await get_tree().process_frame
	phone = get_tree().get_first_node_in_group("phone_ui")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = dimensions; get_window().content_scale_size = dimensions; await frames()
		var at := Player_Manager.get_local_player().global_position
		var profile := await launch("PlayerStats")
		check(profile is UserStatsUI and get_tree().paused and get_tree().current_scene == world,"Profile icon opens a paused overlay over the same world at "+str(dimensions))
		if profile == null: break
		check(profile.profile_name.text == "Yan" and profile.currency_label.text == "RM 124.50","Profile cards show real identity and currency")
		check(profile.page_body.get_global_rect().end.y <= dimensions.y-20,"Profile content fits within the viewport")
		Player_Global_Data.p_curr_health = 275; await get_tree().create_timer(.3).timeout
		check(profile.health_bar.value == 275 and profile.health_label.text.begins_with("275"),"Live health updates while profile owns pause")
		var down := InputEventJoypadButton.new(); down.button_index = JOY_BUTTON_DPAD_DOWN; down.pressed = true
		get_viewport().push_input(down,true); await frames()
		check(profile.details_scroll.scroll_vertical > 0,"Controller directions scroll the read-only profile details")
		profile.details_scroll.scroll_vertical = 0
		await shot("profile-%dx%d" % [dimensions.x,dimensions.y])
		await escape()
		check(not get_tree().paused and get_tree().current_scene == world and Player_Manager.get_local_player().global_position.distance_to(at) < 1,"Escape closes profile without opening Pause or replacing the world")
		var music := await launch("Inventory2")
		check(music != null and music.title_label.text == "Skandal" and music.artist_label.text == "Hujan","Leaf app opens the music player with authored track metadata")
		if music == null: break
		check(music.page_body.get_global_rect().end.y <= dimensions.y-20,"Music layout fits within the viewport")
		check(music.previous_button.disabled and music.next_button.disabled,"Single-track library does not pretend to have more songs")
		await shot("music-%dx%d" % [dimensions.x,dimensions.y])
		music.volume.value = 0
		await click(music.play_button); await get_tree().create_timer(.25).timeout
		check(music.audio.playing and not music.audio.stream_paused and music.play_button.text == "Pause","Play controls the actual audio stream")
		await click(music.play_button)
		check(music.audio.stream_paused and music.play_button.text == "Play","Pause suspends the real player")
		music.seek.value = 20; await frames()
		check(music.seek.value == 20 and music.elapsed_label.text == "0:20","Paused seeking retains the chosen position and time display")
		await click(music.play_button)
		await get_tree().create_timer(.25).timeout
		check(music.audio.get_playback_position() >= 20 and music.audio.get_playback_position() < 22,"Resuming starts playback at the selected seek position")
		music.seek.value = music.seek.max_value-.1; await get_tree().create_timer(.6).timeout
		check(not music.audio.playing and music.seek.value == 0,"Natural track completion resets the player for replay")
		await click(music.play_button)
		var audio: AudioStreamPlayer = music.audio
		await click(music.close_button)
		check(not get_tree().paused and is_instance_valid(audio) and audio.playing,"Closing music restores gameplay and retains playback in the current world")
		audio.stop(); audio.stream_paused = false; audio.volume_db = linear_to_db(.45)
	var empty_scene: PackedScene = load("res://scenes/ui/music-ui/music-selection-ui.tscn")
	var empty := empty_scene.instantiate(); empty.tracks.clear(); add_child(empty); await frames()
	check(empty.play_button.disabled and empty.title_label.text == "Your soundtrack starts here","Empty library presents a safe disabled player")
	empty.queue_free()
	var player := Player_Manager.get_local_player(); player.set_physics_process(false)
	get_window().size = Vector2i(1280,720); get_window().content_scale_size = Vector2i(1280,720)
	Player_Global_Data.p_name = "A very long student name used to check the layout at smaller resolutions"
	Player_Global_Data.p_role = "Student of the Faculty of Logic and Computation"
	Player_Global_Data.learned_spells.clear()
	var profile := await launch("PlayerStats")
	check(profile.page_body.get_global_rect().end.y <= 700,"Long identity text and an empty spell list remain contained at 720p")
	await shot("profile-long-identity-1280x720")
	world.queue_free(); await frames()
	check(not is_instance_valid(ModalService.holder) and not get_tree().paused,"World exit cleans up the profile overlay and its modal ownership")
	print("PROFILE_MUSIC_UI: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)
