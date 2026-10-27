# SpawnData.gd
extends Resource
class_name SpawnData

@export var enemy_scene: PackedScene
@export_range(0, 100) var spawn_weight: float = 10.0 # Relative probability

## Optional definition override; inherited scene configuration is preserved when empty.
@export var enemy_data: EnemyData
