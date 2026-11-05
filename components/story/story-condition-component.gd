@tool
class_name StoryConditionComponent extends Node
signal condition_changed(satisfied: bool)
signal conditions_became_satisfied
signal conditions_became_unsatisfied
@export var conditions: Array[StoryCondition] = []
@export var invert_result := false
@export var enabled := true
@export var evaluate_on_ready := true
@export var update_on_story_change := true
@export var update_on_quest_change := true
var _known := false
var _satisfied := false
var _queued := false
func _ready() -> void:
 if Engine.is_editor_hint(): return
 if update_on_story_change: StoryDirector.story_state_changed.connect(queue_refresh)
 if update_on_quest_change: QuestManager.quests_changed.connect(queue_refresh)
 Player_Global_Data.progression_changed.connect(queue_refresh)
 Player_Global_Data.spells_updated.connect(queue_refresh)
 Inventory_Manager.inventory_changed.connect(func(_item, _count): queue_refresh())
 SaveManager.restored.connect(queue_refresh)
 if evaluate_on_ready: queue_refresh()
func queue_refresh() -> void:
 if _queued or not is_inside_tree(): return
 _queued = true
 call_deferred("refresh")
func refresh() -> bool:
 _queued = false
 var value := enabled and StoryDirector.is_ready() and not conditions.is_empty()
 if value:
  for condition in conditions:
   if condition == null or not StoryDirector.evaluate_condition(condition): value = false; break
 if enabled and StoryDirector.is_ready() and not conditions.is_empty() and invert_result: value = not value
 if not _known or value != _satisfied:
  _known = true
  _satisfied = value
  condition_changed.emit(value)
  if value: conditions_became_satisfied.emit()
  else: conditions_became_unsatisfied.emit()
 return value
func is_satisfied() -> bool: return refresh()
func get_diagnostics() -> Dictionary:
 return {"node": str(get_path()), "satisfied": _satisfied, "conditions": conditions.size(), "valid": not conditions.is_empty() and conditions.all(func(condition: StoryCondition): return condition != null and StoryConditionEvaluator.validate_graph(condition, StoryDirector.registry))}
func _get_configuration_warnings() -> PackedStringArray:
 var warnings := PackedStringArray()
 if conditions.is_empty(): warnings.append("Assign at least one StoryCondition Resource.")
 elif StoryDirector.registry != null:
  for condition in conditions:
   if condition == null or not StoryConditionEvaluator.validate_graph(condition, StoryDirector.registry): warnings.append("Invalid StoryCondition Resource on " + str(get_path()))
 return warnings
