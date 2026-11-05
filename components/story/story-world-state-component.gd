@tool
class_name StoryWorldStateComponent extends Node
@export var condition_component: StoryConditionComponent
@export var visual_target: CanvasItem
@export var visual_when_satisfied := true
@export var interaction_target: Node
@export var actuator: InteractionActuator
@export var actuator_port: EnvironmentLink.Port = EnvironmentLink.Port.ENABLE
@export var respect_persistent_device_state := true
@export var animation_player: AnimationPlayer
@export var animation_when_satisfied: StringName
@export var animation_when_unsatisfied: StringName
func _ready() -> void:
 if Engine.is_editor_hint(): return
 if condition_component == null: condition_component = get_parent().find_child("StoryConditionComponent", true, false)
 if condition_component:
  condition_component.condition_changed.connect(refresh)
  SaveManager.restored.connect(_after_restore)
  refresh(condition_component.is_satisfied())
func _after_restore() -> void:
 if condition_component: call_deferred("_refresh_after_restore")
func _refresh_after_restore() -> void:
 if condition_component: refresh(condition_component.is_satisfied())
func refresh(satisfied: bool) -> void:
 if SaveManager.loading: return
 if visual_target: visual_target.visible = satisfied == visual_when_satisfied
 if interaction_target: interaction_target.process_mode = Node.PROCESS_MODE_INHERIT if satisfied else Node.PROCESS_MODE_DISABLED
 if actuator:
  var device := actuator.get_parent() as EnvironmentDevice
  var saved_override := respect_persistent_device_state and device != null and device.data != null and device.data.persistent and (WorldPersistence.has_state(device, "broken") or WorldPersistence.has_state(device, "activated"))
  if not saved_override: actuator.receive(satisfied, actuator_port, self)
 var animation := animation_when_satisfied if satisfied else animation_when_unsatisfied
 if animation_player and not animation.is_empty() and animation_player.has_animation(animation) and animation_player.current_animation != animation: animation_player.play(animation)
