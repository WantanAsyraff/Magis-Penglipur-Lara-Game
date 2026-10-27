class_name GameplayEvent extends RefCounted
enum Type { ENEMY_DEFEATED, ITEM_COLLECTED, ITEM_REMOVED, NPC_INTERACTED, DIALOGUE_COMPLETED, LOCATION_REACHED, SPELL_CAST, SPELL_HIT, STATUS_APPLIED, OBJECT_INTERACTED, QUEST_COMPLETED, WORLD_FLAG_CHANGED }
var event_id: String = ""
var type: Type = Type.OBJECT_INTERACTED
var owner_id: String = "local"
var actor_id: String = ""
var target_id: String = ""
var source_instance_id: String = ""
var quantity: int = 1
var tags: Array[StringName] = []
var metadata: Dictionary = {}
func _init(kind: Type = Type.OBJECT_INTERACTED, target: String = "", amount: int = 1, owner: String = "local", receipt: String = "") -> void:
	type = kind
	target_id = target
	quantity = amount
	owner_id = owner
	event_id = receipt if not receipt.is_empty() else Crypto.new().generate_random_bytes(16).hex_encode()
func valid() -> bool:
	return type >= 0 and type < Type.size() and not event_id.is_empty() and event_id.length() <= 512 and not owner_id.is_empty() and not target_id.is_empty() and quantity > 0 and quantity <= 1000000
static func owner_for(actor: Variant) -> String:
	if not is_instance_valid(actor): return ""
	if actor.has_meta("quest_owner_id"): return String(actor.get_meta("quest_owner_id"))
	if actor.is_in_group("player"):
		return "peer:%d" % actor.get_multiplayer_authority() if actor.multiplayer.has_multiplayer_peer() and not actor.is_multiplayer_authority() else String(service("QuestManager").get("active_owner_id"))
	return ""
func to_dict() -> Dictionary:
	return {"event_id": event_id, "type": type, "owner_id": owner_id, "actor_id": actor_id, "target_id": target_id, "source_instance_id": source_instance_id, "quantity": quantity, "tags": tags.duplicate(), "metadata": metadata.duplicate(true)}
static func from_dict(row: Dictionary) -> GameplayEvent:
	for key in ["event_id", "owner_id", "target_id"]:
		if not row.get(key) is String or String(row[key]).is_empty(): return null
	for key in ["type", "quantity"]:
		if not (row.get(key) is int or row.get(key) is float): return null
	for tag in row.get("tags", []) if row.get("tags", []) is Array else []:
		if not (tag is String or tag is StringName): return null
	var event := GameplayEvent.new(int(row.get("type", -1)), String(row.get("target_id", "")), int(row.get("quantity", 0)), String(row.get("owner_id", "")), String(row.get("event_id", "")))
	event.actor_id = String(row.get("actor_id", ""))
	event.source_instance_id = String(row.get("source_instance_id", ""))
	if not row.get("tags", []) is Array or not row.get("metadata", {}) is Dictionary: return null
	event.tags.assign(row.get("tags", []))
	event.metadata = row.get("metadata", {})
	return event if event.valid() else null

static func service(id: String) -> Node:
	var loop := Engine.get_main_loop()
	return loop.root.get_node_or_null(id) if loop is SceneTree else null
