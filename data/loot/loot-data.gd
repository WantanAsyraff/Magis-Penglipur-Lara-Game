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

@export_enum("Common", "Uncommon", "Rare", "Epic") var rarity: int = 0
func validate() -> PackedStringArray:
	if item == null or item.item_id.is_empty() or not is_finite(drop_chance) or drop_chance < 0 or drop_chance > 1 or min_quantity < 1 or max_quantity < min_quantity or max_quantity > 9999:
		return PackedStringArray(["Invalid loot item, probability or quantity"])
	for extra in extra_drops:
		if extra == null or extra.item_id.is_empty(): return PackedStringArray(["Invalid bundled extra drop"])
	return PackedStringArray()
