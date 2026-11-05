class_name SpawnSceneBehavior extends DestructionBehavior
enum ParentPolicy { WORLD_MANAGER, SOURCE_PARENT }
@export var scene: PackedScene
@export var spawn_offset := Vector2.ZERO
@export_range(-360, 360) var rotation_degrees := 0.0
@export var visual_scale := Vector2.ONE
@export var parent_policy: ParentPolicy = ParentPolicy.WORLD_MANAGER
@export_range(0.05, 300) var lifetime := 15.0
func validate() -> PackedStringArray:
	var errors := super.validate()
	if scene == null or not spawn_offset.is_finite() or not visual_scale.is_finite() or visual_scale.x <= 0 or visual_scale.y <= 0 or not is_finite(rotation_degrees) or not is_finite(lifetime) or lifetime <= 0 or lifetime > 300: errors.append("Scene spawning needs a scene, finite transform and bounded lifetime")
	return errors
func execute(context: DestructionContext) -> void:
	var node := scene.instantiate()
	if not node is Node2D: node.free(); push_warning("Destruction replacement scene must be Node2D"); return
	node.rotation_degrees = rotation_degrees; node.scale = visual_scale
	node.set_meta("destruction_parent_context", context)
	var parent: Node = null
	var source := context.source_object()
	if parent_policy == ParentPolicy.SOURCE_PARENT and is_instance_valid(source): parent = source.get_parent()
	context.runtime.spawn_node(node, context, context.position + spawn_offset, lifetime, parent)
