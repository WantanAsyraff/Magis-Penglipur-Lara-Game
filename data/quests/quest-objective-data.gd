class_name QuestObjectiveData
extends Resource

enum ObjectiveType { TALK_TO_NPC, COLLECT_ITEM, DEFEAT_ENEMY, REACH_LOCATION }

@export var objective_id: String = ""
@export var description: String = ""
@export var type: ObjectiveType = ObjectiveType.TALK_TO_NPC
@export var is_optional: bool = false

@export_group("Target")
@export var target_id: String = ""
@export var required_amount: int = 1

@export_group("Order")
@export var requires_objectives: Array[String] = []
