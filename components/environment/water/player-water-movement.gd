class_name PlayerWaterMovement extends Node
var volumes: Array[WaterVolume2D] = []
func step(delta: float) -> bool:
	var player := get_parent() as Player
	if player == null or not Player_Global_Data.p_moveable or player.is_dashing: return false
	for water in volumes.duplicate():
		if not is_instance_valid(water): volumes.erase(water); continue
		if not water.player_swimming or not water.contains_body(player) or player.global_position.y < water.surface_y()-20: continue
		var direction := Input.get_vector("move_left","move_right","climb_up","climb_down")
		var desired: Vector2 = direction*water.swim_speed+water.current
		if direction.y == 0: desired.y = clampf((water.surface_y()+25-player.global_position.y)*3,-160,160)
		player.velocity = player.velocity.move_toward(desired,water.swim_speed*5*delta)
		if Input.is_action_just_pressed("jump"): player.velocity.y = -water.swim_speed*1.8
		player.move_and_slide()
		return true
	return false
