# DialogicComponent.gd
class_name DialogicComponent
extends Node

# -------------------------
# SIGNALS
# -------------------------
signal dialogue_started
signal dialogue_ended

# -------------------------
# EXPORTS
# -------------------------
@export var use_dialogic: bool = true
@export var npc_timeline: DialogicTimeline

# -------------------------
# STATE
# -------------------------
var _open: bool = false

# -------------------------
# API
# -------------------------

## Start dialogue. Returns false if already open or timeline missing.
func start() -> bool:
	if _open:
		return false
	if use_dialogic:
		if npc_timeline == null:
			push_warning("DialogicComponent: use_dialogic is true but no npc_timeline assigned.")
			return false
		if Dialogic.current_timeline != null:
			return false

	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()

	if use_dialogic:
		Dialogic.start(npc_timeline)
		await Dialogic.timeline_ended

	_finish_dialogue()
	return true

## Start an arbitrary timeline by reference (used by QuestNPCComponent).
func start_timeline(timeline) -> void:
	if not timeline or _open:
		return
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	Dialogic.start(timeline)
	if Dialogic.has_signal("timeline_ended"):
		await Dialogic.timeline_ended
	_finish_dialogue()

## Start a timeline by string key (Dialogic timeline name or path).
func start_timeline_by_key(key: String) -> void:
	if key.is_empty() or _open:
		return
	_open = true
	Player_Global_Data.p_moveable = false
	dialogue_started.emit()
	Dialogic.start(key)
	if Dialogic.has_signal("timeline_ended"):
		await Dialogic.timeline_ended
	_finish_dialogue()

func close() -> void:
	if not _open:
		return
	if use_dialogic and Dialogic.current_timeline != null:
		Dialogic.end_timeline()
		# _finish_dialogue() will be called by the await in start() when timeline_ended fires
	else:
		_finish_dialogue()

func is_open() -> bool:
	return _open

# -------------------------
# INTERNAL
# -------------------------
func _finish_dialogue() -> void:
	_open = false
	Player_Global_Data.p_moveable = true
	dialogue_ended.emit()
