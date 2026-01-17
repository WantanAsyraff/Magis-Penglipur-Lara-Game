class_name UserInterface extends Control

@onready var health = %HealthLabel
@onready var mana = %ManaLabel

func _ready() -> void:
	if Player_Global_Data == null:
		push_error("Player_Global_Data is not loaded!")
		return
	
	# Connect signals
	Player_Global_Data.mana_changed.connect(_on_mana_changed)
	Player_Global_Data.health_changed.connect(_on_health_changed)
	
	# Set initial values
	_on_mana_changed(Player_Global_Data.p_curr_mana)
	_on_health_changed(Player_Global_Data.p_curr_health)

func _on_mana_changed(new_value: int) -> void:
	mana.text = "Mana: " + str(new_value) + "/" + str(Player_Global_Data.p_max_mana)

func _on_health_changed(new_value: int) -> void:
	health.text = "Health: " + str(new_value) + "/" + str(Player_Global_Data.p_max_health)
