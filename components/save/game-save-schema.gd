class_name GameSaveSchema extends RefCounted
const VERSION := 1
# Current authored curriculum; add future courses here when they become campaign content.
const COURSES = [preload("res://data/magis/ilmiah/physics-field/physical-science.tres")]
const NUMBERS := {"player_level": [1,100000], "p_max_health": [1,10000000], "p_curr_health": [1,10000000], "p_max_mana": [1,10000000], "p_curr_mana": [0,10000000]}
const BOOLEANS := ["combat_mode","phone_visible"]
const STRINGS := ["p_name", "p_role", "p_mood", "current_field", "current_major", "current_minor"]

static func capture_player() -> Dictionary:
	var player := {}
	for key in NUMBERS: player[key] = Player_Global_Data.get(key)
	for key in STRINGS: player[key] = Player_Global_Data.get(key)
	for key in BOOLEANS: player[key] = Player_Global_Data.get(key)
	player.keys = Player_Global_Data.get_meta("keys", []).duplicate()
	player.completed_subjects = Player_Global_Data.completed_subjects.duplicate()
	player.academic_comprehension = {}
	for id in Player_Global_Data.academic_comprehension: player.academic_comprehension[str(id)] = Player_Global_Data.academic_comprehension[id]
	player.equipped_spells = []
	for spell in Player_Global_Data.equipped_spells: player.equipped_spells.append(spell.spell_id)
	return player

static func valid_number(value: Variant, minimum: float, maximum: float, integral: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and (not integral or float(value) == floorf(float(value)))

static func valid_position(value: Variant) -> bool:
	return value is Array and value.size() == 2 and valid_number(value[0],-10000000,10000000) and valid_number(value[1],-10000000,10000000)

static func stage(data: Dictionary, profile: int, registry: Node) -> Dictionary:
	if data.get("version") != VERSION or data.get("profile") != profile or data.get("slot") not in ["manual","auto"]: return {}
	if not data.get("player") is Dictionary or not data.get("quest") is Dictionary or not data.get("location") is Dictionary or not data.get("checkpoint") is Dictionary or not data.get("meta") is Dictionary: return {}
	var p: Dictionary = data.player
	if not p.get("keys",[]) is Array or p.get("keys",[]).size() > 4096: return {}
	for id in p.get("keys",[]):
		if not id is String or id.is_empty() or id.length() > 128: return {}
	for key in NUMBERS:
		if not valid_number(p.get(key), NUMBERS[key][0], NUMBERS[key][1], key in ["player_level","p_max_health","p_curr_health"]): return {}
	if p.p_curr_health > p.p_max_health or p.p_curr_mana > p.p_max_mana: return {}
	for key in BOOLEANS:
		if not p.get(key) is bool: return {}
	for key in STRINGS:
		if not p.get(key) is String or p[key].length() > 256: return {}
	if not p.get("completed_subjects") is Array or p.completed_subjects.size() > 4096 or not p.get("academic_comprehension") is Dictionary or p.academic_comprehension.size() > 256: return {}
	var known_subjects := {}
	for course in COURSES:
		for subject in course.subjects: known_subjects[subject.subject_id] = true
	for id in p.completed_subjects:
		if not id is String or not known_subjects.has(id): return {}
	for id in p.academic_comprehension:
		if not id is String or id.length() > 128 or not valid_number(p.academic_comprehension[id],0,100000,true): return {}
	if not p.get("equipped_spells") is Array or p.equipped_spells.size() > 512: return {}
	var equipped: Array[SpellData] = []
	for id in p.equipped_spells:
		if not id is String or id not in data.quest.get("learned_spells", []): return {}
		var spell := Spell_Library.get_spell_by_id(id)
		if spell == null or spell in equipped: return {}
		equipped.append(spell)
	for location in [data.location, data.checkpoint]:
		if not location.get("scene_id") is String or not registry.scene_exists(location.scene_id) or not valid_position(location.get("position")): return {}
		if not valid_number(location.get("facing",1),-1,1,true) or absf(float(location.get("facing",1))) != 1: return {}
	if not data.checkpoint.get("combat_mode",false) is bool: return {}
	if not data.checkpoint.get("id") is String or data.checkpoint.id.length() > 256: return {}
	if not data.meta.get("name") is String or data.meta.name.length() > 256 or not valid_number(data.meta.get("playtime"),0,1e12) or not valid_number(data.meta.get("timestamp"),0,1e12): return {}
	if data.meta.name != p.p_name: return {}
	var q: Dictionary = data.quest
	# Bound untrusted containers before delegating reference and receipt validation.
	for key in ["instances","inventory","completed_quests","learned_spells","pending_events"]:
		if not q.get(key) is Array or q[key].size() > 100000: return {}
	for key in ["claims","seen_events","world_flags","acquisition_receipts","equipment"]:
		if not q.get(key) is Dictionary or q[key].size() > 100000: return {}
	for key in ["player_xp","currency"]:
		if not valid_number(q.get(key),0,1e12): return {}
	if not valid_number(q.get("max_slots"),1,10000,true): return {}
	for entry in q.inventory:
		if not entry is Dictionary or not entry.get("item_id") is String or not valid_number(entry.get("quantity"),1,1e9,true): return {}
	for slot in q.equipment:
		if slot not in ["0","1","2","3","4"] or not q.equipment[slot] is String: return {}
	for flag in q.world_flags:
		if not flag is String or flag.length() > 256 or not q.world_flags[flag] is bool: return {}
	for id in q.claims:
		var claim: Variant = q.claims[id]
		if not claim is Dictionary or not QuestManager.registry.quests.has(claim.get("quest_id", "")) or claim.get("owner_id") != QuestManager.active_owner_id: return {}
	for id in q.seen_events:
		if not id is String or id.length() > 1024 or not q.seen_events[id] is bool: return {}
	for instance in q.instances:
		if not instance is Dictionary: return {}
		for key in ["accepted_at","completed_at","despawn_time"]:
			if not valid_number(instance.get(key,-1),-1,1e12): return {}
		if not valid_number(instance.get("status"),0,QuestInstance.Status.size()-1,true): return {}
		if not instance.get("reward_claimed") is bool or not instance.get("objective_progress") is Dictionary: return {}
		for value in instance.objective_progress.values():
			if not valid_number(value,0,1e9,true): return {}
	var quest := QuestSaveService.stage(QuestManager,q)
	if quest.is_empty(): return {}
	return {"data": data.duplicate(true), "quest": quest, "equipped": equipped, "scene": registry.get_scene(data.location.scene_id).scene}

static func apply_player(p: Dictionary, equipped: Array[SpellData]) -> void:
	for key in ["p_max_health","p_max_mana"]: Player_Global_Data.set(key,p[key])
	for key in NUMBERS: Player_Global_Data.set(key,p[key])
	for key in STRINGS: Player_Global_Data.set(key,p[key])
	for key in BOOLEANS: Player_Global_Data.set(key,p[key])
	Player_Global_Data.set_meta("keys", p.get("keys",[]).duplicate())
	Player_Global_Data.completed_subjects.assign(p.completed_subjects)
	Player_Global_Data.academic_comprehension.clear()
	for key in p.academic_comprehension: Player_Global_Data.academic_comprehension[StringName(key)] = int(p.academic_comprehension[key])
	Player_Global_Data.equipped_spells = equipped.duplicate()
	Player_Global_Data.spells_updated.emit()
	Player_Global_Data.progression_changed.emit()
