extends RigidBody2D

@export var max_health := 10
var health: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	health = max_health
	particles.emitting = false
	particles.one_shot = true

# This is what your MagicProjectile calls
func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		break_object()

func break_object() -> void:
	# stop interacting with the world
	collision.disabled = true
	sprite.visible = false

	# play break effect
	particles.emitting = true

	# wait for particles, then remove object
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
