class_name DuelGroundsSelection extends HBoxContainer

@export var duel_scene : PackedScene

func _on_enter_button_pressed() -> void:
	Player_Global_Data.combat_mode = true
	SceneManager.change_scene(duel_scene)
