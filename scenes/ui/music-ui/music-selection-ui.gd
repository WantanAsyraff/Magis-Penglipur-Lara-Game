extends Control


func _on_back_button_pressed() -> void:
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	Player_Global_Data.p_moveable = true
