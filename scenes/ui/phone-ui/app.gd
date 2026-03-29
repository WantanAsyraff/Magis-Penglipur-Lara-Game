class_name App extends Control
signal app_pressed(app_scene: PackedScene)
@export var icon: Texture2D
@export var newApp: PackedScene
@export var fullscreen: bool = false
@onready var texture_rect = $TextureRect

func _ready():
	if icon:
		texture_rect.texture = icon
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()
	if event.is_action_pressed("ui_accept"):
		_on_clicked()

func _on_clicked():
	if newApp == null:
		print("Error: No app scene assigned to this icon!")
		return
	if fullscreen:
		Player_Global_Data.previous_scene = Player_Global_Data.current_scene
		Player_Global_Data.previous_position = Player_Manager.last_player_position
		SceneManager.change_scene(newApp)
	else:
		app_pressed.emit(newApp)
