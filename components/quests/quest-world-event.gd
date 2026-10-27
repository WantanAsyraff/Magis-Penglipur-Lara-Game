class_name QuestWorldEvent extends Area2D
## Resource-configured trigger for locations, objects, dialogue and flags.
@export var event_type: GameplayEvent.Type = GameplayEvent.Type.LOCATION_REACHED
@export var target_id: String = ""
@export var quantity: int = 1
@export var metadata: Dictionary = {}
@export var once_per_owner: bool = true
var _owners: Dictionary = {}
func _ready() -> void:
	body_entered.connect(trigger)
func trigger(actor: Node2D) -> void:
	var owner := GameplayEvent.owner_for(actor)
	if owner.is_empty() or target_id.is_empty() or (once_per_owner and _owners.has(owner)): return
	var event := GameplayEvent.new(event_type, target_id, quantity, owner)
	event.metadata = metadata.duplicate(true)
	if QuestManager.publish(event): _owners[owner] = true
