class_name QuestWorldEvent extends Area2D
## Resource-configured trigger for locations, objects, dialogue and flags.
@export var event_type: GameplayEvent.Type = GameplayEvent.Type.LOCATION_REACHED
@export var target_id: String = ""
@export var quantity: int = 1
@export var metadata: Dictionary = {}
@export var once_per_owner: bool = true
@export_group("Story Gate")
@export var trigger_id: String = ""
@export var story_conditions: Array[StoryCondition] = []
var _owners: Dictionary = {}
func _ready() -> void:
	body_entered.connect(trigger)
func trigger(actor: Node2D) -> void:
	# An Area2D entrance can prove location arrival only. Other event types must be
	# published by the gameplay system that actually performed the action.
	if event_type != GameplayEvent.Type.LOCATION_REACHED: return
	var owner := GameplayEvent.owner_for(actor)
	if owner.is_empty() or target_id.is_empty() or (once_per_owner and _owners.has(owner)): return
	if not story_conditions.is_empty():
		if SaveManager.loading or not StoryDirector.is_ready(): return
		for condition in story_conditions:
			if condition == null or not StoryDirector.evaluate_condition(condition): return
	var receipt := "story_trigger:" + trigger_id + ":" + owner if once_per_owner and not trigger_id.is_empty() else ""
	var event := GameplayEvent.new(event_type, target_id, quantity, owner, receipt)
	event.metadata = metadata.duplicate(true)
	if QuestManager.publish(event): _owners[owner] = true
