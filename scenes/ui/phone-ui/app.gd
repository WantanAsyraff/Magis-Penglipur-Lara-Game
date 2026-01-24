class_name App extends Control

# Signal sends the actual PackedScene to the phone manager
signal app_pressed(app_scene: PackedScene)

@export var icon : Texture2D 
@export var newApp: PackedScene # Drag your app .tscn file here in the Inspector

@onready var texture_rect = $TextureRect 

func _ready():
	if icon:
		texture_rect.texture = icon
	
	# Makes the mouse cursor a hand when hovering
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event):
	# Detect mouse click
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()
	
	# Detect controller/keyboard "Accept" (Enter/Space/A Button)
	if event.is_action_pressed("ui_accept"):
		_on_clicked()

func _on_clicked():
	if newApp != null:
		app_pressed.emit(newApp)
	else:
		print("Error: No app scene assigned to this icon!")
