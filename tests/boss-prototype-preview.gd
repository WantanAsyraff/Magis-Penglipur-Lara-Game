extends RefCounted
# Scripted renderer fixtures exercise the production room/attacks. Not a manual balance test.
const FOLDER := "res://docs/previews/boss-prototype/"

static func capture(room: BossPrototypeRoom) -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Boss previews require a real rendering display")
		room.get_tree().quit(1)
		return
	await _shot(room, "01-ready")
	await room.begin_encounter()
	room.player.set_physics_process(false)
	room.player.hitbox.set_invincible(true)
	room.boss.set_physics_process(false)
	_pose(room, "melee-slam")
	await _shot(room, "02-melee-windup")
	room.boss.hitbox.receive_damage(185, room.player)
	await _shot(room, "03-phase-two-transition")
	await room.get_tree().create_timer(1.1, false).timeout
	_pose(room, "dash-attack", Vector2(1550,380), Vector2(1150,366))
	await _shot(room, "04-dash-windup")
	room.boss._interrupt_attack("Preview next pose")
	_pose(room, "ranged-double", Vector2(1600,380), Vector2(1000,366))
	await room.get_tree().create_timer(.9, false).timeout
	await _shot(room, "05-ranged-burst")
	room.boss.hitbox.receive_damage(170, room.player)
	await _shot(room, "06-phase-three-transition")
	await room.get_tree().create_timer(1.1, false).timeout
	_pose(room, "aoe-shockwave", Vector2(1500,380), Vector2(1110,366))
	await _shot(room, "07-shockwave-warning")
	room.boss.hitbox.receive_damage(10000, room.player)
	await _shot(room, "08-victory")
	await room.retry_encounter()
	room.player.set_physics_process(false)
	room.boss.set_physics_process(false)
	await _shot(room, "09-retry")
	room.player.hitbox.receive_damage(10000, room.boss)
	await _shot(room, "10-defeat")
	await room.retry_encounter()
	await _shot(room, "11-retry-after-defeat")
	print("BOSS_PREVIEW: 11 actual-renderer captures saved")
	room.get_tree().quit()

static func _pose(room: BossPrototypeRoom, attack_file: String, boss_position := Vector2(1450,380), player_position := Vector2(1250,366)) -> void:
	var boss := room.boss
	boss._interrupt_attack("Preview pose")
	boss.attack_timer.stop()
	boss.hurt_timer.stop()
	boss.global_position = boss_position
	room.player.global_position = player_position
	boss._player = room.player
	boss.current_attack = load("res://data/npc/enemies/boss/resonance-guardian/" + attack_file + ".tres")
	boss.current_state = Boss.State.IDLE
	boss._set_state(Boss.State.ATTACK)

static func _shot(room: BossPrototypeRoom, file: String) -> void:
	await room.get_tree().create_timer(.18, false).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var result := room.get_viewport().get_texture().get_image().save_png(FOLDER + file + ".png")
	if result != OK: push_error("Could not save boss preview: " + error_string(result))
