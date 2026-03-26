# EnemyLootComponent.gd
extends Node2D
class_name EnemyLootComponent

@export_group("Loot Table")
## Drag and drop LootData resources here
@export var loot_table: Array[LootData] = []

## Should the loot pop out in random directions?
@export var apply_spread: bool = true
@export var spread_force: float = 300.0 # Increased slightly for better "pop"

func _ready() -> void:
	var parent = get_parent()
	if parent.has_signal("enemy_died"):
		parent.enemy_died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	# FIX: Use call_deferred to wait until physics are finished processing.
	# This prevents the "Flushing Queries" error.
	_process_all_loot.call_deferred()

func _process_all_loot() -> void:
	for loot in loot_table:
		_process_loot_entry(loot)

func _process_loot_entry(loot: LootData) -> void:
	# Roll the dice
	if randf() > loot.drop_chance:
		return

	# Determine quantity
	var quantity = randi_range(loot.min_quantity, loot.max_quantity)
	
	for i in range(quantity):
		_spawn_item(loot)

func _spawn_item(loot: LootData) -> void:
	if not loot.item_scene:
		push_warning("LootComponent: %s has no item_scene assigned!" % loot.item_name)
		return

	var item_instance = loot.item_scene.instantiate()
	
	# 1. INJECT DATA: Tell the item what it is before adding to tree
	if "loot_data" in item_instance:
		item_instance.loot_data = loot
	
	# 2. ADD TO WORLD: Use current_scene so it persists after enemy dies
	get_tree().current_scene.add_child(item_instance)
	item_instance.global_position = global_position
	
	# 3. APPLY PHYSICS: The "Pop" effect
	if apply_spread:
		var random_direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()
		var impulse = random_direction * spread_force
		
		if item_instance is RigidBody2D:
			item_instance.apply_central_impulse(impulse)
		elif item_instance is CharacterBody2D:
			# Since we are using Godot's built-in velocity, we set it here
			item_instance.velocity = impulse
