class_name SpellData extends Resource

@export var spell_name: String
@export var spell_id: String

enum SpellType { OFFENSIVE, DEFENSIVE, SUPPORTIVE, AOE, HEALING, RECOVERY, ENCHANCEMENT, IMPAIRMENT, MOVEMENT}
@export var spell_type: SpellType

enum SpellManifest { MELEE, RANGED, PROTECTIVE, UTILITY, CONTROL, RESTORATIVE}
@export var spell_manifest: SpellManifest

@export var spell_incantation: Array[String] = ["", "", "", ""]

@export_enum ("Mana Manipulation", "Elementalist", "Technical", "Alnur", "Alzalam","Celestial")
var magis_archetype: String = "Mana Manipulation"

@export_enum("Novice", "Intermediate", "Advanced", "Expert")
var magis_comprehension = "Novice"

@export var upfront_cost: int
@export var cast_time: float

@export var projectile_particles: PackedScene
@export var impact_particles: PackedScene

@export var projectile_range: float
@export var projectile_size: float
@export var projectile_damage: float
@export var projectile_speed: float
@export var projectile_texture: Texture2D
@export var aoe_spell_radius: float
@export var dot: bool
@export var piercing: bool
@export var stunnable: bool
@export var stun_dur: float
@export var explosive: float

# Theory requirements
@export var subject_prerequisites: Array[subjectData]
@export var theory_desc: String
