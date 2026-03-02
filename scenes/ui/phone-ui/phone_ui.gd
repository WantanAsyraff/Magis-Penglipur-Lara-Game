extends Control

@onready var app_list = %AppList   
@onready var screen = %Screen      

@export var phone_selected : bool = false
@export var up_pos : Vector2 = Vector2(1388.0, 450)
@export var down_pos : Vector2 = Vector2(1388.0, 1000.0)

var current_app_node : Control = null

func _ready():
	# Start the phone in the "down" position
	position = down_pos
	
	# Connect signals from all app icons inside the Panel
	for child in app_list.get_children():
		if child is App:
			child.app_pressed.connect(_on_app_opened)

func _input(event):
	# Toggle phone visibility
	if event.is_action_pressed("open_phone"):
		phone_selected = !phone_selected
		_animate_phone()
	
	# Global Back logic (Keyboard Esc / Right Click)
	if event.is_action_pressed("ui_cancel") and phone_selected:
		if current_app_node:
			_close_current_app()
		else:
			phone_selected = false
			_animate_phone()

func _animate_phone():
	var target_pos = up_pos if phone_selected else down_pos
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.5)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)

func _on_app_opened(app_resource: PackedScene):
	if current_app_node: 
		return 
	
	# 1. Instantiate the app
	current_app_node = app_resource.instantiate()
	
	# 2. Add to screen
	%Screen.add_child(current_app_node)
	
	# 3. FORCE VISIBILITY AND SIZE (Fixes the "invisible app" bug)
	current_app_node.visible = true
	# This forces the app to fill the screen container regardless of scene settings
	current_app_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	%Screen.visible = true
	
	# 4. Connect the App's internal back button signal if it exists
	if current_app_node.has_signal("back_pressed"):
		current_app_node.back_pressed.connect(_close_current_app)

	# 5. Hide the main app icons
	%AppList.visible = false
	
	print("App opened: ", current_app_node.name)

func _close_current_app():
	if current_app_node:
		# Safely delete the app node
		current_app_node.queue_free()
		current_app_node = null
		
		# Show the icons again
		app_list.visible = true
		
		# Return focus to the icons for controller navigation
		if app_list.get_child_count() > 0:
			var first_icon = app_list.get_child(0)
			if first_icon is Control:
				first_icon.grab_focus()
