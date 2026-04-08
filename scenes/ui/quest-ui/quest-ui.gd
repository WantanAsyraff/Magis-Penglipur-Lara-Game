class_name QuestUI
extends Control

const CHAT_PREVIEW_SCENE := preload("res://scenes/ui/quest-ui/chat-preveiw-hbox.tscn")

func _ready() -> void:
	QuestManager.quest_started.connect(_refresh)
	QuestManager.quest_handed_off.connect(_refresh)
	QuestManager.quest_objective_updated.connect(_on_objective_updated)
	_refresh()

func _on_objective_updated(_instance: QuestInstance, _objective_id: String) -> void:
	_refresh()

func _refresh(_instance: QuestInstance = null) -> void:
	for child in %ChatLogsVBox.get_children():
		child.queue_free()
	
	for instance in QuestManager.get_all_active():
		if instance.status == QuestInstance.Status.ACTIVE:
			var box: ChatPreviewBox = CHAT_PREVIEW_SCENE.instantiate()
			%ChatLogsVBox.add_child(box)
			box.populate(instance)

func _on_back_button_pressed() -> void:
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	Player_Global_Data.p_moveable = true
