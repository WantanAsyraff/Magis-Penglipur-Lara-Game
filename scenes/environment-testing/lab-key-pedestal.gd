extends Node2D
func _ready() -> void:
	var label := Label.new(); label.name = "InteractLabel"; label.position = Vector2(-90,-50); add_child(label)
	var caption := Label.new(); caption.text = "Kunci / Key"; caption.position = Vector2(-45,20); add_child(caption)
	var detector := DetectionComponent.new(); detector.interaction_radius = 130; detector.interact_label_text = "Take practice key"; add_child(detector)
	detector.interacted.connect(func():
		var keys: Array = Player_Global_Data.get_meta("keys",[]).duplicate()
		if not keys.has("environment-lab-key"): keys.append("environment-lab-key")
		Player_Global_Data.set_meta("keys",keys))
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2(-10,0),12,Color.GOLD,false,4)
	draw_line(Vector2.ZERO,Vector2(35,0),Color.GOLD,4)
	draw_line(Vector2(30,0),Vector2(30,12),Color.GOLD,4)
