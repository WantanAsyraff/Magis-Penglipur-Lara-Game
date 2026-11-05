class_name LootDropBehavior extends DestructionBehavior
@export var entries: Array[LootData] = []
@export_range(0, 1000) var scatter := 180.0
@export_range(0, 5) var pickup_delay := 0.2
@export_range(1, 300) var lifetime := 120.0
func validate() -> PackedStringArray:
	var errors := super.validate()
	if entries.size() > 16: errors.append("Loot is limited to sixteen entries")
	if not is_finite(scatter) or scatter < 0 or not is_finite(pickup_delay) or pickup_delay < 0 or pickup_delay > 5 or not is_finite(lifetime) or lifetime <= 0 or lifetime > 300: errors.append("Invalid loot scatter, delay or lifetime")
	for entry in entries:
		if entry: errors.append_array(entry.validate())
		else: errors.append("Null loot entry")
	return errors
func execute(context: DestructionContext) -> void:
	for entry in entries:
		if context.rng.randf() > entry.drop_chance: continue
		_drop(context, entry, context.rng.randi_range(entry.min_quantity, entry.max_quantity))
		for extra in entry.extra_drops.slice(0,16):
			if extra == entry.item: continue
			var additional := entry.duplicate() as LootData
			additional.item = extra; additional.extra_drops = []
			_drop(context, additional, 1)
func _drop(context: DestructionContext, loot: LootData, quantity: int) -> void:
	var item := load("res://components/loot/dropped-item/dropped-item.tscn").instantiate() as DroppedItem
	item.loot_data = loot; item.quantity = quantity
	item.loot_owner_id = context.credit_owner
	item.pickup_id = context.event_id + ":loot:" + str(context.runtime.total_spawned)
	item.velocity = Vector2(context.rng.randf_range(-0.7,0.7), -1).normalized() * scatter
	item.pickup_delay = pickup_delay
	context.runtime.spawn_node(item, context, context.position, lifetime)
