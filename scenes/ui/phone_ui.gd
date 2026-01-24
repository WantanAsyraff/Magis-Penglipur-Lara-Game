extends Control

@onready var app_list = %AppList   
@onready var screen = %Screen      

@export var phone_selected : bool = false
@export var up_pos : Vector2 = Vector2(900, 450)
@export var down_pos : Vector2 = Vector2(900, 1100)

var current_app_node : Control = null

func _ready():
	# Position the phone down at the start
	position = down_pos
	
	# Connect apps in the list
	for child in app_list.get_children():
		if child.has_signal("app_pressed"):
			child.app_pressed.connect(_on_app_opened)

func _input(event):
	if event.is_action_pressed("open_phone"):
		phone_selected = !phone_selected
		_animate_phone() # This calls the function below
	
	if event.is_action_pressed("ui_cancel") and phone_selected:
		if current_app_node:
			_close_current_app()
		else:
			phone_selected = false
			_animate_phone()

# --- THE FUNCTION MUST START HERE (No Indent) ---
func _animate_phone():
	var target_pos = up_pos if phone_selected else down_pos
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.5)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)

func _on_app_opened(app_scene_path: String):
	if current_app_node: return # Don't open an app if one is already open
	
	var app_scene = load(app_scene_path)
	current_app_node = app_scene.instantiate()
	
	screen.add_child(current_app_node)
	app_list.visible = false

func _close_current_app():
	if current_app_node:
		current_app_node.queue_free()
		current_app_node = null
		app_list.visible = true
