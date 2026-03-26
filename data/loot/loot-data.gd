# LootData.gd
class_name LootData
extends Resource

@export_group("Identity")
@export var item_id: String = ""
@export var item_name: String = ""
@export var item_icon: Texture2D

@export_group("Drop Logic")
## 0.0 = Never drops, 1.0 = Always drops (100%)
@export_range(0, 1.0) var drop_chance: float = 0.5
## Minimum amount to drop in one go
@export var min_quantity: int = 1
## Maximum amount to drop in one go
@export var max_quantity: int = 1

@export_group("World Drop")
@export var item_scene: PackedScene # Drag DroppedItem.tscn here
@export var rarity_color: Color = Color.WHITE

@export_group("Player Impact")
@export var health_restore: int = 0
@export var mana_restore: float = 0.0
@export var exp_reward: int = 0
@export var currency_reward: int = 0
@export var spell_to_unlock: SpellData = null

@export_group("Questing")
@export var is_quest_item: bool = false
@export var quest_objective_id: String = "" # e.g., "collect_slime_gel"
