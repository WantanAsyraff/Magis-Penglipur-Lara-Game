# scene_data.gd
class_name SceneData
extends Resource

@export var scene_id: String  # UNIQUE ID - this is the key!
@export var scene: PackedScene
@export var scene_name: String
@export var default_spawn_marker: String = "PlayerSpawn"
@export_multiline var description: String
