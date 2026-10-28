extends CPUParticles2D
var bursts: int = 0
func _ready() -> void:
	get_parent().incantation_direction_accepted.connect(_accepted)
func _accepted(_direction: String) -> void:
	bursts += 1
	# Restart reuses six CPU particles, also on the Compatibility/Web renderer.
	# Rapid inputs replace the preceding tiny burst instead of accumulating emitters.
	restart()
