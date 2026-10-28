class_name Pause
extends Control

const SETTINGS_SCENE := "res://scenes/ui/menus/settings-menu.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/menus/intro-menus/main-menu.tscn"

func _ready() -> void:
	visibility_changed.connect(_update_save_availability)

func _update_save_availability() -> void:
	if not is_visible_in_tree(): return
	var reason := SaveManager.unavailable_reason()
	var button: Button = $MenulPanelContainer/VBoxContainer/SaveButton
	button.disabled = not reason.is_empty()
	button.tooltip_text = reason

func _on_resume_button_pressed() -> void:
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("unpause"):
		camera.unpause()
	else:
		get_tree().paused = false
		visible = false

func _on_save_button_pressed() -> void:
	var reason := SaveManager.unavailable_reason()
	if not reason.is_empty():
		_save_result(false, reason)
		return
	if SaveManager.inspect_slot(SaveManager.active_profile).state != "empty":
		var confirm := ConfirmationDialog.new()
		confirm.title = "Overwrite manual save?"
		confirm.dialog_text = "Replace the manual save for profile %d? The previous valid save is retained as a backup." % SaveManager.active_profile
		add_child(confirm)
		confirm.confirmed.connect(func(): _save_now(); confirm.queue_free())
		confirm.canceled.connect(confirm.queue_free)
		confirm.popup_centered()
	else: _save_now()

func _save_now() -> void:
	var success := SaveManager.save_active()
	_save_result(success, SaveManager.last_error)

func _save_result(success: bool, reason: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Save game"
	dialog.dialog_text = "Game saved." if success else "Save failed: " + reason
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

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
