extends Control


@onready var app_list = %AppList   
@onready var screen = %PhoneBG

@export var phone_selected: bool = false
@export var up_pos: Vector2 = Vector2(1388.0, 450)
@export var down_pos: Vector2 = Vector2(1388.0, 1000.0)

var current_app_node: Control = null

func _ready():
	add_to_group("phone_ui")
	if Player_Global_Data.phone_visible:
		$".".visible = true
		print("Phone enabled")
		print("AppList node: ", app_list)
		print("Screen node: ", screen)
		position = down_pos
		for child in app_list.get_children():
			if child is App:
				child.app_pressed.connect(_on_app_opened)
	else:
		$".".visible = false
		print("Phone disabled")

func _unhandled_input(event):
	if QuestOfferDialog.is_open() or Dialogic.current_timeline != null: return
	if event.is_action_pressed("open_phone"):
		phone_selected = !phone_selected
		_animate_phone()
		get_viewport().set_input_as_handled()
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
	if QuestOfferDialog.is_open() or Dialogic.current_timeline != null: return
	if current_app_node:
		return


	current_app_node = app_resource.instantiate()
	%PhoneBG.add_child(current_app_node)
	current_app_node.visible = true
	current_app_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	%PhoneBG.visible = true
	if current_app_node.has_signal("back_pressed"):
		current_app_node.back_pressed.connect(_close_current_app)
	%AppList.visible = false
	print("App opened: ", current_app_node.name)

func _close_current_app():
	if current_app_node:
		current_app_node.queue_free()
		current_app_node = null
		app_list.visible = true
		if app_list.get_child_count() > 0:
			var first_icon = app_list.get_child(0)
			if first_icon is Control:
				first_icon.grab_focus()
