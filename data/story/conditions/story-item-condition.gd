class_name StoryItemCondition extends StoryCondition
@export var item: ItemData
@export_range(1, 9999, 1) var minimum_quantity := 1
@export var must_have := true
func validate(_registry: StoryRegistry) -> PackedStringArray:
	if item == null or QuestManager.registry.items.get(item.item_id) != item: return PackedStringArray(["A registered item is required"])
	return PackedStringArray(["Minimum quantity must be positive"]) if minimum_quantity < 1 else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
	return validate(context.registry).is_empty() and Inventory_Manager.has_item(item.item_id, minimum_quantity) == must_have
