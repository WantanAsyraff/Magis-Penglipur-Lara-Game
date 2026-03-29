class_name PlayerAnim
extends Node

@onready var playerAnim: AnimatedSprite2D = %PlayerSprite
@onready var _player: Player = get_parent() as Player

func _process(_delta: float) -> void:
	_update_flip()
	_update_animations()

func _update_flip() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir < 0:
		playerAnim.flip_h = true
	elif dir > 0:
		playerAnim.flip_h = false

func _update_animations() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var is_moving := absf(dir) > 0.1
	var is_airborne := not _player.is_on_floor()

	# 1. Casting
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
	# 2. Blocking
	elif Input.is_action_pressed("block"):
		playerAnim.play("block")
	# 3. Dash
	elif Player_Global_Data.is_dashing:
		playerAnim.play("dash")
	# 4. Falling
	elif is_airborne:
		playerAnim.play("falling")
	# 5. Walk
	elif is_moving:
		playerAnim.play("walk")
	# 6. Idle
	else:
		playerAnim.play("idle")
