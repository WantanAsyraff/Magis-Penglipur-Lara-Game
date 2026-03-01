class_name DamageIndicator
extends Label

@export var float_height: float = 80.0
@export var duration: float = 1.2

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_height, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
