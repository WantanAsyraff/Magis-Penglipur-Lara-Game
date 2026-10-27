class_name QuestNPCComponent extends Node
signal quest_assigned(instance: QuestInstance)
signal dialogue_requested(dialogue_text: String, instance: QuestInstance)
signal despawned
@export var faculty: QuestData.Faculty = QuestData.Faculty.NONE
@export var npc_id: String = ""
@export var presentation: NPCPresentation
@export var quest_indicator: Node2D
@export_multiline var dialogue_offer: String = "Hello! I have a task for you."
@export_multiline var dialogue_incomplete: String = "You haven't finished the task yet!"
@export_multiline var dialogue_complete: String = "Great job! Here is your reward."
var _instance: QuestInstance
var _npc: CharacterBody2D
var _busy: bool = false
var _announced_despawn: bool = false
@onready var _dialogic_comp: DialogicComponent = get_parent().find_child("DialogicComponent")
func _ready() -> void:
	if presentation == null: presentation = NPCPresentation.resolve(npc_id)
	get_parent().add_to_group("quest_npc")
	QuestManager.quests_changed.connect(_update_indicator)
	_npc = get_parent() as CharacterBody2D
	setup_quest.call_deferred()
func _exit_tree() -> void:
	if is_instance_valid(QuestManager): QuestManager.release_npc(npc_id)
	if is_instance_valid(Player_Global_Data): Player_Global_Data.unregister_npc(npc_id)
	if not _announced_despawn:
		_announced_despawn = true
		despawned.emit()
func has_quest() -> bool:
	return _instance != null and _instance.status in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]
func setup_quest() -> void:
	if npc_id.is_empty() or not is_inside_tree() or is_queued_for_deletion(): return
	_instance = QuestManager.request_quest_for_npc(faculty, npc_id)
	_update_indicator()
	if _instance: quest_assigned.emit(_instance)
func interact() -> void:
	if _busy or QuestOfferDialog.is_open() or Dialogic.current_timeline != null: return
	if not has_quest(): setup_quest()
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.NPC_INTERACTED, npc_id))
	_busy = true
	if _instance == null:
		await _run_quest_sequence("There are no available tasks right now. Check your journal for locked prerequisites.")
	else:
		match _instance.status:
			QuestInstance.Status.AVAILABLE:
				if await _run_quest_sequence(_offer_text()):
					var offer_identity := presentation.duplicate() as NPCPresentation
					offer_identity.offer_dialogue = _offer_text()
					var panel := QuestOfferDialog.show_offer(_instance.instance_id, npc_id, self, offer_identity, _dialogic_comp)
					if panel: await panel.closed
			QuestInstance.Status.ACTIVE:
				await _run_quest_sequence(_authored_text(_instance.quest_data.dialogue_incomplete, dialogue_incomplete, "You haven't finished the task yet!"))
			QuestInstance.Status.COMPLETE:
				await _complete_flow()
	_busy = false
func _run_quest_sequence(text: String) -> bool:
	if _dialogic_comp and _dialogic_comp.use_dialogic:
		return await _dialogic_comp.start_direct_text(text, npc_id, presentation.dialogue_identity if presentation else npc_id)
	return true
func _complete_flow() -> void:
	if not await _run_quest_sequence("Your work is ready to hand in. Confirm to claim the listed rewards."): return
	if QuestManager.try_hand_off(_instance.instance_id, npc_id):
		await _run_quest_sequence(_authored_text(_instance.quest_data.dialogue_complete, dialogue_complete, "Great job! Here is your reward."))
		_set_indicator_visible(false)
		_despawn()
	else:
		await _run_quest_sequence(_instance.pending_claim if not _instance.pending_claim.is_empty() else dialogue_incomplete)
func confirm_offer_complete() -> void:
	# Legacy narrative callback cannot activate a quest. Only explicit offer decisions can.
	pass
func confirm_complete_dialogue_done() -> void:
	if _instance and QuestManager.try_hand_off(_instance.instance_id, npc_id): _despawn()
func _grant_rewards() -> void:
	# Legacy callbacks route through the same idempotent service.
	if _instance: QuestManager.try_hand_off(_instance.instance_id, npc_id)
func _despawn() -> void:
	if _announced_despawn: return
	_announced_despawn = true
	QuestManager.release_npc(npc_id)
	Player_Global_Data.unregister_npc(npc_id)
	despawned.emit()
	if is_instance_valid(_npc): _npc.queue_free()
func _set_indicator_visible(value: bool) -> void:
	if is_instance_valid(quest_indicator): quest_indicator.visible = value
func _text(preferred: String, fallback: String) -> String:
	return preferred if not preferred.is_empty() else fallback

func _update_indicator() -> void:
	if _instance: _instance = QuestManager.get_instance(_instance.instance_id)
	if _instance == null: _instance = QuestManager.get_instance_for_npc(npc_id)
	_set_indicator_visible(_instance != null and _instance.status in [QuestInstance.Status.AVAILABLE, QuestInstance.Status.COMPLETE])

func _offer_text() -> String:
	if presentation and not presentation.offer_dialogue.is_empty(): return presentation.offer_dialogue
	return _authored_text(_instance.quest_data.dialogue_offer, dialogue_offer, "Hello! I have a task for you.")
func _authored_text(quest_text: String, npc_text: String, default_text: String) -> String:
	if not npc_text.is_empty() and npc_text != default_text:
		return npc_text + ("\n\n" + quest_text if not quest_text.is_empty() and quest_text != npc_text else "")
	return _text(quest_text, npc_text)
