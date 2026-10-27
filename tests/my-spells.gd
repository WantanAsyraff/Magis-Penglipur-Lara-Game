extends Node
const Description = preload("res://scenes/ui/spell-equipment/spell-description.gd")
var checks := 0
var failures := 0
var completed := false
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures += 1
	print(("PASS " if condition else "FAIL ") + message)
func spell(file: String) -> SpellData:
	return load("res://data/magis/spells/" + file + ".tres")
func _ready() -> void:
	await get_tree().process_frame
	await run()
	check(completed, "Suite completed")
	print("MY_SPELLS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func run() -> void:
	var saved_spells: Array[SpellData] = Player_Global_Data.learned_spells.duplicate()
	var saved_selection: SpellData = Player_Global_Data.selected_spell
	Player_Global_Data.learned_spells.clear()
	Player_Global_Data.selected_spell = null
	var menu: SpellArchivesMenu = load("res://scenes/ui/spell-equipment/spell-archives-menu.tscn").instantiate()
	add_child(menu)
	check(menu.get_node("%SpellNameLabel").text == "No learned spells", "Empty collection has a clear state")
	for resource in Spell_Library.all_spells.values():
		Player_Global_Data.add_spell(resource)
	await get_tree().process_frame
	await get_tree().process_frame
	var cards := menu.get_node("%LearnedSpells")
	check(cards.get_child_count() == 42, "List updates to all 42 learned spells")
	check(menu.get_node("%SpellNameLabel").text == Player_Global_Data.learned_spells[0].spell_name, "First learned spell selected on opening without selection")
	for card in cards.get_children():
		check(card.get_node("%SpellNameLabel").text == card.spell_data.spell_name, "Named card: " + card.spell_data.spell_name)
		card.spell_selected.emit(card.spell_data)
		check(menu.get_node("%SpellNameLabel").text == card.spell_data.spell_name and menu.get_node("%SpellTheoryLabel").text == card.spell_data.theory_desc, "Selection updates name and theory: " + card.spell_data.spell_name)
		check(not menu.get_node("%CastersNotesLabel").text.is_empty(), "Stats available: " + card.spell_data.spell_name)
	var bloom := spell("phys-thermal-bloom")
	var stats := Description.stats(bloom)
	check(stats.contains("Damage: 5") and stats.contains("Damage: 12") and stats.contains("If target has Cooled"), "Thermal base damage and conditional damage stay separate")
	check(stats.contains("Lifetime: 5 s") and stats.contains("Effects: (each tick)") and not stats.contains("Projectile Speed:"), "Area details omit unused projectile defaults")
	var modified := bloom.duplicate() as SpellData
	modified.projectile_damage = 999
	modified.knockback_force = 999
	check(not Description.stats(modified).contains("999"), "Explicit payload overrides stale legacy damage and knockback")
	var force := spell("phys-force")
	check(Description.stats(force).contains("Damage: 17") and Description.stats(force).contains("Knockback: 320"), "Legacy adapter remains the source for original Force")
	var heat := Description.stats(spell("phys-heat-engine"))
	check(heat.contains("Mana Regen: +4") and heat.contains("Cast Speed: +25%") and not heat.contains("Projectile Range:"), "Buff magnitudes displayed in appropriate units")
	check(Description.stats(spell("phys-harmonic-stabilization")).contains("Healing: 22 HP"), "Support spell shows healing")
	var jet := Description.stats(spell("phys-pressure-jet"))
	check(jet.contains("Channel: 2 s at 5 MP/s") and jet.contains("During channel") and jet.contains("Beam Width:"), "Channel cost, timing and beam dimensions displayed")
	check(Description.stats(spell("phys-resonance-threshold")).contains("After 3 damaging hit(s)"), "Triggered effects show hit threshold")
	check(Description.stats(spell("phys-static-arc")).contains("up to 3 additional targets"), "Chains show bounded targets")
	check(Description.stats(spell("phys-probabilistic-echo")).contains("50% damage / healing"), "Replay description displayed")
	check(Description.stats(spell("phys-tunneling-step")).contains("Displacement: 160 px"), "Teleport distance displayed")
	check(Description.stats(spell("phys-structural-fabrication")).contains("solid platform / surface"), "Construct behavior displayed")
	check(Description.stats(spell("phys-vector-reversal")).contains("Reverses hostile projectiles"), "Projectile control displayed")
	check(Description.casting(spell("phys-momentum-anchor")).contains("Delivery: Direct Target"), "Delivery label comes from effective targeting")
	# Bounded formatting must not recurse forever on a malformed resource.
	var cyclic := ConditionalEffect.new()
	cyclic.children.append(cyclic)
	modified.effects = [cyclic]
	check(Description.stats(modified).contains("Circular effect reference"), "Circular effects are safe to display")
	cyclic.children.clear()
	# Removing the selected spell cannot leave its information on screen.
	menu._on_spell_selected(force)
	Player_Global_Data.remove_spell(force)
	check(Player_Global_Data.selected_spell != force and menu.get_node("%SpellNameLabel").text != force.spell_name, "Removed selection replaced by a learned spell")
	await get_tree().process_frame
	await get_tree().process_frame
	menu.size = Vector2(800, 600)
	await get_tree().process_frame
	await get_tree().process_frame
	var details := menu.get_node("Margin/Layout/Columns/DetailScroll") as ScrollContainer
	var content := details.get_child(0) as Control
	check(content.size.x <= details.size.x and details.size.x > 0, "Details fit the available width at 800 pixels")
	check(content.size.y > details.size.y and details.get_v_scroll_bar().max_value > details.size.y, "Long spell information remains vertically scrollable")
	menu.queue_free()
	await get_tree().process_frame
	Player_Global_Data.learned_spells = saved_spells
	Player_Global_Data.selected_spell = saved_selection
	completed = true
