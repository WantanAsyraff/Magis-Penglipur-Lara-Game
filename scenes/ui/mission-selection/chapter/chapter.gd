extends VBoxContainer
@export var chapter_name: String
@export var destination_scene: PackedScene

@onready var select_btn = %SelectButton

func _ready() -> void:
	select_btn.text = chapter_name

func _on_select_button_pressed() -> void:
	SceneManager.change_scene(destination_scene.resource_path)
	pass
