class_name QuestObjectiveData
extends Resource

enum ObjectiveType { TALK_TO_NPC, COLLECT_ITEM, DEFEAT_ENEMY, REACH_LOCATION, SPELL_CAST, SPELL_HIT, STATUS_APPLIED, OBJECT_INTERACTED, QUEST_COMPLETED, WORLD_FLAG_CHANGED, DIALOGUE_COMPLETED }

@export var objective_id: String = ""
@export var description: String = ""
@export var type: ObjectiveType = ObjectiveType.TALK_TO_NPC
@export var is_optional: bool = false

@export_group("Target")
@export var target_id: String = ""
@export var required_amount: int = 1

@export_group("Order")
@export var requires_objectives: Array[String] = []

enum CollectionMode { CUMULATIVE, CURRENT_HELD, DELIVERY }
@export var collection_mode: CollectionMode = CollectionMode.CUMULATIVE
## Any combination of these targets contributes to this one objective.
@export var target_ids: Array[String] = []
@export var target_tags: Array[StringName] = []
@export var match_metadata: Dictionary = {}
@export var group_id: StringName = &""

func targets() -> Array[String]:
	var result: Array[String] = target_ids.duplicate()
	if not target_id.is_empty() and target_id not in result: result.append(target_id)
	return result
