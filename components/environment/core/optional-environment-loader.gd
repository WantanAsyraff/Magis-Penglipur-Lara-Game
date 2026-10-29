extends Node2D
## Load optional apparatus after the campaign manifest has resolved its scene resources.
## A file reference avoids eagerly pulling the gameplay dependency graph into registry load.
@export_file("*.tscn") var environment_scene: String
func _ready() -> void:
	if environment_scene.is_empty(): return
	var packed := load(environment_scene) as PackedScene
	if packed: add_child(packed.instantiate())
