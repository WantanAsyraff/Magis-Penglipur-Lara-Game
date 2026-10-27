class_name ItemQuestComponent extends Node
## Serialized compatibility only. Confirmed inventory acquisition is the sole event source.
@export var quest_id: String = ""
@export var objective_id: String = ""
func init_component(_parent: DroppedItem) -> void:
	pass
