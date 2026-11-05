extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func _ready() -> void:
	for tick in 24: await get_tree().physics_frame
	var room := get_parent()
	var spawner := room.find_child("NpcQuestSpawner", true, false) as RoomQuestManager
	check(spawner != null, "Main world contains its production NPC spawner")
	if spawner:
		check(spawner.active_npcs.size() == spawner.npcs_to_spawn, "Fresh world boot creates every configured NPC")
		var valid := true
		for npc in spawner.active_npcs:
			var exclude: Array[RID] = [npc.get_rid()]
			valid = valid and npc.is_visible_in_tree() and npc.sprite != null and npc.sprite.texture != null and spawner.spawn_validator.valid(spawner.get_world_2d().direct_space_state, npc.global_position, Rect2(spawner.global_position + spawner.spawn_validator.allowed_region.position, spawner.spawn_validator.allowed_region.size), [], exclude)
		check(not spawner.active_npcs.is_empty() and valid, "Freshly spawned NPCs retain grounded body and interaction clearance")
		print("NPC_BOOT_POSITIONS ", spawner.active_npcs.map(func(n): return n.global_position))
	check(Player_Manager.get_local_player() != null, "Normal ZoneRoot player initialization runs")
	if "--capture-npc-boot" in OS.get_cmdline_user_args() and spawner and not spawner.active_npcs.is_empty():
		var player := Player_Manager.get_local_player()
		var npc: Node2D = spawner.active_npcs[0]
		player.global_position = npc.global_position + Vector2(-160,0)
		for tick in 90: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var dir := "/tmp/magis-npc-startup"
		DirAccess.make_dir_recursive_absolute(dir)
		get_viewport().get_texture().get_image().save_png(dir + "/" + room.scene_file_path.get_file().get_basename() + ".png")
	if "--capture-story-presence" in OS.get_cmdline_user_args() and spawner and not spawner.active_npcs.is_empty():
		if "--story-capture-720p" in OS.get_cmdline_user_args():
			get_window().content_scale_size = Vector2i(1280, 720)
			get_window().size = Vector2i(1280, 720)
		SaveManager.session_ready = true
		StoryDirector._on_restored()
		var npc: Node2D = spawner.active_npcs[0]
		var player := Player_Manager.get_local_player()
		player.global_position = npc.global_position + Vector2(-160, 0)
		var flag := StoryFlagCondition.new()
		flag.flag_definition = StoryDirector.registry.get_flag_definition(&"story.prologue.spm_completed")
		flag.expected_value = true
		var story_condition := StoryConditionComponent.new()
		story_condition.conditions.append(flag)
		npc.add_child(story_condition)
		var presence := StoryPresenceComponent.new()
		presence.actor = npc
		presence.condition_component = story_condition
		npc.add_child(presence)
		var dir := "/tmp/magis-story-presence"
		DirAccess.make_dir_recursive_absolute(dir)
		for tick in 30: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir + "/npc-hidden.png")
		QuestManager.set_world_flag("story.prologue.spm_completed", true)
		for tick in 30: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir + "/npc-visible.png")
		print("STORY_PRESENCE_VISUAL ", player.global_position, " ", npc.global_position, " ", npc.visible, " ", npc.is_visible_in_tree())
		check(npc.is_visible_in_tree(), "Story milestone shows the existing NPC")
	print("NPC_WORLD_BOOT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
