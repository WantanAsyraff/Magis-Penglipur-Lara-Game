class_name EnemyQuestObserver
extends Node

@export var enemy_id: String = ""

var _resolved: bool = false

func _ready() -> void:
	var parent = get_parent()
	if parent.has_signal("enemy_died"):
		parent.enemy_died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	if _resolved or not SpellExecutor.is_authoritative(self): return
	_resolved = true
	if enemy_id.is_empty():
		return
	_notify_quest_manager()

func _notify_quest_manager() -> void:
	var owner := String(get_parent().get_meta("quest_credit_owner", ""))
	if owner.is_empty(): return
	var event := GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, enemy_id, 1, owner, "enemy:" + String(get_parent().get_meta("enemy_network_id", get_parent().get_instance_id())))
	event.source_instance_id = String(get_parent().get_meta("enemy_network_id", ""))
	if get_parent() is Enemy: event.tags.assign(get_parent().definition.enemy_tags)
	QuestManager.publish(event)
