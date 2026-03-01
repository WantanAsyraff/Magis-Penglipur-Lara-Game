class_name NPCSpellcasterData extends Resource

# ─────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────
@export var caster_name: String
@export var caster_id: String
@export_enum("Kocheen", "Ancheen", "Moshang", "Sarigala", "Baruang", "Arnobs")
var race: String = "Kocheen"
@export_enum("Mana Manipulation", "Technical", "Alnur", "Alzalam", "Celestial")
var magis_archetype: String = "Mana Manipulation"
@export_enum("Novice", "Intermediate", "Advanced", "Expert")
var magis_comprehension: String = "Novice"
@export var portrait: Texture2D

# ─────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────
@export var max_hp: float = 100.0
@export var hp_regen_rate: float = 0.0          # per second (0 = no passive regen)
@export var base_defense: float = 0.0           # flat damage reduction
@export var base_mana_shield: float = 0.0       # mana consumed before HP is hit

# ─────────────────────────────────────────
# MANA
# ─────────────────────────────────────────
@export var max_mana: float = 100.0
@export var mana_regen_rate: float = 5.0        # per second
@export var mana_regen_delay: float = 2.0       # seconds after casting before regen kicks in
@export var low_mana_threshold: float = 0.25    # fraction of max_mana to trigger RECOVERING

# ─────────────────────────────────────────
# SPELL POOL
# ─────────────────────────────────────────
@export var spell_pool: Array[SpellData] = []
@export var preferred_spell_types: Array[String] = []   # e.g. ["OFFENSIVE", "IMPAIRMENT"]
@export var forbidden_spell_types: Array[String] = []   # NPC will never pick these

# ─────────────────────────────────────────
# MOVEMENT & POSITIONING
# ─────────────────────────────────────────
@export var move_speed: float = 120.0
@export var preferred_range: float = 250.0      # distance NPC tries to maintain from player
@export var too_close_threshold: float = 80.0   # triggers a backstep or dodge

# ─────────────────────────────────────────
# COMBAT BEHAVIOUR
# ─────────────────────────────────────────
@export var aggression: float = 0.5             # 0 = passive, 1 = relentless
@export var react_window: float = 0.4           # seconds to react to player action
@export var cast_delay_min: float = 0.3         # min pause before casting (feels deliberate)
@export var cast_delay_max: float = 1.2         # max pause (harder = lower gap)
@export var combo_chance: float = 0.0           # chance to chain a second spell immediately
@export var counter_chance: float = 0.0         # chance to counter player's spell archetype

# ─────────────────────────────────────────
# STATUS RESISTANCES
# ─────────────────────────────────────────
@export var stun_resistance: float = 0.0        # 0 = fully stunable, 1 = immune
@export var dot_resistance: float = 0.0
@export var impairment_resistance: float = 0.0

# ─────────────────────────────────────────
# LOOT / PROGRESSION (post-combat)
# ─────────────────────────────────────────
@export var drops_spell_on_defeat: bool = false
@export var dropped_spell: SpellData
@export var exp_reward: int = 0
