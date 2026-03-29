class_name RoutePanel extends PanelContainer

@export var destinations: Array[SceneData] = []
@export var completion_signal_name: String = "route_selected"

var current_index: int = 0

func _ready() -> void:
	_update_label()

func _on_button_pressed() -> void:
	_travel_to(destinations[current_index])
	Player_Global_Data.p_moveable = true

func _on_prev_button_pressed() -> void:
	current_index = wrapi(current_index - 1, 0, destinations.size())
	_update_label()

func _on_next_button_pressed() -> void:
	current_index = wrapi(current_index + 1, 0, destinations.size())
	_update_label()

func _update_label() -> void:
	if destinations.is_empty():
		%LocationLabel.text = "No destinations"
		return
	%LocationLabel.text = destinations[current_index].scene_name

func _travel_to(scene_data: SceneData) -> void:
	if not scene_data:
		push_error("RoutePanel: Invalid SceneData!")
		return
	Player_Global_Data.custom_signal_emitted.emit(completion_signal_name)
	SceneManager.change_scene(scene_data.scene.resource_path)
