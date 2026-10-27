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
	print("NPC_WORLD_BOOT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
