extends Node

@export var npc_timeline: DialogicTimeline
@export var spells_to_grant: Array[SpellData] = []
## If true, also auto-equips all granted spells
@export var auto_equip: bool = false

func _ready() -> void:
	Player_Global_Data.p_moveable = false
	Dialogic.start(npc_timeline)
	await Dialogic.timeline_ended
	for spell in spells_to_grant:
		Player_Global_Data.add_spell(spell)
		if auto_equip:
			Player_Global_Data.equip_spell(spell)
	Player_Global_Data.p_moveable = true
