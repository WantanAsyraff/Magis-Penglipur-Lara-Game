class_name QuestConversation extends RefCounted
var display_name: String = ""
var portrait_path: String = ""
var npc_id: String
var entries: Array[Dictionary] = []
var quest_ids: Array[String] = []
var read_sequence: int = 0
func to_dict() -> Dictionary:
	return {"display_name": display_name, "portrait_path": portrait_path, "npc_id": npc_id, "quest_ids": quest_ids.duplicate(), "entries": entries.duplicate(true), "read_sequence": read_sequence}
func unread() -> bool:
	return not entries.is_empty() and int(entries.back().sequence) > read_sequence
