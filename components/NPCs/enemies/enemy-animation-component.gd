extends Node
class_name EnemyAnimationComponent

@export_group("Settings")
@export var sprite: AnimatedSprite2D
## The Area2D used to detect the player
@export var attack_area: Area2D 

var player_in_range: bool = false

func _ready() -> void:
	# 1. Setup Sprite
	if not sprite:
		sprite = get_parent().find_child("AnimatedSprite2D") as AnimatedSprite2D
	
	# 2. Setup Attack Area
	if not attack_area:
		# Looks for a node named AttackArea specifically (via % unique name or child)
		attack_area = get_parent().find_child("AttackArea") as Area2D

	# 3. Connect Signals
	if attack_area:
		attack_area.body_entered.connect(_on_body_entered)
		attack_area.body_exited.connect(_on_body_exited)
	else:
		push_warning("[EnemyAnimationComponent] No AttackArea found!")

	play_idle()

# -------------------------
# DETECTION LOGIC
# -------------------------

func _on_body_entered(body: Node2D) -> void:
	# Check if the body entering is in the "player" group
	if body.is_in_group("player"):
		player_in_range = true
		print("[Enemy] Player entered range. Starting attack!")
		play_attack()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("[Enemy] Player left range.")
		# Optionally return to idle if not moving
		play_idle()

# -------------------------
# ANIMATION METHODS
# -------------------------

func play_idle() -> void:
	if _has_animation("idle"):
		sprite.play("idle")

func play_attack() -> void:
	if _has_animation("attack"):
		sprite.play("attack")

func _has_animation(anim_name: String) -> bool:
	if not sprite or not sprite.sprite_frames:
		return false
	return sprite.sprite_frames.has_animation(anim_name)
