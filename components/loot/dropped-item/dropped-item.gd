# dropped-item.gd
class_name DroppedItem
extends CharacterBody2D

@export var friction: float = 0.95
@export var bounce: float = 0.5

var loot_data: LootData
var quantity: int = 1  # set by whatever spawns this

@onready var sprite: Sprite2D = $Sprite2D
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if loot_data:
		_setup_from_data()
	for child in get_children():
		if child.has_method("init_component"):
			child.init_component(self)

func _setup_from_data() -> void:
	if not loot_data.item:
		push_error("DroppedItem: loot_data has no ItemData assigned — " + name)
		return
	if loot_data.item.item_icon:
		sprite.texture = loot_data.item.item_icon
	# Rarity particle color
	if gpu_particles:
		gpu_particles.modulate = loot_data.rarity_color

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = -velocity.y * bounce
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		if abs(velocity.y) < 10:
			velocity.y = 0

func pickup() -> void:
	if not loot_data or not loot_data.item:
		push_error("DroppedItem: cannot pick up, missing loot_data or item.")
		return
	Inventory_Manager.pickup(loot_data.item, quantity)
	queue_free()
