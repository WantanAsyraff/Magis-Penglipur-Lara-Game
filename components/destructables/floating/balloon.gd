extends RigidBody2D
@export var max_health := 10
@export var bob_speed := 2.0
@export var bob_height := 5.0
@export var respawnable := false
@export var respawn_cooldown := 5.0
var health: int
var base_y: float
var original_position: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	health = max_health
	particles.emitting = false
	particles.one_shot = true
	gravity_scale = 0
	base_y = position.y
	original_position = position

func _process(delta: float) -> void:
	position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		break_object()

func break_object() -> void:
	collision.disabled = true
	sprite.visible = false
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime).timeout
	if respawnable:
		await get_tree().create_timer(respawn_cooldown).timeout
		respawn()
	else:
		queue_free()

func respawn() -> void:
	health = max_health
	position = original_position
	base_y = original_position.y
	collision.disabled = false
	sprite.visible = true
	particles.emitting = false
