class_name PlayerAnim
extends Node

@onready var playerAnim: AnimatedSprite2D = %PlayerSprite

func _process(_delta: float) -> void:
	_update_flip()
	_update_animations()

func _update_flip() -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.x < 0:
		playerAnim.flip_h = true
	elif dir.x > 0:
		playerAnim.flip_h = false

func _update_animations() -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_moving := dir.length() > 0.1

	# Casting (highest priority)
	if Player_Global_Data.combat_mode and Player_Global_Data.is_casting:
		if Input.is_action_pressed("incantation_up"):
			playerAnim.play("casting_up")
		elif Input.is_action_pressed("incantation_down"):
			playerAnim.play("casting_down")
		elif Input.is_action_pressed("incantation_left"):
			playerAnim.play("casting_left")
		elif Input.is_action_pressed("incantation_right"):
			playerAnim.play("casting_right")
		else:
			playerAnim.play("idle")

	# Dash
	elif Player_Global_Data.is_dashing:
		playerAnim.play("dash")

	# Walk
	elif is_moving:
		playerAnim.play("walk")

	# Idle
	else:
		playerAnim.play("idle")
