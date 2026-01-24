class_name RoutePanel extends PanelContainer

@export var destination_scene : PackedScene
@export var completion_signal_name : String = "route_selected"

func _on_button_pressed() -> void:
	# 1. Logic to handle scene specific data if needed
	print("Route selected: ", completion_signal_name)
	
	# 2. Emit the signal through a global bus so the Sequence Manager hears it
	# We pass the signal_name as a parameter so the manager knows which one finished
	Player_Global_Data.custom_signal_emitted.emit(completion_signal_name)
	print("emitted", completion_signal_name)
	# Optional: If the button should also change the scene immediately:
	SceneManager.change_scene(destination_scene.resource_path)
