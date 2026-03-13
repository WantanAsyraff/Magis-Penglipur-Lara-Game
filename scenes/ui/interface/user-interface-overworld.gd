extends Control


@onready var dashes = %Dashes  # HBoxContainer

const DASH_ICON = preload("res://assets/icons/dash-icon.png")

func _ready() -> void:
	if Player_Global_Data == null:
		push_error("Player_Global_Data is not loaded!")
		return
	
	# Connect signals
	Player_Global_Data.dash_charges_changed.connect(_on_dash_charges_changed)
	
	# Set initial values
	_build_dash_display(Player_Global_Data.MAX_DASH_CHARGES)
	_on_dash_charges_changed(Player_Global_Data.current_dash_charges)

func _build_dash_display(max_charges: int) -> void:
	# Clear any existing icons
	for child in dashes.get_children():
		child.queue_free()
	
	# Spawn one TextureRect per max charge
	for i in max_charges:
		var icon = TextureRect.new()
		icon.texture = DASH_ICON
		icon.custom_minimum_size = Vector2(DASH_ICON.get_width(), DASH_ICON.get_height()) * 1
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dashes.add_child(icon)

func _on_dash_charges_changed(current_charges: int) -> void:
	# Dim icons that represent spent charges
	for i in dashes.get_child_count():
		var icon = dashes.get_child(i)
		icon.modulate.a = 1.0 if i < current_charges else 0.3
