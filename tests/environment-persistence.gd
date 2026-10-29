extends Node
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+text)
func fixture() -> EnvironmentDevice:
	var barrier: EnvironmentDevice = load("res://components/environment/magis-breakable.tscn").instantiate()
	barrier.data = barrier.data.duplicate(true); barrier.data.persistent = true
	barrier.name = "EnvironmentPersistenceFixture"; barrier.position = Vector2(3900,840)
	get_tree().current_scene.get_node("World/GameComponents").add_child(barrier)
	return barrier
func gate_fixture() -> EnvironmentDevice:
	var gate: EnvironmentDevice = load("res://components/environment/powered-gate.tscn").instantiate()
	gate.data = gate.data.duplicate(true); gate.data.persistent = true
	gate.name = "EnvironmentGateFixture"; gate.position = Vector2(4200,600)
	get_tree().current_scene.get_node("World/GameComponents").add_child(gate)
	return gate
func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	if "--read-environment-save" in OS.get_cmdline_user_args():
		check(await SaveManager.load_slot(1),"Fresh process loads the isolated campaign slot")
		var barrier := fixture()
		var gate := gate_fixture()
		await get_tree().physics_frame; await get_tree().physics_frame
		check(gate.actuator.output and gate.collision.disabled,"Persistent gate activation through a linked actuator restores in a fresh process")
		check(barrier.get_meta("combat_dead",false) and barrier.collision.disabled,"Permanent destruction restores through the real world-flag save path")
		check(get_tree().current_scene.get_node("World/GameComponents/Environment/kampung-environment/CatchTank").volume == 0,"Transient water resets on scene reload")
		for kind in ["manual","auto"]: SaveManager.delete_slot(1,kind)
	else:
		for kind in ["manual","auto"]: SaveManager.delete_slot(1,kind)
		check(await SaveManager.new_game(1,"Environment fixture"),"Creates a test-prefixed campaign profile")
		if Dialogic.current_timeline: Dialogic.end_timeline()
		await get_tree().process_frame
		var barrier := fixture()
		var gate := gate_fixture()
		gate.actuator.receive(true,EnvironmentLink.Port.ENABLE,barrier)
		check(WorldPersistence.has_state(gate,"activated"),"Linked mechanism activation marks the existing persistent world flag")
		barrier.hitbox.receive_damage(999,Player_Manager.get_local_player())
		await get_tree().physics_frame; await get_tree().physics_frame
		check(barrier.collision.disabled and WorldPersistence.has_state(barrier,"broken"),"Breakable removes collision and marks stable authored-path state")
		get_tree().current_scene.get_node("World/GameComponents/Environment/kampung-environment/CatchTank").add_water(30)
		check(SaveManager.save_active(),"Existing SaveManager durably saves environmental world flags")
	SaveManager._autosave_pending = false; QuestManager.persistence_enabled = false; QuestManager._save_timer.stop()
	print("ENVIRONMENT_PERSISTENCE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
