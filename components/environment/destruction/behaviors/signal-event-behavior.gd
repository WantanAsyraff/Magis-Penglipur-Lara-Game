class_name SignalEventBehavior extends DestructionBehavior
enum Action { SIGNAL_ONLY, WORLD_FLAG, ACTUATOR_ENABLE, RECEIVER_SIGNAL }
@export var action: Action = Action.SIGNAL_ONLY
@export var event_id: StringName = &"broken"
@export var target_path: NodePath
@export var world_flag := ""
@export var value := true
func validate() -> PackedStringArray:
	var errors := super.validate()
	if event_id == &"": errors.append("Signal behavior needs an event ID")
	if action == Action.WORLD_FLAG and (world_flag.is_empty() or world_flag.length() > 128): errors.append("World flag action requires a stable flag")
	if action in [Action.ACTUATOR_ENABLE, Action.RECEIVER_SIGNAL] and target_path.is_empty(): errors.append("Typed target action needs a NodePath")
	return errors
func execute(context: DestructionContext) -> void:
	var source := context.source_object()
	if not is_instance_valid(source): return
	var component := source.get_node("DestructibleComponent") as DestructibleComponent
	component.authored_event.emit(event_id, context)
	if not is_instance_valid(source) or source.is_queued_for_deletion(): return
	match action:
		Action.WORLD_FLAG: QuestManager.set_world_flag(world_flag, value)
		Action.ACTUATOR_ENABLE:
			var target := source.get_node_or_null(target_path) as InteractionActuator
			if target: target.receive(value, EnvironmentLink.Port.ENABLE)
			else: push_warning("Destruction event target must be InteractionActuator")
		Action.RECEIVER_SIGNAL:
			var target := source.get_node_or_null(target_path) as InteractionReceiver
			if target: target.receive_event(InteractionRule.Event.SIGNAL)
			else: push_warning("Destruction event target must be InteractionReceiver")
