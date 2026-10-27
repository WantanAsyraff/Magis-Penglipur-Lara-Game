# dropped-item.gd
class_name DroppedItem
extends CharacterBody2D

@export var friction: float = 0.95
@export var bounce: float = 0.5

var loot_data: LootData
var pickup_id: String = ""
var loot_owner_id: String = ""
var _part: int = 0
var _collecting: bool = false
var quantity: int = 1  # set by whatever spawns this

@onready var sprite: Sprite2D = $Sprite2D
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if pickup_id.is_empty(): pickup_id = Crypto.new().generate_random_bytes(16).hex_encode()
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

func pickup(actor: Node2D = null) -> int:
	if _collecting or is_queued_for_deletion() or not SpellExecutor.is_authoritative(self) or quantity <= 0 or loot_data == null or loot_data.item == null: return 0
	var owner := GameplayEvent.owner_for(actor) if actor else QuestManager.active_owner_id
	if owner.is_empty() or owner != QuestManager.active_owner_id or (not loot_owner_id.is_empty() and loot_owner_id != owner): return 0
	_collecting = true
	var acquired := Inventory_Manager.pickup(loot_data.item, quantity, "pickup:" + pickup_id + ":" + str(_part), owner)
	if acquired > 0:
		quantity -= acquired
		_part += 1
		if quantity == 0: queue_free()
	_collecting = false
	return acquired
