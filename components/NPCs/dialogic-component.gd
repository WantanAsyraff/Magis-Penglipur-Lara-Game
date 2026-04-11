class_name DialogicComponent
extends Node

signal dialogue_started
signal dialogue_ended

@export var use_dialogic: bool = true
@export var npc_timeline: DialogicTimeline

@export var QUEST_TIMELINE_PATH = "res://dialogue/quest/QuestDialogue.dtl"

var _open: bool = false

# -------------------------
# DIRECT TEXT (quest dialogue)
# -------------------------
func start_direct_text(text: String, npc_id: String = "") -> void:
	if _open or text.is_empty(): 
		return
	
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	
	# Set quest text
	Dialogic.VAR.set_variable("QuestText", text)
	
	# ✅ FIXED HERE
	if not npc_id.is_empty():
		Dialogic.VAR.set_variable("CurrentPortrait", npc_id)
	
	var style = load("res://dialogue/styles/main-style.tres")
	Dialogic.start(QUEST_TIMELINE_PATH, style)
	
	await Dialogic.timeline_ended
	_finish_dialogue()

# -------------------------
# STANDARD TIMELINE
# -------------------------
func start(npc_id: String = "") -> bool:
	if _open or not use_dialogic or npc_timeline == null: 
		return false
	
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	
	# ✅ FIXED HERE
	if not npc_id.is_empty():
		Dialogic.VAR.set_variable("CurrentPortrait", npc_id)
	
	Dialogic.start(npc_timeline)
	
	await Dialogic.timeline_ended
	_finish_dialogue()
	return true

# -------------------------
# HELPERS
# -------------------------
func close() -> void:
	if not _open: return
	Dialogic.end_timeline()

func _finish_dialogue() -> void:
	_open = false
	
	# FIXED HERE
	Dialogic.VAR.set_variable("CurrentPortrait", "")
	
	Player_Global_Data.p_moveable = true
	dialogue_ended.emit()

func is_open() -> bool:
	return _open
