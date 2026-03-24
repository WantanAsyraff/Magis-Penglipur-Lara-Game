extends Control
@onready var temp_goal_label: Label = %TempGoalLabel
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
	
	Player_Global_Data.goals_changed.connect(_on_goals_changed)
	_on_goals_changed(Player_Global_Data.active_goals)

func _on_goals_changed(goals: Array[String]) -> void:
	print("[HUD] goals_changed fired — %d goal(s): %s" % [goals.size(), str(goals)])
	if temp_goal_label:
		temp_goal_label.text = "\n".join(goals) if goals.size() > 0 else ""
	else:
		print("[HUD] temp_goal_label is NULL")
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
