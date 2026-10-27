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
	for instance in QuestManager.get_all_active():
		for objective in instance.quest_data.objectives:
			if objective.type == QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY:
				if enemy_id in objective.target_id:
					QuestManager.update_objective(instance.instance_id, objective.objective_id, 1)
