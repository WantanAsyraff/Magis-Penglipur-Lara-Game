# EnemyLootComponent.gd
extends Node2D
class_name EnemyLootComponent

const DROPPED_ITEM_SCENE = preload("res://components/loot/dropped-item/dropped-item.tscn")

@export_group("Loot Table")
@export var loot_table: Array[LootData] = []
@export var apply_spread: bool = true
@export var spread_force: float = 300.0

func _ready() -> void:
	var parent = get_parent()
	if parent.has_signal("enemy_died"):
		parent.enemy_died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	_process_all_loot.call_deferred()

func _process_all_loot() -> void:
	for loot in loot_table:
		_process_loot_entry(loot)

func _process_loot_entry(loot: LootData) -> void:
	if randf() > loot.drop_chance:
		return
	_spawn_item(loot)

func _spawn_item(loot: LootData) -> void:
	if not loot.item:
		push_warning("EnemyLootComponent: LootData on %s has no ItemData assigned." % name)
		return

	var item_instance: DroppedItem = DROPPED_ITEM_SCENE.instantiate()
	item_instance.loot_data = loot
	item_instance.quantity = randi_range(loot.min_quantity, loot.max_quantity)

	get_tree().current_scene.add_child(item_instance)
	item_instance.global_position = global_position

	if apply_spread:
		var random_direction := Vector2(randf_range(-0.5, 0.5), -1.0).normalized()
		item_instance.velocity = random_direction * spread_force
