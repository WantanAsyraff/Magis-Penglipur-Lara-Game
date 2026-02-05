class_name Pause extends Control

func _on_resume_button_pressed() -> void:
	# Get the camera node and call unpause
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("unpause"):
		camera.unpause()
	else:
		# Fallback if camera not found
		get_tree().paused = false
		visible = false

func _on_save_button_pressed() -> void:
	# TODO: Implement save system
	print("Save functionality not yet implemented")
	
	# Example implementation when you have a save system:
	# SaveManager.save_game()
	# 
	# Optional: Show a "Game Saved!" notification
	# var notification = load("res://ui/notification.tscn").instantiate()
	# add_child(notification)

func _on_settings_button_pressed() -> void:
	# TODO: Implement settings menu
	print("Settings menu not yet implemented")
	
	# Example implementation:
	# Option 1: Load settings as a popup
	# var settings_popup = load("res://ui/settings_popup.tscn").instantiate()
	# add_child(settings_popup)
	
	# Option 2: Switch to settings scene (keeps game paused)
	# SceneManager.change_scene("res://ui/settings_menu.tscn")

func _on_quit_button_pressed() -> void:
	# Unpause before changing scenes to avoid issues
	get_tree().paused = false
	
	# Option 1: Return to main menu (recommended)
	SceneManager.change_scene("res://scenes/main_menu.tscn")
	
	# Option 2: Quit to desktop
	# get_tree().quit()
	
	# Option 3: Ask for confirmation first
	# var confirm_dialog = ConfirmationDialog.new()
	# confirm_dialog.dialog_text = "Are you sure you want to quit?"
	# confirm_dialog.confirmed.connect(func(): 
	#     get_tree().paused = false
	#     SceneManager.change_scene("res://scenes/main_menu.tscn")
	# )
	# add_child(confirm_dialog)
	# confirm_dialog.popup_centered()
