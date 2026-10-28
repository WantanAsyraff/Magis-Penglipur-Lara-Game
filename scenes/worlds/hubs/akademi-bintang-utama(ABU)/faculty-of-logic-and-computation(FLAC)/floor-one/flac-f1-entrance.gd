extends Node2D


func _ready() -> void:
	if SaveManager.loading: return
	begin_intro()

func begin_intro() -> void:
	Player_Global_Data.p_moveable = false
	Player_Global_Data.phone_visible = false
	
	Dialogic.start("after-final-paper")
	await Dialogic.timeline_ended
	
	Player_Global_Data.p_moveable = true
	Player_Global_Data.combat_mode = false
	Player_Global_Data.phone_visible = true
