class_name DestructiblePersistence extends RefCounted
## Save V1 world_flags are Boolean-only. 24 bits encode health to 0.01 HP (max 100000).
static func prefix(config: DestructibleConfig) -> String:
	return "destructible:v1:" + config.persistence_id
static func enabled(config: DestructibleConfig) -> bool:
	return config.persistent and not config.respawn_on_scene_reload and not config.persistence_id.is_empty()
static func store(config: DestructibleConfig, health: float, dead: bool) -> void:
	if not enabled(config) or SaveManager.loading: return
	var key := prefix(config)
	if config.persist_health:
		var encoded := clampi(roundi(health * 100), 0, 10000000)
		for bit in 24: QuestManager.set_world_flag(key + ":hp:" + str(bit), bool(encoded & (1 << bit)))
	QuestManager.set_world_flag(key + ":dead", dead)
	QuestManager.set_world_flag(key + ":present", true)
static func restore(config: DestructibleConfig) -> Dictionary:
	var key := prefix(config)
	if not enabled(config) or not QuestManager.world_flags.get(key + ":present", false): return {}
	var encoded := 0
	for bit in 24:
		if QuestManager.world_flags.get(key + ":hp:" + str(bit), false): encoded |= 1 << bit
	return {"health": minf(encoded / 100.0, config.max_health) if config.persist_health else config.max_health, "destroyed": QuestManager.world_flags.get(key + ":dead", false)}
