extends Control

@onready var dashes = %Dashes
@onready var current_world_label: Label = %CurrentWorldLabel
const DASH_ICON = preload("res://assets/icons/dash-icon.png")

func _ready() -> void:
	if Player_Global_Data == null:
		push_error("Player_Global_Data is not loaded!")
		return

	Player_Global_Data.dash_charges_changed.connect(_on_dash_charges_changed)
	Player_Global_Data.world_changed.connect(_on_world_changed)

	_build_dash_display(Player_Global_Data.MAX_DASH_CHARGES)
	_on_dash_charges_changed(Player_Global_Data.current_dash_charges)
	_on_world_changed(Player_Global_Data.current_world)

func _on_world_changed(world_name: String) -> void:
	if current_world_label:
		current_world_label.text = world_name

func _build_dash_display(max_charges: int) -> void:
	for child in dashes.get_children():
		child.queue_free()
	for i in max_charges:
		var icon = TextureRect.new()
		icon.texture = DASH_ICON
		icon.custom_minimum_size = Vector2(DASH_ICON.get_width(), DASH_ICON.get_height())
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dashes.add_child(icon)

func _on_dash_charges_changed(current_charges: int) -> void:
	for i in dashes.get_child_count():
		var icon = dashes.get_child(i)
		icon.modulate.a = 1.0 if i < current_charges else 0.3
