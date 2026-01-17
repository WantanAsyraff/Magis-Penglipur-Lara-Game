class_name ZoneData extends Resource

@export var zone_id: String
@export var zone_name: String
@export var zone_scene: PackedScene
@export_enum("Hub", "Combat", "Boss", "Recreation", "Study") var zone_type: String = "Combat"
@export var difficulty: int = 1
@export var required_story_flags: Array[String] = []
@export var music_track: AudioStream
