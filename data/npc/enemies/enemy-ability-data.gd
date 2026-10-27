class_name EnemyAbilityData extends Resource
enum Kind { MELEE, SPELL }
enum Role { OFFENSE, DEFENSE, HEAL, SUMMON }
@export var ability_id: StringName = &""
@export var kind: Kind = Kind.SPELL
@export var role: Role = Role.OFFENSE
@export var spell: SpellData
@export var effects: Array[SpellEffectDefinition] = []
@export var min_range: float = 0
@export var max_range: float = 500
@export var requires_los: bool = true
@export var windup: float = 0.25
@export var recovery: float = 0.15
@export var cooldown: float = 1.2
@export var weight: float = 1
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ability_id == &"": errors.append("Empty ability ID")
	if kind < 0 or kind >= Kind.size() or role < 0 or role >= Role.size(): errors.append("Invalid ability category")
	for key in ["min_range", "max_range", "windup", "recovery", "cooldown", "weight"]:
		var value := float(get(key))
		if not is_finite(value) or value < 0: errors.append("Invalid ability value: " + key)
	if min_range > max_range: errors.append("Minimum range exceeds maximum")
	if kind == Kind.SPELL: errors.append_array(SpellValidator.validate(spell))
	else:
		if effects.is_empty(): errors.append("Melee requires effects")
		SpellValidator._validate_effects(effects, errors, [], 0)
	return errors
