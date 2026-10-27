extends Node
var checks := 0
var failures := 0
var completed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func settle() -> void:
	for i in 6: await get_tree().process_frame
func _ready() -> void:
	await get_tree().process_frame
	await run()
	check(completed, "Equipment suite completed")
	print("SPELL_EQUIPMENT_UI: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func run() -> void:
	var saved_learned: Array[SpellData] = Player_Global_Data.learned_spells.duplicate()
	var saved_equipped: Array[SpellData] = Player_Global_Data.equipped_spells.duplicate()
	var saved_selected: SpellData = Player_Global_Data.selected_spell
	Player_Global_Data.learned_spells.assign(Spell_Library.all_spells.values())
	Player_Global_Data.equipped_spells.clear()
	for file in ["phys-structural-fabrication", "phys-resonance-threshold", "thermal-kinetic", "phys-thermal-bloom", "phys-entropy-leak", "phys-heat-engine", "phys-resonate", "phys-shatterwave"]:
		Player_Global_Data.equipped_spells.append(load("res://data/magis/spells/" + file + ".tres"))
	var menu: Control = load("res://scenes/ui/spell-equipment/spell-equipment.tscn").instantiate()
	add_child(menu)
	for dimensions in [Vector2(640, 600), Vector2(800, 600), Vector2(1280, 720), Vector2(1662, 1080)]:
		menu.size = dimensions
		await settle()
		var label := "%dx%d" % [dimensions.x, dimensions.y]
		var library := menu.get_node("%LearnedSpells") as VBoxContainer
		var grid := menu.get_node("%SpellEquipmentContainer") as GridContainer
		check(library.get_child_count() == 34 and grid.get_child_count() == 8, label + " complete learned and equipped lists")
		check(menu.get_node("%EquippedCountLabel").text == "8 / 8 slots used", label + " loadout counter")
		check(grid.columns == (1 if dimensions.x <= 640 else 2), label + " responsive equipped columns")
		var all_cards: Array[Node] = library.get_children() + grid.get_children()
		var cards_fit := true
		var icons_fit := true
		var content_fits := true
		for card in all_cards:
			var parent := card.get_parent() as Control
			cards_fit = cards_fit and card.position.x >= 0 and card.position.x + card.size.x <= parent.size.x + 1
			var arrows := card.get_node("%SpellMoveHBoxContainer") as HBoxContainer
			var name_label := card.get_node("%SpellNameLabel") as Label
			var mana := card.get_node("%SpellCostLabel") as Label
			content_fits = content_fits and arrows.position.y >= name_label.position.y + name_label.size.y and mana.position.y >= arrows.position.y + arrows.size.y
			content_fits = content_fits and mana.get_global_rect().end.y <= card.get_global_rect().end.y
			for icon in arrows.get_children():
				icons_fit = icons_fit and icon.size == Vector2(24, 24) and icon.expand_mode == TextureRect.EXPAND_IGNORE_SIZE
				icons_fit = icons_fit and icon.get_global_rect().end.x <= card.get_global_rect().end.x
		check(cards_fit, label + " cards fit their columns")
		check(icons_fit, label + " icons remain 24 pixels and fit inside cards")
		check(content_fits, label + " names, arrows and mana never overlap")
		var distinct := true
		for i in range(1, library.get_child_count()):
			var before := library.get_child(i - 1) as Control
			var after := library.get_child(i) as Control
			distinct = distinct and after.position.y >= before.position.y + before.size.y + 12
		for i in range(grid.columns, grid.get_child_count()):
			distinct = distinct and grid.get_child(i).position.y >= grid.get_child(i - grid.columns).position.y + grid.get_child(i - grid.columns).size.y + 12
		check(distinct, label + " cards separated without overlap")
		check(menu.get_node("%LibraryScroll").get_v_scroll_bar().max_value > menu.get_node("%LibraryScroll").size.y, label + " library remains scrollable")
	if "--capture-equipment" in OS.get_cmdline_user_args():
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		get_tree().root.content_scale_size = Vector2i.ZERO
		get_tree().root.size = Vector2i(1662, 1080)
		menu.size = Vector2(1662, 1080)
		await settle()
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png("/tmp/magis-spell-equipment.png")
		check(result == OK, "Rendered equipment preview captured")
	var library := menu.get_node("%LearnedSpells") as VBoxContainer
	var extra: SpellData = library.get_child(0).spell_data
	menu._on_learned_spell_selected(extra)
	await settle()
	check(Player_Global_Data.equipped_spells.size() == 8 and menu.get_node("%FeedbackLabel").text.contains("full"), "Full loadout shows inline feedback and enforces limit")
	var first: SpellData = Player_Global_Data.equipped_spells[0]
	menu._on_equipped_spell_selected(first)
	await settle()
	check(menu.get_node("%SpellEquipmentContainer").get_child_count() == 7 and library.get_child_count() == 35, "Unequip moves one card back to library")
	menu._on_learned_spell_selected(extra)
	await settle()
	check(menu.get_node("%SpellEquipmentContainer").get_child_count() == 8 and library.get_child_count() == 34, "Equip fills the free slot without duplicate cards")
	Player_Global_Data.spells_updated.emit()
	Player_Global_Data.spells_updated.emit()
	Player_Global_Data.spells_updated.emit()
	await settle()
	check(library.get_child_count() == 34, "Burst updates coalesce without duplicate cards")
	Player_Global_Data.learned_spells.clear()
	Player_Global_Data.equipped_spells.clear()
	Player_Global_Data.spells_updated.emit()
	await settle()
	check(menu.get_node("%LearnedEmptyLabel").visible and menu.get_node("%EquippedEmptyLabel").visible, "Empty states explain how to populate both lists")
	menu.queue_free()
	await get_tree().process_frame
	Player_Global_Data.learned_spells = saved_learned
	Player_Global_Data.equipped_spells = saved_equipped
	Player_Global_Data.selected_spell = saved_selected
	completed = true
