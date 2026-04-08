class_name SpellArchivesMenu
extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")

func _ready() -> void:
	_populate_spell_list()
	var spell := Player_Global_Data.selected_spell
	if spell:
		_populate(spell)

func _populate_spell_list() -> void:
	for child in %LearnedSpells.get_children():
		child.queue_free()
	await get_tree().process_frame
	for spell in Player_Global_Data.learned_spells:
		var slot = SPELL_SLOT.instantiate()
		%LearnedSpells.add_child(slot)
		slot.set_spell(spell, Player_Global_Data.is_spell_equipped(spell))
		slot.spell_selected.connect(_on_spell_selected)

func _on_spell_selected(spell: SpellData) -> void:
	Player_Global_Data.selected_spell = spell
	_populate(spell)

func _populate(spell: SpellData) -> void:
	%TextureRect.texture = spell.spell_icon
	%SpellNameLabel.text = spell.spell_name
	%SpellFlavourLabel.text = spell.spell_flavour_text
	%SpellMoveLabel.text = _build_move_desc(spell)
	%SpellTheoryLabel.text = spell.theory_desc
	%CastersNotesLabel.text = _build_stats(spell)

func _build_move_desc(spell: SpellData) -> String:
	var lines: Array[String] = []
	lines.append("Type: %s" % SpellData.SpellType.keys()[spell.spell_type])
	lines.append("Manifest: %s" % SpellData.SpellManifest.keys()[spell.spell_manifest])
	lines.append("Archetype: %s" % spell.magis_archetype)
	lines.append("Comprehension: %s" % spell.magis_comprehension)
	if not spell.spell_incantation.is_empty():
		lines.append("Incantation: %s" % " → ".join(spell.spell_incantation))
	return "\n".join(lines)

func _build_stats(spell: SpellData) -> String:
	var lines: Array[String] = []
	if spell.upfront_cost > 0:       lines.append("Mana Cost: %d" % spell.upfront_cost)
	if spell.mana_per_second > 0:    lines.append("Mana/s: %.1f" % spell.mana_per_second)
	if spell.cast_time > 0:          lines.append("Cast Time: %.2fs" % spell.cast_time)
	if spell.is_channelled:          lines.append("Channelled: %.1fs" % spell.channel_duration)
	if spell.projectile_damage > 0:  lines.append("Damage: %.0f" % spell.projectile_damage)
	if spell.projectile_speed > 0:   lines.append("Speed: %.0f" % spell.projectile_speed)
	if spell.projectile_range > 0:   lines.append("Range: %.0f" % spell.projectile_range)
	if spell.projectile_count > 1:   lines.append("Projectiles: %d" % spell.projectile_count)
	if spell.aoe_spell_radius > 0:   lines.append("AoE Radius: %.0f" % spell.aoe_spell_radius)
	if spell.knockback_force > 0:    lines.append("Knockback: %.0f" % spell.knockback_force)
	if spell.stunnable:              lines.append("Stun: %.1fs" % spell.stun_dur)
	if spell.dot:                    lines.append("DoT: %.0f dmg / %.1fs (%.1fs)" % [spell.dot_damage, spell.dot_interval, spell.dot_duration])
	if spell.applies_slow:           lines.append("Slow: %.0f%% for %.1fs" % [spell.slow_factor * 100, spell.slow_duration])
	if spell.applies_silence:        lines.append("Silence: %.1fs" % spell.silence_duration)
	if spell.applies_mana_drain:     lines.append("Mana Drain: %.0f over %.1fs" % [spell.mana_drain_amount, spell.mana_drain_duration])
	return "\n".join(lines)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/spell-equipment/spellku-main-menu.tscn")
