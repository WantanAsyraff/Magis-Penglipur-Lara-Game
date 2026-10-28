class_name EnemyMovementComponent extends Node
var intent: EnemyAIAction.Kind = EnemyAIAction.Kind.IDLE
func tick(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	var push := enemy.get_node_or_null("PlayerPushImpulse") as SpellMotionImpulse
	if push == null: push = enemy.get_node_or_null("SpellMotionImpulse") as SpellMotionImpulse
	if push and not push.is_queued_for_deletion() and push.remaining > 0:
		# A shove owns horizontal motion briefly; chase intent must not cancel it.
		enemy.velocity.x = 0
		return
	if enemy.hitbox.is_stunned() or enemy.current_state == Enemy.State.HURT:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.chase_speed * delta * 4)
		return
	var bb: Dictionary = enemy.detection.blackboard
	var profile: EnemyAIProfile = enemy.ai.profile
	var direction := 0.0
	var speed := maxf(0, enemy.chase_speed + enemy.hitbox.effects.magnitude("buff_speed"))
	if enemy.combat.busy(): enemy.velocity.x = move_toward(enemy.velocity.x, 0, speed * delta * 4); return
	match intent:
		EnemyAIAction.Kind.PATROL:
			var patrol_velocity: float = enemy.patrol.patrol_tick(enemy, enemy._facing_right)
			enemy.velocity.x = signf(patrol_velocity) * maxf(0, absf(patrol_velocity) + enemy.hitbox.effects.magnitude("buff_speed")) * (1 - enemy.hitbox.get_slow_factor())
			enemy._update_facing(enemy.velocity.x)
			return
		EnemyAIAction.Kind.INVESTIGATE, EnemyAIAction.Kind.REPOSITION:
			direction = signf(enemy.detection.last_known_position.x - enemy.global_position.x)
			if absf(enemy.detection.last_known_position.x - enemy.global_position.x) < 16: direction = 0
			if intent == EnemyAIAction.Kind.REPOSITION and enemy.is_on_wall() and enemy.is_on_floor(): enemy.velocity.y = profile.wall_jump_velocity
		EnemyAIAction.Kind.CHASE:
			if enemy.detection.has_line_of_sight(): direction = signf(enemy.detection.player.global_position.x - enemy.global_position.x)
		EnemyAIAction.Kind.RETREAT, EnemyAIAction.Kind.FLEE:
			if is_instance_valid(enemy.detection.player): direction = -signf(enemy.detection.player.global_position.x - enemy.global_position.x)
		EnemyAIAction.Kind.MAINTAIN_RANGE:
			if is_instance_valid(enemy.detection.player):
				var distance: float = bb.get("distance", INF)
				if absf(distance - enemy.ai.preferred_distance()) > profile.range_tolerance: direction = signf(enemy.detection.player.global_position.x - enemy.global_position.x) * (1 if distance > enemy.ai.preferred_distance() else -1)
	# Avoid walking off a ledge while chasing or retreating; patrol owns its own check.
	if direction != 0 and enemy.is_on_floor() and not enemy.patrol._ground_check(direction > 0): direction = 0
	enemy.velocity.x = direction * speed * (1 - enemy.hitbox.get_slow_factor())
	enemy._update_facing(direction)
