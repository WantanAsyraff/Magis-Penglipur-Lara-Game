extends Node
var checks := 0
var failures := 0
var events: Array[SpellCastContext] = []
var path := "user://v3-bindings-test.cfg"
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + text)
func key(code: int) -> InputEventKey:
	var event := InputEventKey.new(); event.physical_keycode = code; return event
func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	if "--quest-test-mode" not in OS.get_cmdline_user_args() or not OS.get_user_data_dir().contains("v3-test-users"):
		push_error("V3 tests require --quest-test-mode and an isolated existing v3-test-users XDG_DATA_HOME directory")
		get_tree().quit(2); return
	if "--read-v3-bindings" in OS.get_cmdline_user_args():
		check(ControlBindings.preset_name(ControlBindings.snapshot()) == "Arrow Keys", "Fresh process restores saved application preset")
		print("COMBAT_CONTROLS_V3: %d checks, %d failures" % [checks, failures]); get_tree().quit(failures); return
	await _controls()
	await _gameplay()
	QuestManager.persistence_enabled = false; QuestManager._save_timer.stop(); SaveManager._autosave_pending = false
	print("COMBAT_CONTROLS_V3: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func _controls() -> void:
	var original := ControlBindings.snapshot()
	var bindings := ControlBindings.snapshot()
	var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_Y
	bindings.incantation_up.append(pad)
	for preset in ["IJKL", "Arrow Keys", "IJKL"]:
		ControlBindings.set_preset(bindings, preset)
		check(ControlBindings.preset_name(bindings) == preset, preset + " recognized after switching")
		for i in 4:
			check(bindings[ControlBindings.CAST_ACTIONS[i]][0].physical_keycode == ControlBindings.PRESETS[preset][i], preset + " physical key " + str(i))
		check(bindings.incantation_up.has(pad), "Preset retains controller mapping")
	check(bindings.move_left[0].is_match(original.move_left[0]), "Movement binding is untouched")
	check(bindings.jump[0].is_match(original.jump[0]), "Jump binding is untouched")
	ControlBindings.replace_family(bindings, "incantation_up", key(KEY_U))
	check(ControlBindings.preset_name(bindings) == "Custom", "Custom keyboard mapping recognized")
	check(not ControlBindings.conflicts(bindings, "incantation_up", key(KEY_A)).is_empty(), "Physical keyboard duplicate warning detects movement overlap")
	var motion := InputEventJoypadMotion.new(); motion.axis = JOY_AXIS_LEFT_X; motion.axis_value = -1
	var mouse := InputEventMouseButton.new(); mouse.button_index = MOUSE_BUTTON_RIGHT
	var modified := key(KEY_Q); modified.ctrl_pressed = true
	for event in [pad, motion, mouse, modified]:
		var decoded := ControlBindings.decode(ControlBindings.encode(event))
		check(decoded.get_class() == event.get_class() and decoded.is_match(event), "Typed serializer round trip: " + event.get_class())
	bindings.incantation_left.append(motion); bindings.start_incantation.append(mouse)
	check(ControlBindings.save_bindings(bindings, path) == OK, "Typed bindings save to disk")
	InputMap.action_erase_events("incantation_up"); ControlBindings.load_bindings(path)
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == "Custom" and InputMap.action_get_events("incantation_up").any(func(e): return e is InputEventJoypadButton), "Disk restore keeps custom keyboard and controller")
	var legacy := ConfigFile.new(); legacy.set_value("keybinds", "incantation_up", [{"physical_keycode": KEY_I, "keycode": 0}]); legacy.save(path)
	ControlBindings.load_bindings(path)
	check(InputMap.action_get_events("incantation_up").any(func(e): return e is InputEventJoypadButton), "Legacy keyboard file preserves existing controller events")
	ControlBindings.apply(original)
	var menu: Control = load("res://scenes/ui/menus/settings-menu.tscn").instantiate()
	add_child(menu)
	menu._select_category("Spellcasting"); menu._preset("Arrow Keys")
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == ControlBindings.preset_name(original), "Settings draft does not mutate gameplay")
	menu.assistance_mode = 2
	check(Player_Global_Data.assistance_mode != 2, "Draft assistance stays unapplied")
	menu._reset_section()
	check(ControlBindings.preset_name(menu.draft) == "IJKL", "Reset section restores authored casting defaults")
	check(menu.draft.move_left[0].is_match(original.move_left[0]), "Section reset preserves movement")
	menu._on_rebind_requested(menu._rows[0])
	var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true; menu._input(escape)
	check(menu._listening_row == null, "Escape cancels input capture")
	menu._on_rebind_requested(menu._rows[0])
	var capture_pad := InputEventJoypadButton.new(); capture_pad.button_index = JOY_BUTTON_RIGHT_SHOULDER; capture_pad.pressed = true
	menu._input(capture_pad)
	check(menu.draft.incantation_up.any(func(e): return e is InputEventJoypadButton) and menu.draft.incantation_up.any(func(e): return e is InputEventKey), "Controller remap retains the keyboard family")
	menu._on_cancel()
	menu.free()
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == ControlBindings.preset_name(original), "Closing uncommitted editor discards draft")
	await get_tree().process_frame
	menu = load("res://scenes/ui/menus/settings-menu.tscn").instantiate(); add_child(menu)
	menu._select_category("Spellcasting"); menu._preset("Arrow Keys"); menu.assistance_mode = 1
	menu._on_save()
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == "Arrow Keys" and Player_Global_Data.assistance_mode == 1, "Settings Apply commits draft bindings and assistance")
	var cfg := ConfigFile.new()
	check(cfg.load(ControlBindings.SAVE_PATH) == OK and cfg.get_value("format", "version") == 2, "Settings Apply persists versioned bindings")
	menu.free()
	await get_tree().process_frame
	var panel := CastingPresetPanel.new(); add_child(panel)
	panel.select("Custom")
	check(panel.confirm_button.disabled and panel.selected == "Custom", "Custom new-game controls require explicit card selection")
	panel.select("Arrow Keys")
	check(panel.cards[1].button_pressed and not panel.confirm_button.disabled, "Arrow card is selectable")
	panel.select("IJKL")
	check(panel.cards[0].button_pressed, "IJKL card is selectable")
	panel.cards[0].grab_focus()
	var navigation := InputEventKey.new(); navigation.keycode = KEY_RIGHT; navigation.pressed = true
	get_viewport().push_input(navigation, true)
	navigation = navigation.duplicate(); navigation.pressed = false; get_viewport().push_input(navigation, true)
	await get_tree().process_frame
	check(get_viewport().gui_get_focus_owner() == panel.cards[1], "UI arrows navigate between casting cards")
	var accept := InputEventJoypadButton.new(); accept.button_index = JOY_BUTTON_A; accept.pressed = true
	get_viewport().push_input(accept, true)
	accept = accept.duplicate(); accept.pressed = false; get_viewport().push_input(accept, true)
	await get_tree().process_frame
	check(panel.selected == "Arrow Keys", "Controller accept selects the focused preset card")
	panel.free()
	var campaign: Control = load("res://scenes/ui/menus/intro-menus/new-game-menu.tscn").instantiate()
	add_child(campaign); campaign.name_input.text = "V3 Yan"; campaign.selected_profile = 3
	var before := SaveManager.active_profile
	campaign._begin(false)
	check(is_instance_valid(campaign.preset_panel) and SaveManager.active_profile == before, "New Game displays preset panel before campaign creation")
	campaign.preset_panel.backed.emit()
	await get_tree().process_frame
	check(SaveManager.active_profile == before and not SaveManager.loading, "Back from preset panel never creates a campaign")
	campaign.free()
	DirAccess.remove_absolute(path)

func _gameplay() -> void:
	for kind in ["manual", "auto"]: SaveManager.delete_slot(3, kind)
	var campaign: Control = load("res://scenes/ui/menus/intro-menus/new-game-menu.tscn").instantiate()
	add_child(campaign); campaign.name_input.text = "V3 Yan"; campaign.selected_profile = 3
	campaign._begin(false); campaign.preset_panel.select("Arrow Keys")
	campaign.preset_panel.confirmed.emit("Arrow Keys")
	for i in 300:
		await get_tree().process_frame
		if SaveManager.session_ready and not SaveManager.loading: break
	check(SaveManager.session_ready and SaveManager.active_profile == 3, "Preset confirmation creates production campaign")
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == "Arrow Keys", "Confirmed new-game preset changes real InputMap")
	campaign.free()
	var player := Player_Manager.get_local_player() as Player
	if player == null: check(false, "Production player exists"); return
	player.set_physics_process(false); player.hitbox.set_physics_process(false)
	Player_Global_Data.combat_mode = true
	Player_Global_Data.assistance_mode = 0; Player_Global_Data.assistance_changed.emit(0)
	var spells: Array[SpellData] = [load("res://data/magis/spells/phys-strike.tres"), load("res://data/magis/spells/phys-resonate.tres"), load("res://data/magis/spells/phys-shatterwave.tres")]
	Player_Global_Data.learned_spells.assign(spells); Player_Global_Data.equipped_spells.assign(spells); Player_Global_Data.spells_updated.emit()
	player._enter_casting_stance()
	var aura := player.get_node("IncantationInputParticles")
	aura._process(0.2)
	check(aura.active and aura.aura.emitting, "Entering stance activates idle CPU aura")
	var count: int = aura.bursts
	player._add_sequence("right")
	check(aura.bursts == count, "Rejected direction never increases accepted-input feedback")
	var focus_button := Button.new(); focus_button.text = "Modal focus"; add_child(focus_button); focus_button.grab_focus()
	var blocked: InputEventKey = InputMap.action_get_events("incantation_down")[0].duplicate(); blocked.pressed = true
	player._unhandled_input(blocked)
	check(player.incantations.sequence.is_empty(), "Focused menu blocks casting arrows from gameplay")
	focus_button.release_focus(); focus_button.free()
	var ui := player.chain_assistant
	check(ui.shown_spells == spells, "HUD discovers equipped spells in path-length order")
	for view in ui.views:
		if view.column.visible: check(view.icon.get_index() > view.path.get_index(), "Actual icon is below directional path")
	for preset in ["IJKL", "Arrow Keys"]:
		player._clear_sequence(); player.casting.cooldowns.clear(); Player_Global_Data.p_curr_mana = 400
		var bindings := ControlBindings.snapshot(); ControlBindings.set_preset(bindings, preset); ControlBindings.apply(bindings)
		for direction in ["down", "left"]:
			var e: InputEventKey = InputMap.action_get_events("incantation_" + direction)[0].duplicate(); e.pressed = true
			player._process_incantation_inputs(e)
		check(player.incantations.get_sequence_snapshot() == ["down", "left"], preset + " drives actual spell input")
		check(ui.views[0].path.text.contains("[u]"), "Entered path has an underline as well as brightness")
		var old: float = aura.buildup
		var released: int = aura.releases
		player._add_sequence("down")
		check(player.incantations.get_current_exact_match() == spells[0] and ui.shown_spells.has(spells[2]), "Completed prefix preserves longer HUD paths")
		for i in 90: player.casting._physics_process(1.0/60)
		check(aura.releases > released and aura.buildup > 0, "Successful prefix releases and retains partial buildup")
		player._add_sequence("left")
		var retained: float = aura.buildup
		player._add_sequence("down")
		check(aura.buildup >= retained, "Terminal resolver reset retains buildup until queued delivery")
		for i in 120: player.casting._physics_process(1.0/60)
		check(player.incantations.sequence.is_empty(), "Longer CHAINED continuation reaches terminal spell")
	player._clear_sequence(); player.casting.cooldowns.clear(); Player_Global_Data.p_curr_mana = 0
	var releases: int = aura.releases
	for direction in spells[0].spell_incantation: player._add_sequence(direction)
	check(aura.releases == releases, "Mana failure never shows successful release")
	player.cancel_active_casting()
	check(aura.buildup == 0, "Explicit cancellation dissipates buildup")
	player._exit_casting_stance(); aura._process(1)
	check(not aura.aura.emitting and not aura.flow.emitting, "Exiting stance fades continuous emitters")
	check(aura.amount + aura.aura.amount + aura.flow.amount + aura.release.amount == 74, "CPU particle count bounded to 74 with defaults")
	# Live channels launch before their completion; release exactly once on delivery.
	var jet: SpellData = load("res://data/magis/spells/phys-pressure-jet.tres")
	Player_Global_Data.learned_spells.append(jet); Player_Global_Data.equipped_spells.append(jet)
	player.casting.cancel(); player.casting.cooldowns.clear(); Player_Global_Data.p_curr_mana = 400
	var launched: int = aura.releases
	check(player.casting.request_cast(jet, player.global_position, Vector2.RIGHT), "Authored live beam enters preparation")
	player.casting._physics_process(0.21)
	check(aura.releases == launched + 1 and player.casting.state == SpellCastingComponent.State.CHANNELING, "Live beam releases when launched, before completion")
	player.casting._physics_process(2.0)
	check(aura.releases == launched + 1, "Channel completion never duplicates launch burst")
	Player_Global_Data.learned_spells.assign(spells); Player_Global_Data.equipped_spells.assign(spells)
	# Exercise long paths and eight equipped definitions without casting or saving fixtures.
	var many: Array[SpellData] = []
	for i in 8:
		var definition: SpellData = spells[0].duplicate(true)
		definition.spell_id = "v3-path-" + str(i); definition.spell_name = "Path " + str(i)
		definition.spell_incantation.clear()
		for j in (32 if i == 0 else i + 2): definition.spell_incantation.append("up")
		definition.spell_incantation.append("left" if i % 2 == 0 else "right")
		if i == 0: definition.spell_icon = null
		many.append(definition)
	player.incantations.rebuild(many); player._enter_casting_stance()
	check(ui.shown_spells.size() == 4 and ui.overflow.text == "+4", "Eight equipped paths use four cached views with deterministic overflow")
	for i in 10: player.incantations.push("up")
	check(ui.shown_spells.size() == 1 and ui.views[0].icon.texture == ui.fallback_icon, "Long path stays readable and missing icon uses fallback")
	var snapshot := player.incantations.get_sequence_snapshot()
	for i in 40: ui._refresh()
	check(player.incantations.get_sequence_snapshot() == snapshot, "HUD refresh never mutates sequence or executes spell")
	Player_Global_Data.assistance_mode = 1; Player_Global_Data.assistance_changed.emit(1)
	check(ui.visible and not ui.views[0].title.visible, "Minimal mode suppresses supporting names")
	Player_Global_Data.assistance_mode = 2; Player_Global_Data.assistance_changed.emit(2)
	check(not ui.visible, "Off mode hides optional guidance")
	Player_Global_Data.assistance_mode = 0; Player_Global_Data.assistance_changed.emit(0)
	player.incantations.rebuild(spells); player._exit_casting_stance()
	var weapon: ItemData = load("res://data/items/equipment/practice-magis-focus.tres")
	var rig: WeaponVisualController = player.get_node("WeaponRig")
	check(not rig.visible, "Empty slot has no weapon visual")
	Inventory_Manager.add_item(weapon)
	var inventory_ui: InventoryUI = load("res://scenes/ui/inventory/inventory-ui.tscn").instantiate(); add_child(inventory_ui)
	inventory_ui._select_item(weapon); inventory_ui.equip_button.pressed.emit()
	check(Inventory_Manager.get_equipped(Inventory_Manager.SlotType.WEAPON) == weapon, "Production inventory Equip button uses existing WEAPON slot")
	inventory_ui.free()
	check(rig.visible and rig.visual.get_child_count() == 1, "Existing equipment API attaches exactly one weapon scene")
	var replacement: ItemData = weapon.duplicate(true); replacement.item_id = "v3-replacement"
	Inventory_Manager.add_item(replacement); Inventory_Manager.equip_item(replacement, Inventory_Manager.SlotType.WEAPON)
	check(rig.equipped == replacement and rig.visual.get_child_count() == 1, "Weapon replacement swaps presentation once")
	Inventory_Manager.equip_item(weapon, Inventory_Manager.SlotType.WEAPON); Inventory_Manager.remove_item(replacement)
	check(Inventory_Manager.get_item_quantity(weapon.item_id) == 0 and rig.equipped == weapon, "Equipment swaps retain authoritative item quantities")
	Inventory_Manager.equipment_changed.emit(Inventory_Manager.SlotType.WEAPON, weapon)
	check(rig.visual.get_child_count() == 1, "Repeated equipment signal never duplicates visual")
	player.get_node("PlayerSprite").flip_h = true; rig._update_facing()
	check(rig.position == weapon.weapon_visual.left_offset and rig.scale.x == -1, "Left facing explicitly mirrors attachment")
	player.get_node("PlayerSprite").flip_h = false; rig._update_facing()
	check(rig.position == weapon.weapon_visual.offset and rig.scale.x == 1, "Right facing restores attachment")
	for animation in ["weapon_idle", "weapon_draw", "weapon_holster", "weapon_attack_1", "weapon_attack_2", "weapon_attack_air", "weapon_block", "weapon_parry", "weapon_cast"]:
		rig.play_presentation(StringName(animation)); rig.animation_player.advance(0.08)
		check(rig.animation_player.current_animation == animation, "Editable placeholder plays " + animation)
	rig.play_presentation(&"weapon_holster"); rig.animation_player.advance(0.3); rig._process(0)
	check(not rig.visual.visible, "Holster remains hidden after the animation completes")
	rig.play_presentation(&"weapon_draw"); rig.animation_player.advance(0.3)
	check(rig.visual.visible, "Draw restores a holstered asset")
	check(SaveManager.save_active(), "Campaign save includes existing equipped weapon ID")
	check(await SaveManager.load_slot(3), "Campaign restores through production SaveManager")
	var loading_menu: Control = load("res://scenes/ui/menus/intro-menus/load-menu.tscn").instantiate(); add_child(loading_menu)
	loading_menu.selected_profile = 3; loading_menu.selected_kind = "manual"; loading_menu._activate()
	for i in 300:
		await get_tree().process_frame
		if not SaveManager.loading: break
	check(not SaveManager.loading and SaveManager.active_profile == 3 and not is_instance_valid(loading_menu.preset_panel), "Normal Load Game bypasses preset selection")
	loading_menu.free()
	player = Player_Manager.get_local_player() as Player
	rig = player.get_node("WeaponRig")
	check(rig.equipped == weapon and rig.visual.get_child_count() == 1, "Save/load restores weapon once through equipment synchronization")
	check(ControlBindings.preset_name(ControlBindings.snapshot()) == "Arrow Keys", "Campaign load preserves application casting preset")
	inventory_ui = load("res://scenes/ui/inventory/inventory-ui.tscn").instantiate(); add_child(inventory_ui)
	inventory_ui.unequip_button.pressed.emit(); inventory_ui.free()
	check(not rig.visible and rig.visual.get_child_count() == 0, "Unequip removes visual safely")
	player._enter_casting_stance(); player._on_died()
	check(not player.get_node("IncantationInputParticles").visible and not player.chain_assistant.visible, "Death clears local particles and path HUD")
