extends CharacterBody2D

@export_group("Dialogic")
@export var npc_timeline: DialogicTimeline

@export_group("Overworld Transition")
@export var is_overworld_npc: bool = false
@export var destination_scene: PackedScene

@export_group("Tutorial")
@export var has_tutorial: bool = false
@export var tutorial_panel_scene: PackedScene

var is_player_in_range: bool = false

func _input(event: InputEvent) -> void:
	if is_player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if Dialogic.current_timeline == null:
		Player_Global_Data.p_moveable = false
		Dialogic.start(npc_timeline)
		await Dialogic.timeline_ended

		if has_tutorial and tutorial_panel_scene:
			_show_tutorial()
			return
		_finish()

func _show_tutorial() -> void:
	var panel = tutorial_panel_scene.instantiate()
	get_tree().current_scene.add_child(panel)
	await panel.closed
	panel.queue_free()
	_finish()

func _finish() -> void:
	if is_overworld_npc and destination_scene:
		Player_Global_Data.p_moveable = true
		await SceneManager.change_scene(destination_scene.resource_path)
	else:
		Player_Global_Data.p_moveable = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
