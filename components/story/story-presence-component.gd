@tool
class_name StoryPresenceComponent extends Node
@export var condition_component: StoryConditionComponent
@export var actor: Node2D
@export var hide_when_unsatisfied := true
@export var disable_interaction_when_unsatisfied := true
@export var pause_ai_when_unsatisfied := true
var _pending: bool
var _collision_defaults: Dictionary = {}
var _original_visible := true
var _original_detection_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _original_wander_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
func _ready() -> void:
 if Engine.is_editor_hint(): return
 if condition_component == null: condition_component = get_parent().find_child("StoryConditionComponent", true, false)
 if actor == null: actor = get_parent() as Node2D
 if actor:
  _original_visible = actor.visible
  for shape in actor.find_children("*", "CollisionShape2D", true, false): _collision_defaults[shape.get_instance_id()] = not shape.disabled
  var original_detection := actor.find_child("DetectionComponent", true, false)
  if original_detection: _original_detection_mode = original_detection.process_mode
  var original_wander := actor.find_child("WanderComponent", true, false)
  if original_wander: _original_wander_mode = original_wander.process_mode
 if condition_component:
  condition_component.condition_changed.connect(_apply_or_defer)
  _apply_or_defer(condition_component.is_satisfied())
func _apply_or_defer(present: bool) -> void:
 if actor == null: return
 var dialogue := actor.find_child("DialogicComponent", true, false) as DialogicComponent
 if dialogue != null and dialogue.is_open():
  _pending = present
  if not dialogue.dialogue_ended.is_connected(_after_dialogue): dialogue.dialogue_ended.connect(_after_dialogue, CONNECT_ONE_SHOT)
  return
 _apply(present)
func _after_dialogue() -> void: _apply(_pending)
func _apply(present: bool) -> void:
 actor.visible = _original_visible if present or not hide_when_unsatisfied else false
 for shape in actor.find_children("*", "CollisionShape2D", true, false):
  if _collision_defaults.has(shape.get_instance_id()): shape.set_deferred("disabled", not present or not _collision_defaults[shape.get_instance_id()])
 var detection := actor.find_child("DetectionComponent", true, false) as DetectionComponent
 if detection and disable_interaction_when_unsatisfied: detection.process_mode = _original_detection_mode if present else Node.PROCESS_MODE_DISABLED
 var wander := actor.find_child("WanderComponent", true, false)
 if wander and pause_ai_when_unsatisfied: wander.process_mode = _original_wander_mode if present else Node.PROCESS_MODE_DISABLED
 var quest := actor.find_child("QuestNPCComponent", true, false) as QuestNPCComponent
 if quest and quest.quest_indicator: quest.quest_indicator.visible = present
func _get_configuration_warnings() -> PackedStringArray:
 return PackedStringArray(["Assign a StoryConditionComponent."]) if condition_component == null else PackedStringArray()
