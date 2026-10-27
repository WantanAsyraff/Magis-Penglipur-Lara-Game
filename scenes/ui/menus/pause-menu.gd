class_name Pause
extends Control

const SETTINGS_SCENE := "res://scenes/ui/menus/settings-menu.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/menus/intro-menus/main-menu.tscn"

func _on_resume_button_pressed() -> void:
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("unpause"):
		camera.unpause()
	else:
		get_tree().paused = false
		visible = false

func _on_save_button_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Save progress"
	dialog.dialog_text = "Quest, inventory and reward progress saved." if QuestManager.save_game() else "Could not save progress. Check available storage and try again."
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _on_settings_button_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene(SETTINGS_SCENE)

func _on_quit_button_pressed() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Quit to Main Menu"
	dialog.dialog_text = "Any unsaved progress will be lost. Quit anyway?"
	dialog.get_ok_button().text = "Quit"
	dialog.get_cancel_button().text = "Cancel"
	dialog.confirmed.connect(func():
		get_tree().paused = false
		SceneManager.change_scene(MAIN_MENU_SCENE)
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()
