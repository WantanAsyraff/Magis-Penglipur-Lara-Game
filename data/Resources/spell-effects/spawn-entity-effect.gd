class_name SpawnEntityEffect extends SpellEffectDefinition
@export var scene: PackedScene
@export var offset: Vector2 = Vector2.ZERO
@export var children: Array[SpellEffectDefinition] = []

func validate() -> PackedStringArray:
	return PackedStringArray(["Spawn effect requires a scene and finite offset"]) if scene == null or not offset.is_finite() else PackedStringArray()
func accepts(target: Node2D) -> bool:
	return is_instance_valid(target)
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var entity := scene.instantiate() as Node2D
	if entity == null:
		return false
	context.caster.get_parent().add_child(entity)
	entity.global_position = target.global_position + offset
	if not children.is_empty():
		SpellExecutor.execute_effects(context, entity, children)
	if entity.has_method("initialize_spell"):
		entity.initialize_spell(context)
	return true
