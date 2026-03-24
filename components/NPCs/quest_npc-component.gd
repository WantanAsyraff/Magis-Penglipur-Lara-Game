class_name QuestNPCComponent
extends Node

# -------------------------
# SIGNALS
# -------------------------
signal quest_assigned(instance: QuestInstance)
signal dialogue_requested(dialogue_key: String, instance: QuestInstance)
signal despawned

# -------------------------
# EXPORTS
# -------------------------
@export var faculty: QuestData.Faculty = QuestData.Faculty.NONE
@export var npc_id: String = ""
@export var warn_before_despawn: float = 30.0
@export var quest_indicator: Node2D = null

# -------------------------
# STATE
# -------------------------
var _instance: QuestInstance = null
var _npc: CharacterBody2D = null
var _warned: bool = false

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	print("[QuestNPCComponent] _ready() | name='%s' | npc_id='%s' | faculty=%d" % [name, npc_id, faculty])
	_npc = get_parent() as CharacterBody2D
	if not _npc:
		push_error("QuestNPCComponent: parent must be a CharacterBody2D.")
		return
	if npc_id.is_empty():
		push_warning("QuestNPCComponent: npc_id is empty on '%s'." % _npc.name)
	_request_quest()

func _process(_delta: float) -> void:
	if not _instance:
		return
	if _instance.status != QuestInstance.Status.AVAILABLE:
		return
	var remaining := _instance.get_despawn_seconds_remaining()
	if remaining < 0.0:
		return
	if not _warned and remaining <= warn_before_despawn:
		_warned = true
		print("[QuestNPCComponent] '%s' despawn warning | %.1fs remaining" % [npc_id, remaining])
		_on_despawn_warning()
	if remaining <= 0.0:
		print("[QuestNPCComponent] '%s' despawn timer expired" % npc_id)
		_despawn()

# -------------------------
# QUEST REQUEST
# -------------------------
func _request_quest() -> void:
	print("[QuestNPCComponent] '%s' requesting quest | faculty=%d" % [npc_id, faculty])
	_instance = QuestManager.request_quest_for_npc(faculty, npc_id)
	if not _instance:
		print("[QuestNPCComponent] '%s' got no quest" % npc_id)
		_set_indicator_visible(false)
		return
	print("[QuestNPCComponent] '%s' assigned '%s' (instance_id=%s)" % [npc_id, _instance.quest_data.quest_id, _instance.instance_id])
	_set_indicator_visible(true)
	quest_assigned.emit(_instance)

# -------------------------
# INTERACT
# -------------------------
func interact() -> void:
	print("[QuestNPCComponent] '%s' interact() | status=%s" % [
		npc_id,
		str(_instance.status) if _instance else "no instance"
	])
	if not _instance:
		return
	match _instance.status:
		QuestInstance.Status.AVAILABLE:
			_offer_quest()
		QuestInstance.Status.ACTIVE:
			_check_progress()
		QuestInstance.Status.COMPLETE:
			_hand_off()
		QuestInstance.Status.HANDED_OFF, QuestInstance.Status.EXPIRED:
			print("[QuestNPCComponent] '%s' quest already done/expired — ignoring" % npc_id)

# -------------------------
# QUEST FLOW
# -------------------------
func _offer_quest() -> void:
	print("[QuestNPCComponent] '%s' offering quest '%s'" % [npc_id, _instance.quest_data.quest_id])
	var dialogue: String = _instance.quest_data.dialogue_offer
	if dialogue.is_empty():
		print("[QuestNPCComponent] '%s' no offer dialogue — auto-accepting" % npc_id)
		QuestManager.accept_quest(_instance.instance_id)
		return
	print("[QuestNPCComponent] '%s' emitting dialogue_requested: '%s'" % [npc_id, dialogue])
	dialogue_requested.emit(dialogue, _instance)

func confirm_offer_complete() -> void:
	print("[QuestNPCComponent] '%s' confirm_offer_complete() — accepting quest" % npc_id)
	QuestManager.accept_quest(_instance.instance_id)

func _check_progress() -> void:
	print("[QuestNPCComponent] '%s' checking progress on '%s'" % [npc_id, _instance.quest_data.quest_id])
	if _instance.is_objectives_met():
		print("[QuestNPCComponent] '%s' objectives met — handing off" % npc_id)
		_hand_off()
		return
	var dialogue: String = _instance.quest_data.dialogue_incomplete
	if not dialogue.is_empty():
		print("[QuestNPCComponent] '%s' emitting incomplete dialogue: '%s'" % [npc_id, dialogue])
		dialogue_requested.emit(dialogue, _instance)
	else:
		print("[QuestNPCComponent] '%s' no incomplete dialogue set" % npc_id)

func _hand_off() -> void:
	print("[QuestNPCComponent] '%s' attempting hand-off for '%s'" % [npc_id, _instance.instance_id])
	var success: bool = QuestManager.try_hand_off(_instance.instance_id)
	if not success:
		print("[QuestNPCComponent] '%s' hand-off failed — falling back to _check_progress()" % npc_id)
		_check_progress()
		return
	print("[QuestNPCComponent] '%s' hand-off successful" % npc_id)
	var dialogue: String = _instance.quest_data.dialogue_complete
	if not dialogue.is_empty():
		print("[QuestNPCComponent] '%s' emitting complete dialogue: '%s'" % [npc_id, dialogue])
		dialogue_requested.emit(dialogue, _instance)
	else:
		print("[QuestNPCComponent] '%s' no complete dialogue — wrapping up" % npc_id)
		_grant_rewards()
		_set_indicator_visible(false)
		_despawn()

func confirm_complete_dialogue_done() -> void:
	print("[QuestNPCComponent] '%s' confirm_complete_dialogue_done()" % npc_id)
	_grant_rewards()
	_set_indicator_visible(false)
	_despawn()

# -------------------------
# REWARDS
# -------------------------
func _grant_rewards() -> void:
	print("[QuestNPCComponent] '%s' granting rewards for '%s'" % [npc_id, _instance.quest_data.quest_id])
	if not _instance:
		push_warning("QuestNPCComponent: _grant_rewards() called with null instance.")
		return
	var data := _instance.quest_data

	if data.reward_xp > 0:
		Player_Global_Data.p_xp = str(int(Player_Global_Data.p_xp) + data.reward_xp)
		print("[QuestNPCComponent] '%s' granted %d XP | new total=%s" % [npc_id, data.reward_xp, Player_Global_Data.p_xp])

	if data.reward_currency > 0:
		var current := int(Player_Global_Data.p_curr_ringgit) if Player_Global_Data.p_curr_ringgit != "" else 0
		Player_Global_Data.p_curr_ringgit = str(current + data.reward_currency)
		print("[QuestNPCComponent] '%s' granted %d ringgit | new total=%s" % [npc_id, data.reward_currency, Player_Global_Data.p_curr_ringgit])

	if data.reward_item_ids.is_empty():
		print("[QuestNPCComponent] '%s' no item rewards" % npc_id)
	else:
		for i in data.reward_item_ids.size():
			var item_id: String = data.reward_item_ids[i]
			var qty: int = data.reward_item_quantities[i]
			print("[QuestNPCComponent] '%s' grant %dx '%s' (TODO: wire to InventoryManager)" % [npc_id, qty, item_id])

# -------------------------
# DESPAWN
# -------------------------
func _despawn() -> void:
	print("[QuestNPCComponent] '%s' despawning | instance_id=%s" % [
		npc_id,
		_instance.instance_id if _instance else "null"
	])
	QuestManager.notify_npc_despawned(_instance.instance_id if _instance else "")
	despawned.emit()
	_npc.queue_free()

func _on_despawn_warning() -> void:
	print("[QuestNPCComponent] '%s' despawn warning fired — add visual feedback here" % npc_id)

# -------------------------
# INDICATOR
# -------------------------
func _set_indicator_visible(is_visible: bool) -> void:
	print("[QuestNPCComponent] '%s' indicator visible=%s" % [npc_id, is_visible])
	if quest_indicator:
		quest_indicator.visible = is_visible

# -------------------------
# UTILITY
# -------------------------
func has_quest() -> bool:
	return _instance != null

func get_instance() -> QuestInstance:
	return _instance
