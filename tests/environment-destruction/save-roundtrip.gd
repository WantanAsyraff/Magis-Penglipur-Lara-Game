extends Node
var checks := 0
var failures := 0
const BASE := "res://components/environment/destruction/"
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func prop(id: String) -> DestructibleObject:
	var node := load(BASE+"presets/explosive-barrel.tscn").instantiate() as DestructibleObject
	node.config = node.config.duplicate(true)
	node.config.persistent = true; node.config.persistence_id = id
	add_child(node)
	return node
func _ready() -> void:
	await get_tree().process_frame
	if "--quest-test-mode" not in OS.get_cmdline_user_args() or not OS.get_user_data_dir().contains("destruction-save-users"):
		push_error("Run save tests with --quest-test-mode in an isolated destruction-save-users XDG_DATA_HOME")
		get_tree().quit(2); return
	get_tree().current_scene = null
	var reading := "--read-destruction-save" in OS.get_cmdline_user_args()
	var ok := await SaveManager.load_slot(3) if reading else await SaveManager.new_game(3,"Destruction regression",true)
	check(ok,"Save V1 initializes/restores the actual campaign: "+SaveManager.last_error)
	if not ok: get_tree().quit(1); return
	if Dialogic.current_timeline: Dialogic.end_timeline()
	await get_tree().process_frame
	var player := Player_Manager.get_local_player() as Player
	player.set_physics_process(false)
	var dead := prop("roundtrip_dead"); var partial := prop("roundtrip_partial")
	var dead_component := dead.get_node("DestructibleComponent") as DestructibleComponent
	var partial_component := partial.get_node("DestructibleComponent") as DestructibleComponent
	if not reading:
		dead_component.destroy(); partial_component.set_health(7.25)
		check(SaveManager.save_active(),"Actual Save V1 commits destroyed and partial states: "+SaveManager.last_error)
		var old := SaveManager.snapshot()
		old.quest.world_flags = {}
		check(not GameSaveSchema.stage(old,3,Scene_Registry).is_empty(),"An old save without destructible flags remains valid without migration")
	else:
		check(dead_component.is_destroyed() and dead_component.effects_executed,"Fresh process restores destroyed barrel without rerunning effects")
		check(partial_component.health == 7.25 and not partial_component.is_destroyed(),"Fresh process restores exact hundredth-point durability")
		await get_tree().create_timer(0.2).timeout
		check(get_tree().get_nodes_in_group("destruction_explosion").is_empty(),"Fresh-process restoration produces no explosion")
	QuestManager.persistence_enabled = false; QuestManager._save_timer.stop(); SaveManager._autosave_pending = false
	print("DESTRUCTION_SAVE_%s: %d checks, %d failures" % ["READ" if reading else "WRITE",checks,failures])
	get_tree().quit(1 if failures else 0)
