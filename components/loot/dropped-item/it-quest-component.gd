# ItemQuestComponent.gd
extends Node
class_name ItemQuestComponent

@export var quest_id: String = ""
@export var objective_id: String = ""

var _parent_item: DroppedItem

# Called by DroppedItem during _ready
func init_component(parent: DroppedItem) -> void:
	_parent_item = parent
	# Assuming your items have a 'picked_up' signal or area detection
	var pickup_area = _parent_item.find_child("PickupArea")
	if pickup_area:
		pickup_area.body_entered.connect(_on_picked_up)

func _on_picked_up(body: Node) -> void:
	if body.is_in_group("player"):
		if quest_id != "" and objective_id != "":
			QuestManager.update_objective_by_quest(quest_id, objective_id, 1)
		
		# Optional: Play sound, then free the parent
		_parent_item.queue_free()
