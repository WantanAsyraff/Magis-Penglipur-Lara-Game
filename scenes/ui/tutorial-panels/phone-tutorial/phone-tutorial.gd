extends Panel

signal closed

func _on_close_button_pressed() -> void:
	closed.emit()
	hide()
