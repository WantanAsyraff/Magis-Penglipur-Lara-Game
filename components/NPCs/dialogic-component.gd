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
	# GUARD: Ignore if already in a dialogue or text is empty
	if _open:
		print("[Dialogic] Blocked: Dialogue already open.")
		return
		
	if text.is_empty():
		print("[Dialogic] Blocked: Text is empty.")
		return

	print("[Dialogic] start_direct_text | text='%s'" % text)
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	
	Dialogic.VAR.QuestText = text
	
	# Force load the style/layout manually
	var style = load("res://dialogue/styles/main-style.tres")
	Dialogic.start(QUEST_TIMELINE_PATH, style)
	
	await Dialogic.timeline_ended
	_finish_dialogue()

# -------------------------
# STANDARD TIMELINE
# -------------------------
func start() -> bool:
	# GUARD: Prevent spamming the interact button
	if _open:
		print("[Dialogic] Blocked: Dialogue already open.")
		return false
		
	if not use_dialogic or npc_timeline == null:
		return false

	print("[Dialogic] start() | npc_timeline=%s" % npc_timeline)
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
	print("[Dialogic] dialogue finished and closed.")

func is_open() -> bool:
	return _open
