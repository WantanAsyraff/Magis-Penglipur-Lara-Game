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

func _process(_delta: float) -> void:
	var actor := Player_Manager.get_local_player() as Player
	if is_instance_valid(actor):
		if dashes.get_child_count() != actor.get_max_dash_charges():
			_build_dash_display(actor.get_max_dash_charges())
		UserInterface.update_dash_display(dashes, actor.dash_charges, actor.dash_regen_timer / maxf(actor.DASH_COOLDOWN, 0.001))

func _build_dash_display(max_charges: int) -> void:
	UserInterface.build_dash_display(dashes, max_charges)

func _on_dash_charges_changed(current_charges: int) -> void:
	UserInterface.update_dash_display(dashes, current_charges, 0.0)
