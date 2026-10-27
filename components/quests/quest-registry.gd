class_name QuestRegistry extends RefCounted

var quests: Dictionary = {}
var items: Dictionary = {}
var enemy_ids: Dictionary = {}
var errors: PackedStringArray = []
func _init() -> void:
	var item_path: String = "res://data/items/item-manifest.gd"
	var item_manifest: Variant = load(item_path)
	for item in item_manifest.ITEMS: _register_item(item)
	for loot in item_manifest.LEGACY_LOOT:
		if loot.item: _register_item(loot.item)
	var enemy_path: String = "res://data/npc/enemies/enemy-manifest.gd"
	var enemy_manifest: Variant = load(enemy_path)
	for enemy in enemy_manifest.ENEMIES: enemy_ids[String(enemy.enemy_id)] = true
	for path in ["res://data/quests/flac-database.tres", "res://data/quests/bakau-database.tres"]:
		var database: QuestDatabase = load(path)
		for quest in database.quests:
			if quests.has(quest.quest_id): errors.append("Duplicate quest: " + quest.quest_id)
			else: quests[quest.quest_id] = quest
	for quest in quests.values(): errors.append_array(validate(quest))
	for field in ["prerequisite_quest_ids", "next_quest_id"]:
		for id in quests: _cycle(id, field, [], errors)
func _register_item(item: ItemData) -> void:
	if item == null or item.item_id.is_empty() or item.max_stack < 1: errors.append("Invalid item definition"); return
	if items.has(item.item_id) and items[item.item_id] != item: errors.append("Duplicate item: " + item.item_id); return
	items[item.item_id] = item
func validate(quest: QuestData) -> PackedStringArray:
	var result := PackedStringArray()
	if quest == null: return PackedStringArray(["Missing quest"])
	if quest.quest_id.is_empty() or quest.title.is_empty() or quest.objectives.is_empty(): result.append("Quest requires identity, title and objectives")
	if quest.reward_xp < 0 or quest.reward_currency < 0 or quest.faculty < 0 or quest.faculty >= QuestData.Faculty.size() or not is_finite(quest.expires_after_seconds) or quest.expires_after_seconds < 0: result.append("Invalid quest rewards, faculty or expiry")
	for id in quest.prerequisite_quest_ids:
		if not quests.has(id): result.append("Unknown prerequisite: " + id)
	if not quest.next_quest_id.is_empty() and not quests.has(quest.next_quest_id): result.append("Unknown next quest")
	var objectives := {}
	var groups := {}
	for group in quest.objective_groups:
		if group == null or group.group_id == &"" or groups.has(group.group_id) or group.minimum_completed < 1: result.append("Invalid objective group"); continue
		groups[group.group_id] = group
	for obj in quest.objectives:
		if obj == null: result.append("Missing objective"); continue
		if obj.objective_id.is_empty() or objectives.has(obj.objective_id) or obj.required_amount < 1 or obj.required_amount > 1000000: result.append("Invalid objective identity or quantity")
		objectives[obj.objective_id] = obj
		if obj.type < 0 or obj.type >= QuestObjectiveData.ObjectiveType.size() or obj.collection_mode < 0 or obj.collection_mode >= QuestObjectiveData.CollectionMode.size(): result.append("Invalid objective mode")
		if obj.targets().is_empty() and obj.target_tags.is_empty(): result.append("Objective has no target")
		if obj.group_id != &"" and not groups.has(obj.group_id): result.append("Unknown objective group")
		for target in obj.targets():
			match obj.type:
				QuestObjectiveData.ObjectiveType.COLLECT_ITEM:
					if not items.has(target): result.append("Unknown item: " + target)
				QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY:
					if not enemy_ids.has(target): result.append("Unknown enemy: " + target)
				QuestObjectiveData.ObjectiveType.SPELL_CAST, QuestObjectiveData.ObjectiveType.SPELL_HIT:
					if GameplayEvent.service("Spell_Library").call("get_spell_by_id", target) == null: result.append("Unknown spell: " + target)
				QuestObjectiveData.ObjectiveType.QUEST_COMPLETED:
					if not quests.has(target): result.append("Unknown objective quest: " + target)
	for obj in quest.objectives:
		if obj == null: continue
		for id in obj.requires_objectives:
			if not objectives.has(id): result.append("Unknown objective prerequisite")
		_objective_cycle(obj.objective_id, objectives, [], result)
	for group in quest.objective_groups:
		if group == null: continue
		var count := 0
		for obj in quest.objectives:
			if obj != null and obj.group_id == group.group_id and not obj.is_optional: count += 1
		if count == 0 or (group.policy == QuestObjectiveGroup.Policy.ANY and count < group.minimum_completed): result.append("Unsatisfiable objective group")
	for reward in quest.reward_items:
		if reward == null or not reward.validate().is_empty(): result.append("Invalid item reward"); continue
		if not items.has(reward.item.item_id) or reward.min_quantity != reward.max_quantity or not reward.extra_drops.is_empty(): result.append("Rewards require registered items and fixed unbundled quantities")
	for spell in quest.reward_spells:
		if spell == null or GameplayEvent.service("Spell_Library").call("get_spell_by_id", spell.spell_id) == null: result.append("Unknown reward spell")
	return result
func _cycle(id: String, field: String, path: Array, result: PackedStringArray) -> void:
	if id in path: result.append("Quest dependency cycle: " + id); return
	if not quests.has(id): return
	var refs: Array = quests[id].prerequisite_quest_ids if field == "prerequisite_quest_ids" else ([quests[id].next_quest_id] if not quests[id].next_quest_id.is_empty() else [])
	for ref in refs: _cycle(ref, field, path + [id], result)
func _objective_cycle(id: String, objectives: Dictionary, path: Array, result: PackedStringArray) -> void:
	if id in path: result.append("Objective cycle: " + id); return
	if not objectives.has(id): return
	for ref in objectives[id].requires_objectives: _objective_cycle(ref, objectives, path + [id], result)
