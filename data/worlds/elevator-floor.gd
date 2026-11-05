# ElevatorFloor.gd
# A small Resource that describes one selectable floor in an ElevatorPortal.
# Create these as .tres files or inline in the ElevatorPortal inspector.
class_name ElevatorFloor
extends Resource

@export var floor_name: String = ""
@export var scene_id: String = ""
@export var spawn_marker_override: String = ""
# If true, the floor button is shown but greyed out with a lock icon.
# Tie this to Player_Global_Data course checks at runtime if needed.
@export var locked: bool = false
@export var locked_hint: String = "Access restricted"

@export_group("Story Gate")
@export var story_conditions: Array[StoryCondition] = []
func is_accessible() -> bool:
	if locked: return false
	return story_allows()
func story_allows() -> bool:
	if story_conditions.is_empty(): return true
	if not StoryDirector.is_ready() or SaveManager.loading: return false
	for condition in story_conditions:
		if condition == null or not StoryDirector.evaluate_condition(condition): return false
	return true
