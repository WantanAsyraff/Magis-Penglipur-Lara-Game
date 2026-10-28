class_name PlayerPushback extends Node
## Contextual E ability. Cooldown is transient gameplay state, never a dispellable status.
@export var cooldown: float = 4.0
@export var radius: float = 400.0
@export var force: float = 2200.0
var remaining: float = 0.0

func _physics_process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)

func try_push(prioritize_interaction: bool = true) -> bool:
	var player := get_parent() as Player
	if player == null or not SpellExecutor.is_authoritative(player) or remaining > 0: return false
	if not player.combat_mode or player.get_meta("combat_dead", false) or not Player_Global_Data.is_alive(): return false
	if get_tree().paused or player.hitbox.is_stunned(): return false
	if not Player_Global_Data.p_moveable and not player._stop_moving_locked: return false
	if Dialogic.current_timeline != null or QuestOfferDialog.is_open(): return false
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return false
	if prioritize_interaction:
		if DetectionComponent.focused(get_tree()) != null: return false
		for interaction in get_tree().get_nodes_in_group("world_interaction"):
			if interaction.blocks_combat_push(player): return false
	SpellFeedback.flash(player, Color(0.55, 0.9, 1.0), radius)
	var pushed := false
	for target in get_tree().get_nodes_in_group("combat_target"):
		if not target is CharacterBody2D or target.get_meta("spell_team", &"") != &"enemy": continue
		if target.is_queued_for_deletion() or target.get_meta("combat_dead", false): continue
		if not SpellExecutor.is_authoritative(target) or SpellDelivery.target_distance(player.global_position, target) > radius: continue
		var hitbox := target.get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox == null or not hitbox.receives_knockback or hitbox.is_invincible() or hitbox.knockback_resistance >= 1: continue
		var ray := PhysicsRayQueryParameters2D.create(player.global_position, target.global_position, 16, [player.get_rid(), target.get_rid()])
		if not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var direction: Vector2 = player.global_position.direction_to(target.global_position)
		if direction.is_zero_approx(): direction = player.castMarker.position.normalized()
		if direction.is_zero_approx(): direction = Vector2.RIGHT
		var motion := SpellMotionImpulse.new()
		motion.name = "PlayerPushImpulse"
		motion.remaining = 0.4
		motion.impulse = direction * force * (1.0 - hitbox.knockback_resistance)
		target.add_child(motion)
		hitbox.knocked_back.emit(motion.impulse)
		SpellFeedback.flash(target, Color(0.55, 0.9, 1.0))
		pushed = true
	if pushed:
		remaining = cooldown
	else:
		player._spawn_indicator("No pushable enemy in reach", "#8edcff")
	return pushed
