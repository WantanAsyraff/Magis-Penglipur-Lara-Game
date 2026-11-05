extends Node
## Drives production menus and the actual boss gameplay room. No campaign/profile writes.
const FOLDER := "res://docs/previews/combat-controls-v3/"
var layer: CanvasLayer
func _ready() -> void:
	if DisplayServer.get_name() == "headless": get_tree().quit(2); return
	get_tree().current_scene = null
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var room: BossPrototypeRoom = load("res://scenes/combat/boss-prototype-room.tscn").instantiate()
	add_child(room); await room.initialized
	room.menu.hide(); room.player.set_physics_process(false); room.boss.set_physics_process(false)
	room.get_node("StartTrigger").monitoring = false
	room.player.position = Vector2(760, 366); room.boss.position = Vector2(1600, 380)
	Player_Global_Data.learned_spells.assign(room.LOADOUT)
	Player_Global_Data.equipped_spells.assign(room.LOADOUT); Player_Global_Data.spells_updated.emit()
	Player_Global_Data.combat_mode = true; room.player.combat_mode = true
	Player_Global_Data.assistance_mode = 0; Player_Global_Data.assistance_changed.emit(0)
	room.player.hitbox.set_physics_process(false)
	layer = CanvasLayer.new(); layer.layer = 100; add_child(layer)
	for resolution in [Vector2i(1280,720), Vector2i(1920,1080)]:
		get_window().size = resolution; get_window().content_scale_size = resolution
		var tag := str(resolution.x)
		var settings: Control = load("res://scenes/ui/menus/settings-menu.tscn").instantiate(); layer.add_child(settings)
		settings._select_category("Spellcasting")
		await shot("01-settings-" + tag)
		settings.free()
		var panel := CastingPresetPanel.new(); layer.add_child(panel)
		panel.select("IJKL"); await shot("02-preset-ijkl-" + tag)
		panel.select("WASD"); await shot("03-preset-wasd-" + tag)
		panel.free()
		var focused := get_viewport().gui_get_focus_owner()
		if focused: focused.release_focus()
		var player := room.player
		player._clear_sequence(); player.casting.cancel(); player.casting.cooldowns.clear()
		Inventory_Manager.equipped[Inventory_Manager.SlotType.WEAPON] = null
		Inventory_Manager.equipment_changed.emit(Inventory_Manager.SlotType.WEAPON, null)
		player._exit_casting_stance()
		await shot("04-empty-weapon-rig-" + tag)
		player._enter_casting_stance()
		await shot("05-initial-aura-" + tag, 0.55)
		var aura := player.get_node("IncantationInputParticles")
		print("AURA ", aura.active, " strength=", aura.strength, " visible=", aura.visible, " in_tree=", aura.is_visible_in_tree(), " emitting=", aura.aura.emitting, " process=", aura.is_processing())
		player._add_sequence("down"); player._add_sequence("left")
		await shot("06-mid-combo-" + tag, 0.65)
		Player_Global_Data.p_curr_mana = 400
		player._add_sequence("down")
		await player.casting.delivery_succeeded
		await shot("07-cast-release-" + tag, 0.07)
		player._add_sequence("left")
		await shot("08-shared-prefix-paths-" + tag, 0.12)
		player._clear_sequence(); player.casting.cancel()
		# Remove only dispatched fixture deliveries before inspecting the attachment.
		for child in room.actors.get_children():
			if child is SpellEffect or child is SpellConstruct or child is SpellAreaDelivery or child is GPUParticles2D or child is SpellFeedback: child.queue_free()
		var weapon: ItemData = load("res://data/items/equipment/practice-magis-focus.tres")
		Inventory_Manager.add_item(weapon); Inventory_Manager.equip_item(weapon, Inventory_Manager.SlotType.WEAPON)
		var rig: WeaponVisualController = player.get_node("WeaponRig")
		player._exit_casting_stance(); await shot("09-equipped-weapon-" + tag, 0.4)
		print("WEAPON visible=", rig.visible, " children=", rig.visual.get_child_count())
		var inventory_ui: InventoryUI = load("res://scenes/ui/inventory/inventory-ui.tscn").instantiate()
		layer.add_child(inventory_ui); inventory_ui._select_item(weapon)
		await shot("15-inventory-weapon-" + tag)
		inventory_ui.free()
		rig.present_attack(); rig.animation_player.advance(0.18); rig.animation_player.pause(); rig.set_process(false)
		await shot("10-weapon-attack-" + tag, 0.08)
		rig.set_process(true); player._enter_casting_stance(); rig.play_presentation(&"weapon_cast"); rig.animation_player.advance(0.12); rig.animation_player.pause()
		await shot("11-weapon-cast-" + tag, 0.08)
		rig.set_process(true); rig.animation_player.play("weapon_idle")
		player._exit_casting_stance()
		var many: Array[SpellData] = []
		for i in 8:
			var spell: SpellData = room.LOADOUT[0].duplicate(true)
			spell.spell_name = "Path " + str(i); spell.spell_id = "preview-path-" + str(i)
			spell.spell_incantation.clear()
			for j in (32 if i == 0 else i + 2): spell.spell_incantation.append("up")
			spell.spell_incantation.append("left" if i % 2 == 0 else "right")
			many.append(spell)
		player.incantations.rebuild(many); player._enter_casting_stance()
		for i in 10: player.incantations.push("up")
		await shot("12-long-path-" + tag)
		Player_Global_Data.assistance_mode = 1; Player_Global_Data.assistance_changed.emit(1)
		await shot("13-minimal-" + tag)
		Player_Global_Data.assistance_mode = 2; Player_Global_Data.assistance_changed.emit(2)
		await shot("14-off-" + tag)
		Player_Global_Data.assistance_mode = 0; Player_Global_Data.assistance_changed.emit(0)
		player.incantations.rebuild(room.LOADOUT); player._exit_casting_stance()
	print("COMBAT_CONTROLS_V3_PREVIEW: 30 rendered captures")
	get_tree().quit()
func shot(title: String, delay: float = 0.2) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(FOLDER + title + ".png")
	if error != OK: push_error("Capture failed: " + error_string(error))
