extends Node
# One profile owns one manual slot and one distinct autosave, with previous-good backups.
signal operation_finished(success: bool, message: String)
signal restored
const START_SCENE := "yan_prologue_house_entrance"
const MENU := "res://scenes/ui/menus/intro-menus/main-menu.tscn"
var active_profile: int = 0
var session_ready := false
var loading := false
var writing := false
var last_error := ""
var playtime: float = 0
var checkpoint: Dictionary = {}
var _autosave_pending := false
var _autosave_delay: float = 0
var _test_mode := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_test_mode = "--quest-test-mode" in OS.get_cmdline_user_args()
	QuestManager.quest_completed.connect(func(_quest): request_autosave())
	QuestManager.quest_handed_off.connect(func(_quest): request_autosave())

func _process(delta: float) -> void:
	if session_ready and not loading and not get_tree().paused and _campaign_scene_id() != "": playtime += delta
	if not _autosave_pending or loading: return
	_autosave_delay -= delta
	if _autosave_delay > 0 or QuestManager._claiming: return
	if Dialogic.current_timeline != null or QuestOfferDialog.is_open():
		_autosave_delay = .5
		return
	_autosave_pending = false
	if unavailable_reason().is_empty(): _save("auto")

func path_for(profile: int, kind: String = "manual", backup: bool = false) -> String:
	if profile < 1 or profile > 3 or kind not in ["manual","auto"]: return ""
	var prefix := "test-" if _test_mode else ""
	return GameSaveStore.ROOT + "%sprofile-%d-%s%s.json" % [prefix,profile,kind,"-backup" if backup else ""]

func _fail(message: String) -> bool:
	last_error = message
	operation_finished.emit(false,message)
	return false

func _offline() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.multiplayer_peer is OfflineMultiplayerPeer

func _campaign_scene_id() -> String:
	var scene := get_tree().current_scene
	if scene == null: return ""
	# Only ZoneRoot campaign scenes registered by the authored world manifest qualify.
	if scene.get_script() == null or scene.get_script().resource_path != "res://data/worlds/zone-root.gd": return ""
	for id in Scene_Registry.scenes:
		var resource: SceneData = Scene_Registry.scenes[id]
		if resource.scene and resource.scene.resource_path == scene.scene_file_path: return id
	return ""

func unavailable_reason(allow_claim: bool = false) -> String:
	if not _offline(): return "Campaign saving is available in single player only."
	if active_profile == 0 or not session_ready: return "Start or load a campaign profile first."
	if loading: return "Restoration is still in progress."
	if writing: return "A save is already being written."
	if QuestManager._claiming and not allow_claim: return "A reward transaction is in progress."
	if _campaign_scene_id().is_empty(): return "Saving is unavailable in menus, tests and training encounters."
	var player := Player_Manager.get_local_player() as Player
	if not is_instance_valid(player) or not Player_Global_Data.is_alive() or player.get_meta("combat_dead",false): return "The player must be alive and initialized."
	if (Dialogic.current_timeline != null or QuestOfferDialog.is_open()) and not allow_claim: return "Finish the conversation before saving."
	return ""

func snapshot() -> Dictionary:
	var player := Player_Manager.get_local_player() as Player
	var scene_id := _campaign_scene_id()
	for spell in Player_Global_Data.learned_spells:
		if spell == null or Spell_Library.get_spell_by_id(spell.spell_id) != spell: return {}
	if not player or scene_id.is_empty() or checkpoint.is_empty(): return {}
	return {"version": GameSaveSchema.VERSION, "profile": active_profile, "slot": "manual",
		"meta": {"name": Player_Global_Data.p_name, "timestamp": Time.get_unix_time_from_system(), "playtime": playtime},
		"player": GameSaveSchema.capture_player(), "quest": QuestSaveService.encode(QuestManager),
		"location": {"scene_id": scene_id, "position": [player.global_position.x,player.global_position.y], "facing": -1 if player.get_node("PlayerSprite").flip_h else 1},
		"checkpoint": checkpoint.duplicate(true)}

func save_active() -> bool:
	return _save("manual")

func commit_reward() -> bool:
	# Called synchronously from QuestRewardService before any reward notifications.
	# Failure propagates to its existing rollback of inventory, XP, claims and outbox.
	return _save("auto", true)

func _save(kind: String, allow_claim: bool = false, replace_damaged: bool = false) -> bool:
	var reason := unavailable_reason(allow_claim)
	if not reason.is_empty(): return _fail(reason)
	var data := snapshot()
	if not data.is_empty(): data.slot = kind
	if GameSaveSchema.stage(data,active_profile,Scene_Registry).is_empty(): return _fail("The current state contains invalid or unregistered progression data.")
	var path := path_for(active_profile,kind)
	# Never erase damaged evidence during an ordinary Save. Explicit UI replacement is required.
	var previous := GameSaveStore.read(path)
	var valid := not GameSaveSchema.stage(previous,active_profile,Scene_Registry).is_empty()
	if FileAccess.file_exists(path) and not valid and not replace_damaged: return _fail("The destination is damaged. Recover its backup or delete it explicitly in Load Game.")
	writing = true
	var error := GameSaveStore.write(path,data,valid)
	writing = false
	if not error.is_empty(): return _fail(error)
	last_error = ""
	operation_finished.emit(true,"Game saved.")
	return true

func request_autosave() -> void:
	if not session_ready or loading or active_profile == 0: return
	_autosave_pending = true
	_autosave_delay = .5

func inspect_slot(profile: int, kind: String = "manual", backup: bool = false) -> Dictionary:
	var path := path_for(profile,kind,backup)
	if path.is_empty(): return {"state": "invalid"}
	if not FileAccess.file_exists(path): return {"state": "empty"}
	var data := GameSaveStore.read(path)
	if data.get("slot",kind) != kind: return {"state": "damaged"}
	if data.get("version",GameSaveSchema.VERSION) != GameSaveSchema.VERSION: return {"state": "incompatible"}
	if GameSaveSchema.stage(data,profile,Scene_Registry).is_empty(): return {"state": "damaged"}
	return {"state": "valid", "name": data.meta.name, "level": data.player.player_level, "playtime": data.meta.playtime, "timestamp": data.meta.timestamp, "location": Scene_Registry.get_scene(data.location.scene_id).scene_name}

func delete_slot(profile: int, kind: String) -> bool:
	if loading or writing: return _fail("An operation is in progress.")
	for backup in [false,true]:
		var path := path_for(profile,kind,backup)
		if path.is_empty(): return _fail("Invalid slot.")
		for target in [path,path+".tmp"]:
			if FileAccess.file_exists(target):
				var error := DirAccess.remove_absolute(target)
				if error != OK: return _fail("Cannot delete slot: " + error_string(error))
	return true

func load_slot(profile: int, kind: String = "manual", backup: bool = false, respawn: bool = false) -> bool:
	if loading or writing or not _offline(): return _fail("Loading is unavailable during another operation or multiplayer.")
	var data := GameSaveStore.read(path_for(profile,kind,backup))
	if data.get("slot",kind) != kind: return _fail("The file belongs to a different save slot.")
	var staged := GameSaveSchema.stage(data,profile,Scene_Registry)
	if staged.is_empty(): return _fail("Save is damaged or incompatible. No progression has been changed.")
	if respawn:
		if data.location.scene_id != data.checkpoint.scene_id: data.player.combat_mode = data.checkpoint.get("combat_mode",false)
		data.location = data.checkpoint.duplicate(true)
		data.player.p_curr_health = data.player.p_max_health
		data.player.p_curr_mana = data.player.p_max_mana
		staged = GameSaveSchema.stage(data,profile,Scene_Registry)
	return await _restore(staged,profile)

func _restore(staged: Dictionary, profile: int) -> bool:
	if staged.is_empty(): return _fail("Cannot prepare restored state.")
	var packed: PackedScene = staged.scene
	var next := packed.instantiate()
	if next == null: return _fail("Cannot instantiate the saved scene.")
	if next.get_script() == null or next.get_script().resource_path != "res://data/worlds/zone-root.gd":
		next.free()
		return _fail("The saved destination is not a supported campaign scene.")
	# Keep the prior scene and its players alive until the destination has initialized.
	var old_scene := get_tree().current_scene
	var old_players := Player_Manager.players.duplicate()
	var old_quest := QuestSaveService.stage(QuestManager,QuestSaveService.encode(QuestManager))
	var old_player := GameSaveSchema.capture_player()
	var old_equipped := Player_Global_Data.equipped_spells.duplicate()
	var old_combat := Player_Global_Data.combat_mode
	var old_world := Player_Global_Data.current_world
	var old_position := Player_Manager.last_player_position
	var old_profile := active_profile
	var old_ready := session_ready
	loading = true
	session_ready = false
	_autosave_pending = false
	QuestManager._save_timer.stop()
	get_tree().paused = true
	QuestManager._restoring = true
	if Dialogic.current_timeline != null: Dialogic.end_timeline()
	if QuestOfferDialog.is_open():
		var offer := QuestOfferDialog.current
		offer._resolved = true
		offer._previous_movement = true
		offer.finish("dismiss")
	if old_scene: get_tree().root.remove_child(old_scene)
	Player_Global_Data.active_npc_ids.clear()
	Player_Manager.players.clear()
	Player_Manager.last_player_position = Vector2.ZERO
	if Player_Manager.has_meta("next_spawn_marker"): Player_Manager.remove_meta("next_spawn_marker")
	_apply(staged)
	QuestManager._restoring = true
	get_tree().root.add_child(next)
	get_tree().current_scene = next
	var player: Player
	for frame in 180:
		await get_tree().process_frame
		player = Player_Manager.get_local_player() as Player
		if is_instance_valid(player) and player.is_node_ready(): break
	var destination := Vector2(staged.data.location.position[0],staged.data.location.position[1])
	var initialized := is_instance_valid(player) and player.is_node_ready()
	if initialized:
		await get_tree().physics_frame
		if _position_embedded(player,destination):
			var fallback: Node2D = next.find_child("PlayerSpawn",true,false)
			initialized = fallback != null and _safe_checkpoint_position(player,fallback.global_position)
			if initialized: destination = fallback.global_position
	if not initialized:
		get_tree().root.remove_child(next)
		next.queue_free()
		Player_Manager.players = old_players
		if old_scene:
			get_tree().root.add_child(old_scene)
			get_tree().current_scene = old_scene
		if not old_quest.is_empty(): QuestManager.apply_staged(old_quest)
		GameSaveSchema.apply_player(old_player,old_equipped)
		Player_Global_Data.combat_mode = old_combat
		Player_Global_Data.current_world = old_world
		Player_Manager.last_player_position = old_position
		active_profile = old_profile
		session_ready = old_ready
		loading = false
		QuestManager._restoring = false
		get_tree().paused = false
		return _fail("Scene initialization failed; returned to the prior session.")
	# Reapply after authored scene setup; loading must not acquire starter items or emit events.
	_apply(staged)
	player.cancel_active_casting()
	player._exit_casting_stance()
	player.hitbox.clear_all_effects()
	player.hitbox.set_invincible(false)
	if player.has_meta("combat_dead"): player.remove_meta("combat_dead")
	player.velocity = Vector2.ZERO
	var location: Dictionary = staged.data.location
	player.global_position = destination
	player.get_node("PlayerSprite").flip_h = location.get("facing",1) == -1
	player.camera.reset_smoothing()
	Player_Manager.last_player_position = player.global_position
	checkpoint = staged.data.checkpoint.duplicate(true)
	playtime = staged.data.meta.playtime
	active_profile = profile
	_reset_transients()
	QuestManager._restoring = false
	loading = false
	session_ready = true
	get_tree().paused = false
	player.camera.unpause()
	if old_scene: old_scene.queue_free()
	last_error = ""
	restored.emit()
	operation_finished.emit(true,"Game loaded.")
	# Durable pending reward notifications are replayed only after commit, with stored receipts.
	QuestManager.drain_outbox()
	for instance in QuestManager._active_instances.values().duplicate():
		if instance.status == QuestInstance.Status.HANDED_OFF: QuestManager._continue_chain(instance)
	return true

func _apply(staged: Dictionary) -> void:
	Player_Global_Data.active_goals.clear()
	QuestManager.apply_staged(staged.quest)
	GameSaveSchema.apply_player(staged.data.player,staged.equipped)

func _reset_transients() -> void:
	Player_Global_Data.active_buffs.clear()
	Player_Global_Data.selected_spell = null
	Player_Global_Data.p_moveable = true
	Player_Global_Data.p_jumpable = true
	Player_Global_Data.p_visible = true
	Player_Global_Data.p_hidden = false
	Player_Global_Data.p_invincible = false
	Player_Global_Data.is_casting = false
	Player_Global_Data.is_dashing = false
	Player_Global_Data.current_dash_charges = Player_Global_Data.MAX_DASH_CHARGES

func new_game(profile: int, character_name: String, overwrite: bool = false) -> bool:
	if loading or writing or not _offline() or profile < 1 or profile > 3: return _fail("Cannot create that profile now.")
	if character_name.strip_edges().is_empty() or character_name.length() > 64: return _fail("Enter a character name of 1–64 characters.")
	var occupied := false
	for kind in ["manual","auto"]:
		for backup in [false,true]: occupied = occupied or FileAccess.file_exists(path_for(profile,kind,backup))
	if occupied and not overwrite: return _fail("Confirm replacement of this profile before starting.")
	var data := _default_snapshot(profile,character_name)
	var staged := GameSaveSchema.stage(data,profile,Scene_Registry)
	if staged.is_empty(): return _fail("New game defaults could not be validated.")
	if not await _restore(staged,profile): return false
	# Use the authored starting spawn, rather than inventing a historical position.
	var scene := get_tree().current_scene
	var marker: Node2D = scene.find_child("PlayerSpawn",true,false)
	if marker == null: return _fail("Starting scene has no safe PlayerSpawn marker.")
	Player_Manager.get_local_player().global_position = marker.global_position
	checkpoint = {"combat_mode": false, "id": "entry:"+START_SCENE, "scene_id": START_SCENE, "position": [marker.global_position.x,marker.global_position.y], "facing": 1}
	if occupied:
		# Replacement is explicit. Preserve each original as a timestamped diagnostic archive.
		if not _archive_profile(profile):
			_present_error(last_error)
			return false
	var success := _save("manual",false,overwrite)
	if success and occupied: success = delete_slot(profile,"auto")
	if not success: _present_error(last_error)
	if success and not _test_mode:
		var story := scene.get_node_or_null("World")
		if story and story.has_method("begin_intro"): story.begin_intro()
	return success

func _archive_profile(profile: int) -> bool:
	var stamp := str(Time.get_ticks_usec())
	for kind in ["manual","auto"]:
		for backup in [false,true]:
			var path := path_for(profile,kind,backup)
			if FileAccess.file_exists(path):
				var error := DirAccess.copy_absolute(path,path+".replaced-"+stamp)
				if error != OK: return _fail("Could not archive the replaced profile: "+error_string(error))
	return true

func _default_snapshot(profile: int, character_name: String) -> Dictionary:
	var p := {"combat_mode": false, "phone_visible": true, "p_name": character_name.strip_edges(), "p_role": "", "p_mood": "", "player_level": 1, "p_max_health": 400, "p_curr_health": 400, "p_max_mana": 400.0, "p_curr_mana": 400.0, "current_field": "", "current_major": "", "current_minor": "", "completed_subjects": [], "academic_comprehension": {}, "equipped_spells": []}
	var q := {"version": 2, "owner_id": "local", "instances": [], "completed_quests": [], "claims": {}, "seen_events": {}, "selected_quest": "", "world_flags": {}, "pending_events": [], "inventory": [], "equipment": {}, "acquisition_receipts": {}, "max_slots": 64, "player_xp": 9999, "currency": 0, "learned_spells": [], "conversations": QuestConversationStore.new().to_dict()}
	var location := {"scene_id": START_SCENE,"position": [0,0],"facing": 1}
	return {"version": 1,"profile": profile,"slot": "manual","meta": {"name": p.p_name,"timestamp": Time.get_unix_time_from_system(),"playtime": 0},"player": p,"quest": q,"location": location,"checkpoint": {"combat_mode": false, "id": "entry:"+START_SCENE,"scene_id": START_SCENE,"position": [0,0],"facing": 1}}

func campaign_scene_ready(scene: Node) -> void:
	# ZoneRoot calls after its authoritative player spawn. Loads/new games set their own checkpoint.
	if loading or not session_ready or active_profile == 0 or scene != get_tree().current_scene: return
	await get_tree().process_frame
	if not is_instance_valid(scene) or scene != get_tree().current_scene: return
	var id := _campaign_scene_id()
	var marker: Node2D = scene.find_child("PlayerSpawn",true,false)
	if id.is_empty() or marker == null: return
	activate_checkpoint("entry:"+id, marker.global_position)

func activate_checkpoint(id: String, position: Vector2) -> bool:
	if not unavailable_reason().is_empty() or id.is_empty() or id.length() > 256 or not position.is_finite(): return false
	if not _safe_checkpoint_position(Player_Manager.get_local_player() as Player,position): return false
	checkpoint = {"combat_mode": Player_Global_Data.combat_mode, "id": id,"scene_id": _campaign_scene_id(),"position": [position.x,position.y],"facing": 1}
	request_autosave()
	return true

func recover_after_death() -> bool:
	if active_profile == 0 or not session_ready or _campaign_scene_id().is_empty(): return false
	# Prefer the latest durable autosave; never write the dead player's state.
	for kind in ["auto","manual"]:
		if inspect_slot(active_profile,kind).state == "valid": return await load_slot(active_profile,kind,false,true)
	return _fail("No valid checkpoint save. Use Load Game to recover a backup.")

func legacy_available() -> bool:
	return FileAccess.file_exists("user://quest-progress-v2.json")

func import_legacy(profile: int, source: String = "user://quest-progress-v2.json") -> bool:
	if _test_mode:
		if source != "user://quest-legacy-save-v1-test.json": return _fail("Use the isolated legacy fixture in tests.")
	elif source != "user://quest-progress-v2.json": return _fail("Invalid legacy import source.")
	if loading or writing or profile < 1 or profile > 3: return _fail("Invalid import destination.")
	for kind in ["manual","auto"]:
		for backup in [false,true]:
			if FileAccess.file_exists(path_for(profile,kind,backup)): return _fail("Import requires an empty profile.")
	var file := FileAccess.open(source,FileAccess.READ)
	if file == null or file.get_length() > GameSaveStore.MAX_BYTES: return _fail("Cannot read legacy save.")
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not value is Dictionary or QuestSaveService.stage(QuestManager,value).is_empty(): return _fail("Legacy Quest V2 save failed validation.")
	var data := _default_snapshot(profile,"Imported character")
	data.quest = value
	# Missing position/spells/academics use documented new-game defaults and authored safe spawn.
	var packed: PackedScene = Scene_Registry.get_scene(START_SCENE).scene
	var scene := packed.instantiate()
	var marker: Node2D = scene.find_child("PlayerSpawn",true,false)
	if marker == null:
		scene.free()
		return _fail("No safe starting spawn for import.")
	data.location.position = [marker.position.x,marker.position.y]
	data.checkpoint.position = data.location.position.duplicate()
	scene.free()
	if GameSaveSchema.stage(data,profile,Scene_Registry).is_empty(): return _fail("Legacy references cannot be imported safely.")
	var error := GameSaveStore.write(path_for(profile),data,false)
	if not error.is_empty(): return _fail(error)
	return true # Original legacy file remains untouched.

func _position_embedded(player: Player, position: Vector2) -> bool:
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = Transform2D(player.global_rotation,position + shape.position)
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	for hit in player.get_world_2d().direct_space_state.intersect_shape(query,16):
		if hit.collider is StaticBody2D or hit.collider is TileMapLayer: return true
	return false

func _safe_checkpoint_position(player: Player, position: Vector2) -> bool:
	if not is_instance_valid(player) or _position_embedded(player,position): return false
	# Checkpoint authoring requires nearby ground, not an arbitrary airborne coordinate.
	var floor_query := PhysicsRayQueryParameters2D.create(position,position+Vector2(0,240),player.collision_mask,[player.get_rid()])
	var floor_hit := player.get_world_2d().direct_space_state.intersect_ray(floor_query)
	return not floor_hit.is_empty() and (floor_hit.collider is StaticBody2D or floor_hit.collider is TileMapLayer)

func _present_error(message: String) -> void:
	# New Game has already entered gameplay when its initial durable write returns.
	var dialog := AcceptDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.title = "Save failed"
	dialog.dialog_text = message + "\nExisting save data has been preserved. Retry Save after resolving the storage problem."
	get_tree().root.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
