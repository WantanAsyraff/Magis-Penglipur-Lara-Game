class_name StatusPresentation extends RefCounted
# Original line glyphs are drawn by StatusEffectIcon. Extend this table for new effects.
const DEFINITIONS := {
	"buff_speed": ["Speed boost", "Move faster", "speed", 10],
	"buff_damage": ["Damage boost", "Increased spell damage", "damage", 10],
	"buff_defense": ["Defense boost", "Reduced incoming damage", "shield", 10],
	"buff_mana_regen": ["Mana regeneration", "Recover mana faster", "mana", 10],
	"buff_cast_speed": ["Cast speed boost", "Prepare spells faster", "speed", 10],
	"buff_dash_charges": ["Dash charges", "Additional dash capacity", "speed", 10],
	"hot": ["Healing over time", "Periodically restores health", "heal", 10],
	"slow": ["Slow", "Reduced movement speed", "slow", 2],
	"stun": ["Stun", "Movement and casting blocked", "stun", 0],
	"silence": ["Silence", "Casting blocked", "silence", 1],
	"dot": ["Damage over time", "Periodically loses health", "damage", 1],
	"mana_drain": ["Mana drain", "Periodically loses mana", "mana", 2],
}
static func describe(key: String) -> Array:
	return DEFINITIONS.get(key, [key.replace("_", " ").capitalize(), "Active status effect", "unknown", 5])
