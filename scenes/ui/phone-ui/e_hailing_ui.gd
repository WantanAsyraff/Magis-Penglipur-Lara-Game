extends Control

signal back_pressed # This is the "shout" the app will make

func _on_back_button_pressed():
	# Connect this to the 'pressed' signal of the actual button in your App scene
	back_pressed.emit()
