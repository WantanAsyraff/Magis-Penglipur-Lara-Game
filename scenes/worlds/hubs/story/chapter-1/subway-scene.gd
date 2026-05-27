extends Node2D

# Progress of the game's tutorial here

func _ready() -> void:
	Player_Global_Data.p_moveable = false
	Player_Global_Data.phone_visible = false
	
	Dialogic.start("after-final-paper")
	await Dialogic.timeline_ended
	
	Player_Global_Data.p_moveable = true
	Player_Global_Data.combat_mode = false
