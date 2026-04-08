class_name ChatPreviewBox
extends HBoxContainer

func populate(instance: QuestInstance) -> void:
	var data: QuestData = instance.quest_data
	
	%QuestNameLabel.text = data.title
	
	var desc_lines: Array[String] = [data.description, ""]
	for obj in data.objectives:
		var progress: int = instance.objective_progress.get(obj.objective_id, 0)
		var required: int = obj.required_amount
		var done := "✓" if progress >= required else "○"
		desc_lines.append("  %s %s (%d/%d)" % [done, obj.description, progress, required])
	%QuestDescLabel.text = "\n".join(desc_lines)
	
	var reward_parts: Array[String] = []
	if data.reward_xp > 0: reward_parts.append("XP: %d" % data.reward_xp)
	if data.reward_currency > 0: reward_parts.append("RM: %d" % data.reward_currency)
	%RewardsLabel.text = "\n".join(reward_parts) if not reward_parts.is_empty() else ""
