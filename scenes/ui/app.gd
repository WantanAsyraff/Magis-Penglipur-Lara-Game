class_name App extends Control

# Signal to tell the Phone logic to open this specific app
signal app_pressed(scene_path: String)

@export var icon : Texture2D # Use Texture2D for UI elements
@export_file("*.tscn") var app_scene_path : String

@onready var texture_rect = $TextureRect # Adjust path to your TextureRect node

func _ready():
	if icon:
		texture_rect.texture = icon
	
	# If using a Button node as the root, or a Button overlay:
	# $Button.pressed.connect(_on_clicked)

# This function triggers when the user clicks the app icon
func _on_clicked():
	if app_scene_path != "":
		app_pressed.emit(app_scene_path)
