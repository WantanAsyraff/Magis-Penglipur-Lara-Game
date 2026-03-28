class_name QuestObjectiveData
extends Resource

enum ObjectiveType { TALK_TO_NPC, COLLECT_ITEM, DEFEAT_ENEMY, REACH_LOCATION }

@export var objective_id: String = ""
@export var description: String = ""
@export var type: ObjectiveType = ObjectiveType.TALK_TO_NPC
@export var is_optional: bool = false

@export_group("Targets")
## target_ids[i] pairs with required_amounts[i]
## Keep both arrays the same length
@export var target_ids: Array[String] = []
## target_ids[i] pairs with required_amounts[i]
## Keep both arrays the same length
@export var required_amounts: Array[int] = []

@export_group("Order")
@export var requires_objectives: Array[String] = []
