# EnemyQuestObserver.gd
extends Node
class_name EnemyQuestObserver

## This should match the 'target_id' or 'objective_id' in your QuestObjectiveData
@export var enemy_id: String = "" 

func _ready() -> void:
	var parent = get_parent()
	if parent.has_signal("enemy_died"):
		parent.enemy_died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	if enemy_id == "":
		return
		
	# We use the 'update_objective_by_quest' logic or a global 'check all active'
	# Because players might have multiple quests to kill the same enemy type
	_notify_quest_manager()

func _notify_quest_manager() -> void:
	# Loop through active quests in your QuestManager
	for instance in QuestManager.get_all_active():
		for objective in instance.quest_data.objectives:
			# Check if this objective cares about THIS specific enemy_id
			if objective.type == QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY:
				if objective.target_id == enemy_id:
					QuestManager.update_objective(instance.instance_id, objective.objective_id, 1)
