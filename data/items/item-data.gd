class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM, QUEST_ITEM, MATERIAL, COMPONENT, FOOD, WEAPON_MATERIAL, RARE_MATERIAL }

@export_group("Identity")
@export var item_id: String = ""
@export var item_name: String = ""
@export var item_icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export_multiline var description: String = ""

@export_group("Stack")
@export var is_stackable: bool = true
@export var max_stack: int = 99

@export_group("Economy")
@export var ringgit_value: float = 0.0
@export var is_sellable: bool = true

@export_group("Effects")
@export var health_restore: int = 0
@export var mana_restore: float = 0.0
@export var exp_reward: int = 0
@export var spell_to_unlock: SpellData = null

@export_group("Questing")
## List of quest objective IDs this item can satisfy.
@export var quest_objective_ids: Array[String] = []

@export_group("Crafting / Recipe")
@export var ingredient_1: ItemData = null
@export var qty_1: int = 0
@export var ingredient_2: ItemData = null
@export var qty_2: int = 0
@export var ingredient_3: ItemData = null
@export var qty_3: int = 0

@export var tags: Array[StringName] = []
