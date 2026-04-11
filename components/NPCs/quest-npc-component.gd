class_name QuestNPCComponent
extends Node

signal quest_assigned(instance: QuestInstance)
signal dialogue_requested(dialogue_text: String, instance: QuestInstance)
signal despawned

@export_group("Quest Settings")
@export var faculty: QuestData.Faculty = QuestData.Faculty.NONE
## This ID must match the Character name/ID in the Dialogic Editor
@export var npc_id: String = ""
@export var quest_indicator: Node2D = null

@export_group("Quest Dialogue")
@export_multiline var dialogue_offer: String = "Hello! I have a task for you."
@export_multiline var dialogue_incomplete: String = "You haven't finished the task yet!"
@export_multiline var dialogue_complete: String = "Great job! Here is your reward."

var _instance: QuestInstance = null
var _npc: CharacterBody2D = null
var _busy: bool = false

@onready var _dialogic_comp: DialogicComponent = get_parent().find_child("DialogicComponent")

func _ready() -> void:
	_npc = get_parent() as CharacterBody2D
	
	# Hook into Dialogic start (extra safety)
	if Engine.has_singleton("Dialogic"):
		Dialogic.timeline_started.connect(_on_dialogic_started)

func _exit_tree() -> void:
	if not _instance:
		Player_Global_Data.unregister_npc(npc_id)
		return
	if _instance.status == QuestInstance.Status.AVAILABLE:
		QuestManager.release_npc(npc_id)
		Player_Global_Data.unregister_npc(npc_id)

func has_quest() -> bool:
	return _instance != null

func setup_quest() -> void:
	_instance = QuestManager.request_quest_for_npc(faculty, npc_id)
	if _instance:
		_set_indicator_visible(true)
		quest_assigned.emit(_instance)

# -------------------------
# INTERACT
# -------------------------
func interact() -> void:
	if _busy: return
	
	if not _instance:
		if _dialogic_comp:
			_dialogic_comp.start(npc_id)
			await get_tree().process_frame
			_update_dialogic_portrait()
		return
		
	match _instance.status:
		QuestInstance.Status.AVAILABLE:
			_busy = true
			await _run_quest_sequence(dialogue_offer)
			QuestManager.accept_quest(_instance.instance_id)
			_busy = false
			
		QuestInstance.Status.ACTIVE:
			_busy = true
			if _instance.is_objectives_met():
				await _complete_flow()
			else:
				await _run_quest_sequence(dialogue_incomplete)
			_busy = false
			
		QuestInstance.Status.COMPLETE:
			_busy = true
			await _complete_flow()
			_busy = false

# -------------------------
# INTERNAL FLOW
# -------------------------
func _run_quest_sequence(text: String) -> void:
	if text.is_empty(): return
	if _dialogic_comp:
		await _dialogic_comp.start_direct_text(text, npc_id)
		await get_tree().process_frame
		_update_dialogic_portrait()

func _complete_flow() -> void:
	if QuestManager.try_hand_off(_instance.instance_id):
		await _run_quest_sequence(dialogue_complete)
		_grant_rewards()
		_set_indicator_visible(false)
		_despawn()
	else:
		await _run_quest_sequence(dialogue_incomplete)

# -------------------------
# DIALOGIC INTEGRATION
# -------------------------
func _update_dialogic_portrait() -> void:
	if Engine.has_singleton("Dialogic"):
		if Dialogic.VAR.has("CurrentPortrait"):
			Dialogic.VAR.set("CurrentPortrait", npc_id)
			print("Portrait set to: ", npc_id)
		else:
			push_warning("Dialogic variable 'CurrentPortrait' does not exist!")

func _on_dialogic_started(_timeline_name: String) -> void:
	# Force update again when timeline begins (prevents override)
	await get_tree().process_frame
	_update_dialogic_portrait()

# -------------------------
# UTILITY
# -------------------------
func confirm_offer_complete() -> void:
	QuestManager.accept_quest(_instance.instance_id)

func confirm_complete_dialogue_done() -> void:
	_grant_rewards()
	_set_indicator_visible(false)
	_despawn()

func _grant_rewards() -> void:
	if not _instance: return
	var data := _instance.quest_data
	Player_Global_Data.player_exp += data.reward_xp
	Player_Global_Data.p_curr_ringgit += data.reward_currency

func _despawn() -> void:
	QuestManager.notify_npc_despawned(_instance.instance_id if _instance else "")
	Player_Global_Data.unregister_npc(npc_id)
	despawned.emit()
	if _npc: _npc.queue_free()

func _set_indicator_visible(is_visible: bool) -> void:
	if quest_indicator:
		quest_indicator.visible = is_visible
