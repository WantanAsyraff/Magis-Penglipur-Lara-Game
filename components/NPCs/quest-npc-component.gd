class_name QuestNPCComponent
extends Node

signal quest_assigned(instance: QuestInstance)
signal dialogue_requested(dialogue_text: String, instance: QuestInstance)
signal despawned

@export_group("Quest Settings")
@export var faculty: QuestData.Faculty = QuestData.Faculty.NONE
@export var npc_id: String = ""
@export var quest_indicator: Node2D = null

var _instance: QuestInstance = null
var _npc: CharacterBody2D = null
var _busy: bool = false

@onready var _dialogic_comp: DialogicComponent = get_parent().find_child("DialogicComponent")

func _ready() -> void:
	_npc = get_parent() as CharacterBody2D
	print("[QuestNPC] ready | npc_id=%s | faculty=%s | _dialogic_comp=%s" % [npc_id, faculty, _dialogic_comp])

func has_quest() -> bool:
	return _instance != null

# -------------------------
# SETUP (called by RoomQuestManager)
# -------------------------
func setup_quest() -> void:
	_instance = QuestManager.request_quest_for_npc(faculty, npc_id)
	print("[QuestNPC] setup_quest | _instance=%s" % _instance)
	if _instance:
		_set_indicator_visible(true)
		quest_assigned.emit(_instance)

# -------------------------
# INTERACT
# -------------------------
func interact() -> void:
	print("[QuestNPC] interact() | _busy=%s | _instance=%s" % [_busy, _instance])
	if _busy:
		print("[QuestNPC] busy, bailing")
		return
	if not _instance:
		if _dialogic_comp:
			_dialogic_comp.start()
		return
	print("[QuestNPC] status=%s | dialogue_offer='%s'" % [_instance.status, _instance.quest_data.dialogue_offer])
	match _instance.status:
		QuestInstance.Status.AVAILABLE:
			_busy = true
			await _run_quest_sequence(_instance.quest_data.dialogue_offer)
			QuestManager.accept_quest(_instance.instance_id)
			_busy = false
		QuestInstance.Status.ACTIVE:
			if _instance.is_objectives_met():
				_busy = true
				await _complete_flow()
				_busy = false
			else:
				_busy = true
				await _run_quest_sequence(_instance.quest_data.dialogue_incomplete)
				_busy = false
		QuestInstance.Status.COMPLETE:
			_busy = true
			await _complete_flow()
			_busy = false

# -------------------------
# CONFIRM HOOKS
# -------------------------
func confirm_offer_complete() -> void:
	QuestManager.accept_quest(_instance.instance_id)

func confirm_complete_dialogue_done() -> void:
	_grant_rewards()
	_set_indicator_visible(false)
	_despawn()

# -------------------------
# INTERNAL FLOW
# -------------------------
func _complete_flow() -> void:
	if QuestManager.try_hand_off(_instance.instance_id):
		await _run_quest_sequence(_instance.quest_data.dialogue_complete)
		_grant_rewards()
		_set_indicator_visible(false)
		_despawn()
	else:
		await _run_quest_sequence(_instance.quest_data.dialogue_incomplete)

func _run_quest_sequence(text: String) -> void:
	print("[QuestNPC] _run_quest_sequence | text='%s'" % text)
	if text.is_empty():
		print("[QuestNPC] text is empty, bailing")
		return
	if _dialogic_comp:
		print("[QuestNPC] calling start_direct_text")
		await _dialogic_comp.start_direct_text(text)
	else:
		print("[QuestNPC] _dialogic_comp is NULL")

func _grant_rewards() -> void:
	if not _instance:
		return
	var data := _instance.quest_data
	Player_Global_Data.player_exp += data.reward_xp
	Player_Global_Data.p_curr_ringgit += data.reward_currency

func _despawn() -> void:
	QuestManager.notify_npc_despawned(_instance.instance_id if _instance else "")
	despawned.emit()
	if _npc:
		_npc.queue_free()

func _set_indicator_visible(is_visible: bool) -> void:
	if quest_indicator:
		quest_indicator.visible = is_visible
