# main-menu.gd
extends Control

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/load-menu.tscn")

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/new-game-menu.tscn")

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/settings-menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
