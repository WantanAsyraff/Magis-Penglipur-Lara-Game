class_name PlayerAnim extends Node

func _process(_delta: float) -> void:
	_update_temp_anim()

func _update_temp_anim() -> void:
	# dir.x will be -1 for left, 1 for right, and 0 for no horizontal input
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if dir.x < 0:
		%"PlayerSprite(Temp)".flip_h = true  # Moving Left
	elif dir.x > 0:
		%"PlayerSprite(Temp)".flip_h = false # Moving Right
