class_name DestructibleHitbox extends HitboxComponent
var incoming: EnvironmentalDamage
func _ready() -> void:
	super._ready()
	get_parent().remove_from_group("combat_target")
	remove_from_group("enemy_hitbox")
func receive_spell_damage(raw_damage: float, context: SpellCastContext) -> void:
	incoming = EnvironmentalDamage.from_spell(context)
	super.receive_spell_damage(raw_damage, context)
	incoming = null
