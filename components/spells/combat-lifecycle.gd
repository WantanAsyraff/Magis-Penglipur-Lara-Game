class_name CombatLifecycle extends RefCounted
static func own(entity: Node, source: Node) -> void:
	entity.add_to_group("combat_owned")
	entity.set_meta("combat_owner", source)
	var owner := GameplayEvent.owner_for(source)
	if not owner.is_empty(): entity.set_meta("quest_owner_id", owner)
static func cleanup(source: Node) -> void:
	if not source.is_inside_tree(): return
	for entity in source.get_tree().get_nodes_in_group("combat_owned"):
		if entity.get_meta("combat_owner", null) == source and not entity.is_queued_for_deletion(): entity.queue_free()
