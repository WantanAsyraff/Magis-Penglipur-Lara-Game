class_name QuestUI
extends Control

@onready var quest_label: Label = %QuestLabel

func _ready() -> void:
	QuestManager.quest_started.connect(_refresh)
	QuestManager.quest_handed_off.connect(_refresh)
	QuestManager.quest_objective_updated.connect(_on_objective_updated)
	_refresh()

func _on_objective_updated(_instance: QuestInstance, _objective_id: String) -> void:
	_refresh()

func _refresh(_instance: QuestInstance = null) -> void:
	var lines: Array[String] = []
	for instance in QuestManager.get_all_active():
		if instance.status == QuestInstance.Status.ACTIVE:
			var data: QuestData = instance.quest_data
			lines.append("──────────────────")
			lines.append("📋 %s" % data.title)
			lines.append(data.description)
			lines.append("")
			for obj in data.objectives:
				var progress: int = instance.objective_progress.get(obj.objective_id, 0)
				var required := 0
				for amount in obj.required_amounts:
					required += amount
				var done := "✓" if progress >= required else "○"
				lines.append("  %s %s (%d/%d)" % [done, obj.description, progress, required])
			if data.reward_xp > 0 or data.reward_currency > 0:
				lines.append("")
				lines.append("🎁 Rewards:")
				if data.reward_xp > 0:
					lines.append("  XP: %d" % data.reward_xp)
				if data.reward_currency > 0:
					lines.append("  RM: %d" % data.reward_currency)
	if lines.is_empty():
		quest_label.text = "No active quests."
	else:
		quest_label.text = "\n".join(lines)

func _on_back_button_pressed() -> void:
	print("Current scene, ", Player_Global_Data.current_scene)
	print("Previous scene, ", Player_Global_Data.previous_scene)
	if Player_Global_Data.previous_scene == "":
		push_error("BackButton: No previous scene stored.")
		return
	Player_Manager.last_player_position = Player_Global_Data.previous_position
	SceneManager.change_scene(Player_Global_Data.previous_scene)
	print("Position, ", Player_Global_Data.previous_position)
	print("Position, ", Player_Global_Data.previous_position)
	Player_Global_Data.p_moveable = true
