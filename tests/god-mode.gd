extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func frames(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	await get_tree().process_frame
func _ready() -> void:
	await get_tree().process_frame
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	Player_Global_Data.p_moveable = true
	var player := load("res://components/characters/player/player.tscn").instantiate() as Player
	add_child(player)
	var mode := player.god_mode
	var original_mask := player.collision_mask
	var key := InputEventAction.new(); key.action = "god_mode"; key.pressed = true
	mode._unhandled_input(key)
	check(mode._active and player.hitbox.is_invincible(), "Backtick action enables normal god mode protections")
	var start := player.global_position
	await frames(60)
	check(player.global_position.is_equal_approx(start) and player.velocity.y == 0, "Idle god mode holds altitude across sixty actual physics steps")
	Input.action_press("ui_up"); await frames(6); Input.action_release("ui_up")
	check(player.global_position.y < start.y, "God mode still flies upward")
	await frames(2); var altitude := player.global_position.y
	await frames(30)
	check(is_equal_approx(player.global_position.y, altitude), "Releasing flight input stops vertical movement without drifting")
	Player_Global_Data.p_moveable = false
	await frames(10)
	check(is_equal_approx(player.global_position.y, altitude), "Reserved movement does not reintroduce gravity while hovering")
	Player_Global_Data.p_moveable = true
	mode._unhandled_input(key)
	await frames(6)
	check(not mode._active and player.collision_mask == original_mask and not player.hitbox.is_invincible() and player.global_position.y > altitude, "Leaving god mode restores collisions, damage eligibility and gravity")
	QuestManager.persistence_enabled = false; QuestManager._save_timer.stop(); SaveManager._autosave_pending = false
	print("GOD_MODE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
