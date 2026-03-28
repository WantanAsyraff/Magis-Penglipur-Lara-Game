class_name ActiveQuest

var data: QuestData
var objective_progress: Dictionary = {}
var is_completed: bool = false

func _init(quest_data: QuestData) -> void:
	data = quest_data
	for obj in quest_data.objectives:
		objective_progress[obj.objective_id] = 0

func update_objective(objective_id: String, amount: int = 1) -> bool:
	if not objective_progress.has(objective_id):
		return false
	objective_progress[objective_id] = min(
		objective_progress[objective_id] + amount,
		_get_required(objective_id)
	)
	return check_all_complete()

func check_all_complete() -> bool:
	for obj in data.objectives:
		if objective_progress.get(obj.objective_id, 0) < _get_required(obj.objective_id):
			return false
	is_completed = true
	return true

func _get_required(objective_id: String) -> int:
	for obj in data.objectives:
		if obj.objective_id == objective_id:
			var total := 0
			for amount in obj.required_amounts:
				total += amount
			return total
	return 1
