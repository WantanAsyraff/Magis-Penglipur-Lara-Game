class_name EnemyAnimationComponent extends Node
@export var sprite: AnimatedSprite2D
@export var attack_area: Area2D
var player_in_range: bool = false
func bind_enemy(enemy: Enemy) -> void:
	if sprite == null: sprite = enemy.sprite
	if not enemy.state_changed.is_connected(_state_changed): enemy.state_changed.connect(_state_changed)
	_state_changed(enemy.current_state)
func _state_changed(state: Enemy.State) -> void:
	var animation := "idle"
	match state:
		Enemy.State.PATROL, Enemy.State.CHASE, Enemy.State.RETURN: animation = "walk"
		Enemy.State.ATTACK: animation = "attack"
		Enemy.State.HURT: animation = "hurt"
		Enemy.State.DEATH: animation = "death"
	if _has_animation(animation): sprite.play(animation)
	elif _has_animation("idle"): sprite.play("idle")
func play_idle() -> void:
	if _has_animation("idle"): sprite.play("idle")
func play_attack() -> void:
	if _has_animation("attack"): sprite.play("attack")
func _has_animation(value: String) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(value)
