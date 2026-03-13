class_name SpellData extends Resource

# ─────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────
@export_group("Identity")
## Display name.
@export var spell_name: String = ""
## For internal index searching.
@export var spell_id: String = ""
## Display preview, example: spell tree
@export var spell_icon: Texture2D
@export var spell_colour: Color = Color.WHITE
@export_multiline var spell_flavour_text: String = ""
@export_multiline var theory_desc: String = ""

# ─────────────────────────────────────────
# CLASSIFICATION
# ─────────────────────────────────────────
@export_group("Classification")

enum SpellType {
	OFFENSIVE,
	DEFENSIVE,
	SUPPORTIVE,
	AOE,
	HEALING,
	RECOVERY,
	ENHANCEMENT,
	IMPAIRMENT,
	MOVEMENT
}
@export var spell_type: SpellType

enum SpellManifest {
	MELEE,
	RANGED,
	PROTECTIVE,
	UTILITY,
	CONTROL,
	RESTORATIVE
}
@export var spell_manifest: SpellManifest

@export_enum("Mana Manipulation", "Ilmiah", "Alnur", "Alzalam", "Semesta")
var magis_archetype: String = "Mana Manipulation"

@export_enum("Novice", "Intermediate", "Advanced", "Expert")
var magis_comprehension: String = "Novice"

# ─────────────────────────────────────────
# INCANTATION
# ─────────────────────────────────────────
@export_group("Incantation")
@export var spell_incantation: Array[String] = []

# ─────────────────────────────────────────
# MANA
# ─────────────────────────────────────────
@export_group("Mana")
@export var upfront_cost: int = 0
@export var mana_per_second: float = 0.0
@export var cast_time: float = 0.0
@export var is_channelled: bool = false
@export var channel_duration: float = 0.0

# ─────────────────────────────────────────
# PROJECTILE
# ─────────────────────────────────────────
@export_group("Projectile")
@export var spell_scene: PackedScene
@export var projectile_texture: Texture2D
@export var projectile_particles: PackedScene
@export var impact_particles: PackedScene
@export var cast_sound: AudioStream
@export var impact_sound: AudioStream
@export var projectile_range: float = 0.0
@export var projectile_size: float = 0.0
@export var projectile_damage: float = 0.0
@export var projectile_speed: float = 0.0
@export var projectile_count: int = 1
@export var projectile_spread: float = 0.0
@export var piercing: bool = false
## Used for heals and self-applications.
@export var is_self_cast: bool = false

# ─────────────────────────────────────────
# AOE
# ─────────────────────────────────────────
@export_group("AOE")
@export var aoe_spell_radius: float = 0.0
@export var explosive: float = 0.0
@export var knockback_force: float = 0.0

# ─────────────────────────────────────────
# STATUS EFFECTS
# ─────────────────────────────────────────
@export_group("Status Effects")

@export var stunnable: bool = false
@export var stun_dur: float = 0.0

@export var dot: bool = false
@export var dot_damage: float = 0.0
@export var dot_interval: float = 0.5
@export var dot_duration: float = 0.0

@export var applies_slow: bool = false
@export var slow_factor: float = 0.0
@export var slow_duration: float = 0.0

@export var applies_mana_drain: bool = false
@export var mana_drain_amount: float = 0.0
@export var mana_drain_duration: float = 0.0

@export var applies_silence: bool = false
@export var silence_duration: float = 0.0

# Future-proofing hook — leave empty until StatusEffectManager is built
@export var status_effects: Array[Resource] = []
