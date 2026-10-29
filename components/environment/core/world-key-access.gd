class_name WorldKeyAccess extends RefCounted
static func has_key(id: String) -> bool:
	return Player_Global_Data.has_meta("keys") and (Player_Global_Data.get_meta("keys") as Array).has(id)
static func consume(id: String) -> void:
	if not Player_Global_Data.has_meta("keys"): return
	var keys: Array = Player_Global_Data.get_meta("keys")
	keys.erase(id)
	Player_Global_Data.set_meta("keys",keys)
