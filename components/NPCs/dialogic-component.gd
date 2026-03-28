class_name DialogicComponent
extends Node

signal dialogue_started
signal dialogue_ended

@export var use_dialogic: bool = true
@export var npc_timeline: DialogicTimeline

const QUEST_TIMELINE_PATH = "res://dialogue/quest/QuestDialogue.dtl"

var _open: bool = false

# -------------------------
# DIRECT TEXT (quest dialogue)
# -------------------------
func start_direct_text(text: String) -> void:
	print("[Dialogic] start_direct_text | _open=false | text='%s'" % text)
	if _open or text.is_empty():
		return
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	Dialogic.VAR.QuestText = text
	# Force load the style/layout manually
	var style = load("res://dialogue/styles/main-style.tres")
	print("[Dialogic] style loaded: %s" % style)
	Dialogic.start(QUEST_TIMELINE_PATH, style)
	await Dialogic.timeline_ended
	_finish_dialogue()

# -------------------------
# STANDARD TIMELINE
# -------------------------
func start() -> bool:
	print("[Dialogic] start() | _open=%s | use_dialogic=%s | npc_timeline=%s" % [_open, use_dialogic, npc_timeline])
	if _open or not use_dialogic or npc_timeline == null:
		return false
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	Dialogic.start(npc_timeline)
	await Dialogic.timeline_ended
	_finish_dialogue()
	return true

# -------------------------
# CLOSE
# -------------------------
func close() -> void:
	if not _open:
		return
	Dialogic.end_timeline()

# -------------------------
# INTERNAL
# -------------------------
func _finish_dialogue() -> void:
	_open = false
	Player_Global_Data.p_moveable = true
	dialogue_ended.emit()

func is_open() -> bool:
	return _open
