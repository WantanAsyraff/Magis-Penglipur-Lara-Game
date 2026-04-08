class_name LootData
extends Resource

@export_group("Item Reference")
@export var item: ItemData

@export_group("Drop Logic")
@export_range(0, 1.0) var drop_chance: float = 0.5
@export var min_quantity: int = 1
@export var max_quantity: int = 1

@export_group("Multi-Drop Support")
## Optional: Additional items that drop if this specific loot entry is triggered
@export var extra_drops: Array[ItemData] = []

@export_group("World Drop")
@export var rarity_color: Color = Color.WHITE
