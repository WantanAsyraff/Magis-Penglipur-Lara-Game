class_name CampaignCheckpoint extends Area2D
# Place the Respawn Marker2D on safe ground, outside walls and hazards.
@export var checkpoint_id: String = ""
@onready var respawn: Marker2D = $Respawn
func _ready() -> void:
	body_entered.connect(func(body):
		if body == Player_Manager.get_local_player() and not checkpoint_id.is_empty():
			SaveManager.activate_checkpoint(checkpoint_id,respawn.global_position))
