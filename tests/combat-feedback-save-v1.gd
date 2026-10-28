extends Node
var checks := 0
var failures := 0
var fixture: Dictionary
var player: Player
const PROFILE := 3
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func _ready() -> void:
	await get_tree().process_frame
	# Driver survives production scene transitions; files are test-prefixed by --quest-test-mode.
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args():
		push_error("This suite requires --quest-test-mode")
		get_tree().quit(2)
		return
	if "--read-full-save" in OS.get_cmdline_user_args(): await _read_process()
	else: await _write_process()
	SaveManager._autosave_pending = false
	QuestManager.persistence_enabled = false
	QuestManager._save_timer.stop()
	print("COMBAT_FEEDBACK_SAVE_V1: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _write_process() -> void:
	for kind in ["manual","auto"]: SaveManager.delete_slot(PROFILE,kind)
	check(await SaveManager.new_game(PROFILE,"Regression Yan"),"New Game initializes and durably saves an isolated campaign")
	if Dialogic.current_timeline: Dialogic.end_timeline()
	await get_tree().process_frame
	player = Player_Manager.get_local_player() as Player
	check(player != null and SaveManager.session_ready,"Player exists before restoration completes")
	if player == null: return
	player.set_physics_process(false)
	check(QuestManager.reward_claims.is_empty() and Inventory_Manager.inventory.is_empty() and Player_Global_Data.player_exp == 9999,"New profile has clean quests, inventory and actual XP defaults")
	check(QuestManager.live_offers.is_empty() and Player_Global_Data.completed_subjects.is_empty(),"New profile has clean offers and academic state")
	await _feedback()
	# Exercise the real quest claim transaction through full-game autosave.
	QuestManager.persistence_enabled = true
	Player_Global_Data.player_exp = 0
	var first := QuestManager.offer_quest("quest_bakau_001","bakau_field_researcher")
	QuestManager.accept_quest(first.instance_id)
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED,"enemy_mangroove_snakehead_murrel",8))
	check(QuestManager.try_hand_off(first.instance_id,"bakau_field_researcher"),"Real reward transaction commits one coherent full-game autosave")
	check(Player_Global_Data.player_exp == 120 and SaveManager.inspect_slot(PROFILE,"auto").state == "valid","Reward XP and claim are durable in autosave")
	var second := QuestManager.offer_quest("quest_bakau_002","bakau_field_researcher")
	QuestManager.decide_offer(QuestManager.present_offer(second.instance_id,"bakau_field_researcher"),"accept")
	Inventory_Manager.pickup(QuestManager.registry.items.drop_001,2,"full-save-pickup")
	# Exercise the existing equipment map using a registered item; no item definitions change.
	var equipment_item: ItemData = QuestManager.registry.items.drop_002
	Inventory_Manager.add_item(equipment_item,1,"equipment-fixture")
	Inventory_Manager.equip_item(equipment_item,Inventory_Manager.SlotType.ACCESSORY_1)
	check(Inventory_Manager.get_equipped(Inventory_Manager.SlotType.ACCESSORY_1) == equipment_item,"Existing inventory API stages equipped-item persistence")
	QuestManager.select_quest(second.instance_id)
	QuestManager.mark_conversation_read("bakau_field_researcher")
	QuestManager.set_world_flag("save_test_gate",true)
	Player_Global_Data.current_field = "Physics"
	Player_Global_Data.current_major = "Mechanics"
	Player_Global_Data.current_minor = "Thermal"
	Player_Global_Data.completed_subjects.assign(["PHY-001"])
	Player_Global_Data.set_comprehension(&"physics",3)
	Player_Global_Data.phone_visible = false
	Player_Global_Data.set_meta("keys",["regression_key"])
	Inventory_Manager.max_slots = 80
	Player_Global_Data.player_level = 4
	Player_Global_Data.p_curr_health = 213
	Player_Global_Data.p_curr_mana = 167
	player.global_position = Vector2(540,760)
	check(not SaveManager.activate_checkpoint("unsafe-checkpoint",Vector2(220,1000)),"Checkpoint refuses a coordinate embedded in the ground")
	check(SaveManager.activate_checkpoint("regression-checkpoint",Vector2(220,760)),"Checkpoint records a safe campaign coordinate")
	check(SaveManager.save_active(),"Manual save validates full player, academic, spell and quest state: " + SaveManager.last_error)
	fixture = SaveManager.snapshot()
	check(SaveManager.inspect_slot(PROFILE).name == "Regression Yan" and SaveManager.inspect_slot(PROFILE).level == 4,"Slot metadata comes from real saved state")
	check(SaveManager.path_for(PROFILE) != SaveManager.path_for(PROFILE,"auto"),"Manual and autosave destinations are separate")
	var bytes := FileAccess.get_file_as_bytes(SaveManager.path_for(PROFILE))
	check(SaveManager.save_active() and SaveManager.save_active(),"Repeated synchronous saves serialize without concurrent writes")
	check(SaveManager.inspect_slot(PROFILE,"manual",true).state == "valid","Previous valid full snapshot is backed up")
	var bad := fixture.duplicate(true)
	bad.location.scene_id = "../../arbitrary.gd"
	check(GameSaveSchema.stage(bad,PROFILE,Scene_Registry).is_empty(),"Arbitrary executable scene destinations are rejected")
	bad = fixture.duplicate(true)
	bad.quest.inventory[0].quantity = 1.5
	check(GameSaveSchema.stage(bad,PROFILE,Scene_Registry).is_empty(),"Fractional item quantities are rejected")
	bad = fixture.duplicate(true)
	bad.player.equipped_spells = ["retired-spell"]
	check(GameSaveSchema.stage(bad,PROFILE,Scene_Registry).is_empty(),"Missing spell IDs fail safely")
	bad = fixture.duplicate(true)
	bad.player.p_curr_health = 0
	check(GameSaveSchema.stage(bad,PROFILE,Scene_Registry).is_empty(),"Dead snapshots are rejected")
	check(not GameSaveStore.valid_path("user://campaign-v1/../other.json") and GameSaveStore.write("user://unrelated.json",fixture,false) != "","Save store restricts all full-game writes to fixed slot paths")
	# Corrupt only the isolated fixture. Backup is offered explicitly, never silently loaded.
	var file := FileAccess.open(SaveManager.path_for(PROFILE),FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	var xp_before := Player_Global_Data.player_exp
	var unsupported := fixture.duplicate(true)
	unsupported.location.scene_id = "spell_tree"
	check(not await SaveManager._restore(GameSaveSchema.stage(unsupported,PROFILE,Scene_Registry),PROFILE) and Player_Manager.get_local_player() == player,"Unsupported destination refuses restoration without replacing the live player")
	check(not await SaveManager.load_slot(PROFILE) and Player_Global_Data.player_exp == xp_before,"Damaged save refuses load without mutating progression")
	check(SaveManager.inspect_slot(PROFILE).state == "damaged" and SaveManager.inspect_slot(PROFILE,"manual",true).state == "valid","Damaged primary and recoverable backup are distinguished")
	check(not SaveManager.save_active(),"Ordinary save preserves damaged diagnostic evidence")
	check(await SaveManager.load_slot(PROFILE,"manual",true),"Explicit backup recovery restores the production campaign scene")
	player = Player_Manager.get_local_player() as Player
	player.set_physics_process(false)
	check(player.hitbox.effects.entries.is_empty() and not get_tree().paused and Player_Global_Data.p_moveable,"Load clears temporary effects and restores control")
	check(player.global_position == Vector2(540,760),"Position restores only after production player initialization")
	# Restore the primary fixture for the independent process, preserving backup.
	var error := GameSaveStore.write(SaveManager.path_for(PROFILE),fixture,false)
	check(error.is_empty(),"Fixture repaired explicitly for fresh-process verification")
	# Failure before temporary open must leave an existing good save untouched.
	bytes = FileAccess.get_file_as_bytes(SaveManager.path_for(PROFILE))
	DirAccess.make_dir_absolute(SaveManager.path_for(PROFILE)+".tmp")
	check(not SaveManager.save_active() and FileAccess.get_file_as_bytes(SaveManager.path_for(PROFILE)) == bytes,"Failed temporary write preserves the previous primary bytes")
	DirAccess.remove_absolute(SaveManager.path_for(PROFILE)+".tmp")
	# Legacy validation/import retains original bytes and all reward/event receipts.
	var legacy_path := "user://quest-legacy-save-v1-test.json"
	QuestSaveService.write_atomic(legacy_path,fixture.quest)
	var original := FileAccess.get_file_as_bytes(legacy_path)
	for kind in ["manual","auto"]: SaveManager.delete_slot(2,kind)
	check(SaveManager.import_legacy(2,legacy_path),"Legacy Quest V2 can be explicitly imported into an empty profile")
	var imported := GameSaveStore.read(SaveManager.path_for(2))
	check(imported.quest.claims == fixture.quest.claims and int(imported.quest.acquisition_receipts.get("full-save-pickup",0)) == 2 and original == FileAccess.get_file_as_bytes(legacy_path),"Legacy import preserves claims, receipts and original file")
	check(imported.player.equipped_spells.is_empty() and imported.player.completed_subjects.is_empty(),"Legacy missing spell equipment and academics use explicit safe defaults")
	check(await SaveManager.new_game(2,"Replacement character",true),"Explicit New Game replacement succeeds after archiving the prior profile")
	check(SaveManager.inspect_slot(2).name == "Replacement character" and SaveManager.inspect_slot(2,"auto").state == "empty" and QuestManager.reward_claims.is_empty(),"Replacement starts clean and does not retain the old autosave")
	DirAccess.remove_absolute(legacy_path)
	for kind in ["manual","auto"]: SaveManager.delete_slot(2,kind)
	for file_name in DirAccess.get_files_at(GameSaveStore.ROOT):
		if file_name.begins_with("test-profile-2-") and ".replaced-" in file_name: DirAccess.remove_absolute(GameSaveStore.ROOT+file_name)
	var world := get_tree().current_scene
	var key_scene := load("res://components/dungeon/key/key.tscn") as PackedScene
	var key := key_scene.instantiate() as Key
	key.name = "PersistenceTestKey"
	world.add_child(key)
	var flag := WorldPersistence.flag_for(key,"collected")
	key._pick_up()
	check(not flag.is_empty() and QuestManager.world_flags.get(flag,false),"Collecting an authored dungeon key writes its stable world flag")
	await get_tree().process_frame
	key = key_scene.instantiate() as Key
	key.name = "PersistenceTestKey"
	world.add_child(key)
	check(key.is_queued_for_deletion(),"A collected key stays absent when its authored node is recreated")
	var peer := ENetMultiplayerPeer.new()
	var network_error := peer.create_server(0)
	check(network_error == OK,"Multiplayer boundary fixture opens a local ephemeral peer")
	if network_error == OK:
		multiplayer.multiplayer_peer = peer
		check(not SaveManager.save_active() and not await SaveManager.load_slot(PROFILE),"Multiplayer blocks local campaign saving and loading")
		multiplayer.multiplayer_peer = null
		peer.close()
	var campaign_bytes := FileAccess.get_file_as_bytes(SaveManager.path_for(PROFILE))
	get_tree().change_scene_to_file("res://scenes/combat/boss-prototype-room.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	check(not SaveManager.save_active() and FileAccess.get_file_as_bytes(SaveManager.path_for(PROFILE)) == campaign_bytes,"Actual boss prototype training loadout cannot overwrite the campaign")
	check(await SaveManager.load_slot(PROFILE),"Campaign can be restored after the standalone boss room")
	if "--capture-save-v1" in OS.get_cmdline_user_args(): await _captures()

func _feedback() -> void:
	var hud: StatusEffectsHUD = player.camera.get_node("UI/StatusEffectsHUD")
	hud.bind_player(player)
	player.hitbox.clear_all_effects()
	check(hud.grouped_entries().is_empty() and not hud.visible,"No active effects leaves no HUD panel")
	player.hitbox.effects.apply("buff_speed",2,{"amount":10},"test",ActiveEffectManager.StackPolicy.STACK,3,true)
	player.hitbox.effects.apply("buff_speed",4,{"amount":10},"test2",ActiveEffectManager.StackPolicy.STACK,3,true)
	player.hitbox._apply_stun(2)
	check(hud.grouped_entries().size() == 2 and hud.grouped_entries()[0].key == "stun" and hud.grouped_entries()[1].count == 2,"HUD favors dangerous debuffs and counts independent buff stacks")
	var detached := player.hitbox.effects.get_entries()
	detached[0].remaining = 999
	check(player.hitbox.effects.get_entries()[0].remaining == 2,"HUD read-only entries cannot mutate authoritative timing")
	player.hitbox.effects.apply("stun",5,{})
	check(hud.grouped_entries()[0].remaining == 5 and hud.grouped_entries()[0].count == 1,"Refresh updates duration without duplicate stacks")
	player.hitbox.clear_all_debuffs()
	check(hud.grouped_entries().size() == 1 and hud.grouped_entries()[0].key == "buff_speed","Clearing debuffs retains buffs")
	player.hitbox.effects.apply("mixed",5,{},"",ActiveEffectManager.StackPolicy.STACK,3,true)
	player.hitbox.effects.apply("mixed",5,{},"",ActiveEffectManager.StackPolicy.STACK,3,false)
	player.hitbox.clear_all_buffs()
	check(player.hitbox.effects.get_entries().size() == 1 and not player.hitbox.effects.get_entries()[0].beneficial,"Selective clear preserves opposite-classification stacks with the same key")
	player.hitbox.effects.tick(6)
	check(hud.grouped_entries().is_empty(),"Expiration removes the final icon immediately")
	for i in 12: player.hitbox.effects.apply("future_%02d"%i,1,{})
	check(hud.icons.size() == 8 and hud.overflow.visible and hud.overflow.text == "+4","Future effects use fallback icons and compact deterministic overflow")
	var nodes := hud.get_child_count()
	for i in 30: hud.refresh()
	check(hud.get_child_count() == nodes,"Repeated HUD updates reuse cached icon nodes")
	player.hitbox.clear_all_effects()
	var heal := HealEffect.new()
	heal.duration = 2
	heal.amount = 1
	heal.execute(SpellCastContext.new(player,Spell_Library.get_spell_by_id("phys-strike")),player)
	check(player.hitbox.effects.get_entries()[0].beneficial,"Direct healing-over-time application is classified as a buff")
	player.hitbox.clear_all_buffs()
	player.hitbox.apply_status("hot",2,{"amount":1},"status-path",ActiveEffectManager.StackPolicy.REFRESH,1)
	check(player.hitbox.effects.get_entries()[0].beneficial,"Hitbox healing status uses the same beneficial classification")
	player.hitbox.clear_all_effects()
	for id in ["phys_strike","phys_resonate","phys_shatterwave"]:
		var s := Spell_Library.get_spell_by_id(id)
		if s == null:
			# IDs are authored with hyphens in this project's spell manifest.
			s = Spell_Library.get_spell_by_id(id.replace("_","-"))
		if s: Player_Global_Data.add_spell(s); Player_Global_Data.equip_spell(s)
	check(Player_Global_Data.equipped_spells.size() == 3,"Particle fixture uses authored shared-prefix Physics spells")
	Player_Global_Data.combat_mode = true
	player._enter_casting_stance()
	var emitter := player.get_node("IncantationInputParticles")
	var bursts: int = emitter.bursts
	var longest: SpellData = Player_Global_Data.equipped_spells.back()
	for key in longest.spell_incantation: player._add_sequence(key)
	check(emitter.bursts == bursts + longest.spell_incantation.size(),"Every valid prefix and completion emits once, independent of execution")
	bursts = emitter.bursts
	player._add_sequence("invalid")
	player.hitbox._apply_silence(1)
	player._add_sequence(longest.spell_incantation[0])
	check(emitter.bursts == bursts,"Invalid and silenced inputs never emit success feedback")
	player.hitbox.clear_all_effects()
	player.hitbox._apply_stun(1)
	player._add_sequence(longest.spell_incantation[0])
	check(emitter.bursts == bursts,"Stun blocks accepted-direction feedback")
	player.hitbox.clear_all_effects()
	get_tree().paused = true
	player._add_sequence(longest.spell_incantation[0])
	get_tree().paused = false
	check(emitter.bursts == bursts,"Modal pause intercepts valid-input feedback")
	player.set_multiplayer_authority(2)
	player._add_sequence(longest.spell_incantation[0])
	player.set_multiplayer_authority(1)
	check(emitter.bursts == bursts,"Remote authority never produces the local accepted event")
	player._enter_casting_stance()
	player._clear_sequence()
	var short: SpellData = Player_Global_Data.equipped_spells[0]
	for key in short.spell_incantation: player._add_sequence(key)
	player._add_sequence(short.spell_incantation[0])
	check(emitter.bursts == bursts + short.spell_incantation.size() + 1,"Valid CHAINED restart emits once without dropping its first key")
	player._clear_sequence()
	bursts = emitter.bursts
	Player_Global_Data.p_curr_mana = 0
	for key in short.spell_incantation: player._add_sequence(key)
	check(emitter.bursts == bursts + short.spell_incantation.size(),"Execution failure on mana/cooldown still confirms every accepted direction")
	Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
	bursts = emitter.bursts
	player._exit_casting_stance()
	player._add_sequence(longest.spell_incantation[0])
	check(emitter.bursts == bursts and emitter.amount == 6,"Outside-stance input is ignored and rapid emission has a fixed six-particle pool")

func _read_process() -> void:
	check(SaveManager.active_profile == 0 and QuestManager.reward_claims.is_empty(),"Fresh process does not auto-load legacy or another profile")
	check(await SaveManager.load_slot(PROFILE),"Fresh process continues the intended full-game slot")
	player = Player_Manager.get_local_player() as Player
	if player == null: return
	player.set_physics_process(false)
	check(player.global_position == Vector2(540,760) and SaveManager._campaign_scene_id() == SaveManager.START_SCENE,"Fresh process restores correct scene and world position")
	check(Player_Global_Data.combat_mode and not Player_Global_Data.phone_visible,"Scene-specific combat context and phone availability survive restart")
	check(Player_Global_Data.p_curr_health == 213 and Player_Global_Data.p_curr_mana == 167,"Fresh process restores current health and mana")
	check(Player_Global_Data.player_level == 4 and Player_Global_Data.current_major == "Mechanics" and Player_Global_Data.completed_subjects == ["PHY-001"] and Player_Global_Data.academic_comprehension[&"physics"] == 3,"Fresh process restores identity and academic progression")
	check(Player_Global_Data.equipped_spells.size() == 3 and Player_Global_Data.learned_spells.size() == 3,"Fresh process resolves learned and ordered equipped Resources through spell IDs")
	check(Player_Global_Data.player_exp == 120 and Inventory_Manager.get_item_quantity("craft_cons_001") == 2,"Fresh process restores exact reward XP and inventory quantity")
	check(Player_Global_Data.get_meta("keys",[]) == ["regression_key"] and Inventory_Manager.max_slots == 80,"Dungeon keys and inventory capacity survive restart")
	check(Inventory_Manager.get_equipped(Inventory_Manager.SlotType.ACCESSORY_1).item_id == "drop_002","Fresh process restores equipped item Resources in their slots")
	check(QuestManager.world_flags.get("save_test_gate",false),"Fresh process restores durable world flags")
	check(Inventory_Manager.pickup(QuestManager.registry.items.drop_001,2,"full-save-pickup") == 0,"Fresh process rejects replayed acquisition receipt")
	var claimed: QuestInstance
	for instance in QuestManager._active_instances.values():
		if instance.quest_data.quest_id == "quest_bakau_001": claimed = instance
	check(claimed != null and not QuestManager.try_hand_off(claimed.instance_id,"bakau_field_researcher"),"Fresh process rejects duplicate quest reward claims")
	var contact: QuestConversation = QuestManager.conversations.contacts.get("bakau_field_researcher")
	check(contact != null and not contact.unread(),"Conversation decisions and read state survive restart")
	check(QuestManager.get_instance(QuestManager.selected_instance_id).quest_data.quest_id == "quest_bakau_002","Tracked active quest survives restart")
	check(get_tree().get_nodes_in_group("player").filter(func(node): return node is Player).size() == 1,"Scene load creates exactly one campaign player")
	Player_Global_Data.p_curr_health = 0
	check(not SaveManager.save_active(),"Death cannot overwrite a valid manual checkpoint")
	check(await SaveManager.recover_after_death(),"Death restores the last durable checkpoint")
	check(Player_Global_Data.p_curr_health == Player_Global_Data.p_max_health and Player_Manager.get_local_player().global_position == Vector2(220,760),"Checkpoint recovery restores full health at a safe authored position")
	check(not await SaveManager.new_game(PROFILE,"Accidental replacement"),"New Game refuses to replace an occupied profile without explicit confirmation")
	for kind in ["manual","auto"]: SaveManager.delete_slot(PROFILE,kind)

func _captures() -> void:
	await load("res://tests/save-v1-preview.gd").capture(self)
