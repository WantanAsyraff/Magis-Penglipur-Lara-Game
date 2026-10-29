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

enum UseBehavior { AUTOMATIC_COMPATIBILITY, MANUAL, ACQUISITION_REWARD, NONE }
@export_group("Actions")
## Compatibility means food/consumable restoration is manual; legacy XP/spells grant once per ID.
@export var use_behavior: UseBehavior = UseBehavior.AUTOMATIC_COMPATIBILITY
@export_flags("Weapon", "Offhand", "Robe", "Accessory 1", "Accessory 2") var equipment_slots: int = 0
@export var can_drop: bool = true
@export var allow_wasted_use: bool = false

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

func supports_slot(slot: int) -> bool:
	return item_type == ItemType.EQUIPMENT and slot >= 0 and slot < 5 and equipment_slots & (1 << slot) != 0
func manual_use() -> bool:
	return use_behavior == UseBehavior.MANUAL or (use_behavior == UseBehavior.AUTOMATIC_COMPATIBILITY and item_type in [ItemType.CONSUMABLE,ItemType.FOOD])
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id.is_empty() or item_name.is_empty() or max_stack < 1: errors.append("Item needs identity and positive stack capacity")
	if health_restore < 0 or not is_finite(mana_restore) or mana_restore < 0 or exp_reward < 0 or not is_finite(ringgit_value) or ringgit_value < 0: errors.append("Invalid item effect/value")
	if item_type not in ItemType.values() or use_behavior not in UseBehavior.values(): errors.append("Invalid item category or use behavior")
	if equipment_slots < 0 or equipment_slots > 31 or (equipment_slots != 0 and item_type != ItemType.EQUIPMENT): errors.append("Only equipment can declare valid equipment slots")
	return errors
