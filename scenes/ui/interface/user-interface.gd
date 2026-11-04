class_name UserInterface extends Control

@onready var health = %HealthLabel
@onready var mana = %ManaLabel
@onready var health_bar = %HealthProgressBar
@onready var mana_bar = %ManaProgressBar
@onready var dashes = %Dashes  # HBoxContainer

const DASH_ICON = preload("res://assets/icons/dash-icon.png")

func _ready() -> void:
	if Player_Global_Data == null:
		push_error("Player_Global_Data is not loaded!")
		return
	
	# Connect signals
	Player_Global_Data.mana_changed.connect(_on_mana_changed)
	Player_Global_Data.health_changed.connect(_on_health_changed)
	Player_Global_Data.dash_charges_changed.connect(_on_dash_charges_changed)
	
	# Set initial values
	_on_mana_changed(Player_Global_Data.p_curr_mana)
	_on_health_changed(Player_Global_Data.p_curr_health)
	_build_dash_display(Player_Global_Data.MAX_DASH_CHARGES)
	_on_dash_charges_changed(Player_Global_Data.current_dash_charges)

func _process(_delta: float) -> void:
	var actor := Player_Manager.get_local_player() as Player
	if is_instance_valid(actor):
		if dashes.get_child_count() != actor.get_max_dash_charges():
			_build_dash_display(actor.get_max_dash_charges())
		update_dash_display(dashes, actor.dash_charges, actor.dash_regen_timer / maxf(actor.DASH_COOLDOWN, 0.001))

func _build_dash_display(max_charges: int) -> void:
	build_dash_display(dashes, max_charges)

func _on_dash_charges_changed(current_charges: int) -> void:
	update_dash_display(dashes, current_charges, 0.0)

static func build_dash_display(row: HBoxContainer, max_charges: int) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for i in max_charges:
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 5)
		row.add_child(column)
		var icon := TextureRect.new()
		icon.texture = DASH_ICON
		icon.custom_minimum_size = Vector2(DASH_ICON.get_width(), DASH_ICON.get_height())
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		column.add_child(icon)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 6)
		bar.show_percentage = false
		style_cooldown_bar(bar)
		bar.max_value = 1.0
		column.add_child(bar)

static func update_dash_display(row: HBoxContainer, charges: int, progress: float) -> void:
	for i in row.get_child_count():
		var column := row.get_child(i)
		column.get_child(0).modulate.a = 1.0 if i < charges else 0.3
		column.get_child(1).value = 1.0 if i < charges else (clampf(progress, 0.0, 1.0) if i == charges else 0.0)

func _on_mana_changed(new_value: int) -> void:
	mana.text = "Mana"
	mana_bar.max_value = Player_Global_Data.p_max_mana
	mana_bar.value = new_value

func _on_health_changed(new_value: int) -> void:
	health.text = "Health"
	health_bar.max_value = Player_Global_Data.p_max_health
	health_bar.value = new_value

static func style_cooldown_bar(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1b2938")
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("72cbd7")
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
