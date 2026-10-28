class_name WorldPersistence extends RefCounted
# Authored node path + registered campaign scene defines object identity. No second flag store.
static func flag_for(node: Node, state: String) -> String:
	if SaveManager.active_profile == 0 and not SaveManager.loading: return ""
	var ancestor := node.get_parent()
	while ancestor:
		if ancestor.get_script() and ancestor.get_script().resource_path == "res://data/worlds/zone-root.gd":
			return "object:" + (ancestor.scene_file_path + ":" + str(ancestor.get_path_to(node))).sha256_text() + ":" + state
		ancestor = ancestor.get_parent()
	return ""
static func has_state(node: Node, state: String) -> bool:
	var id := flag_for(node,state)
	return not id.is_empty() and QuestManager.world_flags.get(id,false)
static func mark(node: Node, state: String) -> void:
	var id := flag_for(node,state)
	if not id.is_empty(): QuestManager.set_world_flag(id,true)
