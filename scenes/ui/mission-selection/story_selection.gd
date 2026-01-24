extends Control

@export var destination_scene: PackedScene

func _on_button_pressed() -> void:
	SceneManager.change_scene(destination_scene.resource_path)
	pass
