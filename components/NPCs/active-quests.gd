class_name ActiveQuest extends QuestInstance
var data: QuestData:
	get: return quest_data
var is_completed: bool:
	get: return is_objectives_met()
func _init(definition: QuestData) -> void:
	super(definition)
	status = Status.ACTIVE
func check_all_complete() -> bool:
	return is_objectives_met()
