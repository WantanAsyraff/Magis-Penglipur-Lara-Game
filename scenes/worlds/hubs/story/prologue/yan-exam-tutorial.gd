extends Node2D

# Progress of the game's tutorial here

func _ready() -> void:
	if SaveManager.loading: return
	begin_intro()

func begin_intro() -> void:
	Player_Global_Data.p_moveable = false
	Player_Global_Data.phone_visible = false
	
	Dialogic.start("spm-school-entrance")
	await Dialogic.timeline_ended
	
	Player_Global_Data.p_moveable = true
	Player_Global_Data.combat_mode = true
	Player_Global_Data.add_spell(preload("res://data/magis/spells/thermal-kinetic.tres"))
	Player_Global_Data.equip_spell(preload("res://data/magis/spells/thermal-kinetic.tres"))
