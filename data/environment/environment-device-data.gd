class_name EnvironmentDeviceData extends Resource
enum Kind { SWITCH, FUSE, LIGHT, GATE, VALVE, PUMP, TANK, FAN, DRAIN, PLATE, RECEIVER, TURRET, BREAKABLE, RELAY, LEVER }
enum Logic { NONE, AND, OR }
enum PlateMode { HOLD, TOGGLE, ONE_SHOT, TIMED }
@export var device_name: String = "Mechanism"
@export var kind: Kind = Kind.SWITCH
@export var visual: EnvironmentVisualData
@export var rule: InteractionRule
@export var size: Vector2 = Vector2(80,80)
@export var interaction_radius: float = 200.0
@export var initial_enabled: bool = false
@export var initial_power: bool = true
@export var logic: Logic = Logic.NONE
@export var persistent: bool = false
@export var key_id: String = ""
@export var consume_key: bool = true
@export var activation_seconds: float = 0.0
@export var auto_close: float = 0.0
@export var max_health: float = 80.0
@export var respawn_seconds: float = 0.0
@export var capabilities: Array[StringName] = []
@export var loot: Array[LootData] = []
@export var capacity: float = 100.0
@export var initial_volume: float = 0.0
@export var flow_rate: float = 15.0
@export_range(0,1) var valve_opening: float = 1.0
@export var minimum_weight: float = 40.0
@export var player_weight: float = 70.0
@export var activation_delay: float = 0.15
@export var deactivation_delay: float = 0.15
@export var plate_mode: PlateMode = PlateMode.HOLD
@export var fan_speed: float = 6.0
@export var fan_acceleration: float = 6.0
@export var airflow: Vector2 = Vector2(100,-25)
@export var airflow_enabled: bool = false
@export var player_airflow: bool = false
@export var airflow_max_mass: float = 15.0
@export var turret_spell: SpellData
@export var attack_range: float = 800.0
@export var warning_seconds: float = 0.7
@export var firing_interval: float = 2.0
@export var outgoing_damage: float = 1.0
@export var training_nonlethal: bool = true
@export var destructible: bool = true
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if device_name.is_empty() or not size.is_finite() or size.x <= 0 or size.y <= 0: errors.append("Device needs a name and positive size")
	for value in [interaction_radius,activation_seconds,auto_close,max_health,respawn_seconds,capacity,initial_volume,flow_rate,minimum_weight,player_weight,activation_delay,deactivation_delay,fan_speed,fan_acceleration,airflow_max_mass,attack_range,warning_seconds,firing_interval,outgoing_damage]:
		if not is_finite(value) or value < 0: errors.append("Device numbers must be finite and nonnegative"); break
	if capacity <= 0 or max_health <= 0 or initial_volume > capacity: errors.append("Invalid capacity, volume or health")
	if kind == Kind.TURRET and (turret_spell == null or firing_interval < .1 or warning_seconds < .05): errors.append("Turret requires a spell and bounded firing/warning times")
	if kind == Kind.TURRET and turret_spell:
		errors.append_array(SpellValidator.validate(turret_spell))
		if LegacySpellAdapter.delivery_for(turret_spell) != SpellData.Delivery.PROJECTILE: errors.append("Turret requires projectile delivery")
		if training_nonlethal:
			for effect in LegacySpellAdapter.effects_for(turret_spell):
				if not (effect is DamageEffect or effect is KnockbackEffect or effect is VectorEffect): errors.append("Nonlethal training uses direct damage/impulse effects only")
	if not is_finite(valve_opening) or valve_opening < 0 or valve_opening > 1 or not airflow.is_finite(): errors.append("Invalid valve opening or airflow")
	if rule: errors.append_array(rule.validate())
	if visual: errors.append_array(visual.validate())
	return errors
