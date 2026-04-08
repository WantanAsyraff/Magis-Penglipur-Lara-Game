class_name SpellKuMainMenu extends Control


func _on_equip_spell_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/spell-equipment/spell-equipment.tscn")


func _on_spell_archive_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/spell-equipment/spell-archives-menu.tscn")

func _on_back_button_pressed() -> void:
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	Player_Global_Data.p_moveable = true
