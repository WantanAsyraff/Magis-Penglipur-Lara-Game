# DroppedItem.gd
class_name DroppedItem
extends CharacterBody2D

@export var friction: float = 0.95
@export var bounce: float = 0.5

var loot_data: LootData

@onready var sprite: Sprite2D = $Sprite2D
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D # For "shine" effects

func _ready() -> void:
	if loot_data:
		_setup_from_data()
	
	# Auto-initialize any specialized components added as children
	for child in get_children():
		if child.has_method("init_component"):
			child.init_component(self)

func _setup_from_data() -> void:
	if loot_data.item_icon:
		sprite.texture = loot_data.item_icon
	# You can add logic here to change particle colors based on rarity, etc.

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 2. Move and Handle Collisions
	# move_and_slide() uses the layers/masks to stop at walls/floors
	move_and_slide()
	
	# 3. Simple Bouncing Logic
	if is_on_floor():
		# Flip the Y velocity and dampen it
		velocity.y = -velocity.y * bounce
		# Dampen the X velocity (Friction)
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		
		# If it's barely moving, just stop it
		if abs(velocity.y) < 10:
			velocity.y = 0
