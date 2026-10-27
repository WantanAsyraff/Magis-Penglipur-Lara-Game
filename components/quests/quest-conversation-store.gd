class_name QuestConversationStore extends RefCounted
signal changed
var contacts: Dictionary = {}
var receipts: Dictionary = {}
var sequence: int = 0
func record(npc: String, quest: String, kind: String, sender: String, text: String, receipt: String, snapshot: Dictionary = {}) -> bool:
	if npc.is_empty() or receipt.is_empty() or receipts.has(receipt): return false
	var conversation: QuestConversation = contacts.get(npc)
	if conversation == null:
		conversation = QuestConversation.new()
		conversation.npc_id = npc
		var identity := NPCPresentation.resolve(npc)
		conversation.display_name = identity.display_name
		conversation.portrait_path = identity.resolved_portrait().resource_path if identity.resolved_portrait() else ""
		contacts[npc] = conversation
	sequence += 1
	if quest not in conversation.quest_ids: conversation.quest_ids.append(quest)
	conversation.entries.append({"entry_id": receipt, "event_type": kind, "quest_id": quest, "sender_type": sender, "message_text": text, "timestamp": Time.get_unix_time_from_system(), "sequence": sequence, "snapshot": snapshot.duplicate(true)})
	receipts[receipt] = true
	changed.emit()
	return true
func mark_read(id: String) -> void:
	if not contacts.has(id): return
	var conversation: QuestConversation = contacts[id]
	conversation.read_sequence = int(conversation.entries.back().sequence) if not conversation.entries.is_empty() else 0
func to_dict() -> Dictionary:
	var result := {}
	for id in contacts: result[id] = contacts[id].to_dict()
	return result
static func restore(data: Variant, registry: QuestRegistry) -> QuestConversationStore:
	if not data is Dictionary: return null
	var store := QuestConversationStore.new()
	for id in data:
		var row: Variant = data[id]
		if not id is String or id.is_empty() or not row is Dictionary or row.get("npc_id") != id or not row.get("entries") is Array or not row.get("quest_ids") is Array: return null
		if row.entries.is_empty(): return null
		var conversation := QuestConversation.new()
		conversation.npc_id = id
		conversation.display_name = String(row.get("display_name", ""))
		conversation.portrait_path = String(row.get("portrait_path", ""))
		for quest in row.quest_ids:
			if not quest is String or not registry.quests.has(quest): return null
			conversation.quest_ids.append(quest)
		var previous := 0
		for entry in row.entries:
			if not entry is Dictionary: return null
			for key in ["entry_id", "event_type", "quest_id", "sender_type", "message_text"]:
				if not entry.get(key) is String: return null
			if entry.entry_id.is_empty() or entry.quest_id not in conversation.quest_ids or store.receipts.has(entry.entry_id) or not entry.get("snapshot", {}) is Dictionary: return null
			if not (entry.get("sequence") is int or entry.get("sequence") is float) or int(entry.sequence) <= previous: return null
			if entry.sender_type not in ["npc", "player", "system"]: return null
			previous = int(entry.sequence)
			store.sequence = maxi(store.sequence, previous)
			store.receipts[entry.entry_id] = true
			conversation.entries.append(entry.duplicate(true))
		conversation.read_sequence = clampi(int(row.get("read_sequence", 0)), 0, store.sequence)
		store.contacts[id] = conversation
	return store
