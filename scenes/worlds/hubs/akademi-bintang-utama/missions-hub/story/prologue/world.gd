extends Node

@export var spells_to_grant: Array[SpellData] = []
## If true, also auto-equips all granted spells
@export var auto_equip: bool = false

func _ready() -> void:
	for spell in spells_to_grant:
		Player_Global_Data.add_spell(spell)
		if auto_equip:
			Player_Global_Data.equip_spell(spell)
