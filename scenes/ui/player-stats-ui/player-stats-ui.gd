class_name UserStatsUI
extends Control

@onready var stats_label: Label = %PlayerStatsLabel

func _ready() -> void:
	Player_Global_Data.health_changed.connect(_refresh.unbind(1))
	Player_Global_Data.mana_changed.connect(_refresh.unbind(1))
	Player_Global_Data.dash_charges_changed.connect(_refresh.unbind(1))
	Player_Global_Data.combat_mode_changed.connect(_refresh.unbind(1))
	Player_Global_Data.spells_updated.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var lines: Array[String] = []

	# Identity
	lines.append("── IDENTITY ──")
	lines.append("Name: %s" % Player_Global_Data.p_name)
	lines.append("Role: %s" % Player_Global_Data.p_role)
	lines.append("Mood: %s" % Player_Global_Data.p_mood)
	lines.append("Ringgit: RM %.2f" % Player_Global_Data.p_curr_ringgit)
	lines.append("")

	# Progression
	lines.append("── PROGRESSION ──")
	lines.append("Level: %d" % Player_Global_Data.player_level)
	lines.append("EXP: %.0f" % Player_Global_Data.player_exp)
	lines.append("Quests Completed: %d" % Player_Global_Data.completed_quests.size())
	lines.append("")

	# Combat Stats
	lines.append("── STATS ──")
	lines.append("HP: %d / %d" % [Player_Global_Data.p_curr_health, Player_Global_Data.p_max_health])
	lines.append("Mana: %.0f / %.0f" % [Player_Global_Data.p_curr_mana, Player_Global_Data.p_max_mana])
	lines.append("Dash Charges: %d / %d" % [Player_Global_Data.current_dash_charges, Player_Global_Data.MAX_DASH_CHARGES])
	lines.append("Speed: %.0f" % (Player_Global_Data.p_speed / 100))
	lines.append("")

	# Mode Flags
	lines.append("── STATUS ──")
	lines.append("Combat Mode: %s" % ("ON" if Player_Global_Data.combat_mode else "OFF"))
	lines.append("Casting: %s" % ("YES" if Player_Global_Data.is_casting else "NO"))
	lines.append("Invincible: %s" % ("YES" if Player_Global_Data.p_invincible else "NO"))
	lines.append("")

	# Academic
	if Player_Global_Data.current_field != "":
		lines.append("── ACADEMIC ──")
		lines.append("Field: %s" % Player_Global_Data.current_field)
		lines.append("Major: %s" % Player_Global_Data.current_major)
		lines.append("Minor: %s" % Player_Global_Data.current_minor)
		lines.append("")

	# Spells
	lines.append("── SPELLS ──")
	if Player_Global_Data.learned_spells.is_empty():
		lines.append("No spells learned.")
	else:
		for spell in Player_Global_Data.learned_spells:
			var equipped := " [E]" if Player_Global_Data.is_spell_equipped(spell) else ""
			lines.append("• %s%s" % [spell.spell_name, equipped])

	stats_label.text = "\n".join(lines)

func _on_back_button_pressed() -> void:
	print("Current scene, ", Player_Global_Data.current_scene)
	print("Previous scene, ", Player_Global_Data.previous_scene)
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	print("Position, ", Player_Global_Data.previous_position)
	print("Position, ", Player_Global_Data.previous_position)
	Player_Global_Data.p_moveable = true
