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
