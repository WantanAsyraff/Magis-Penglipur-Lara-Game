class_name EnemyData extends Resource
@export var enemy_id: StringName = &"":
	get:
		if enemy_id != &"": return enemy_id
		if not quest_enemy_id.is_empty(): return StringName(quest_enemy_id)
		# Legacy nonquest definitions retain their registered filename identity.
		return StringName(resource_path.get_file().get_basename())
@export var enemy_name: String = "Enemy"
@export_multiline var description: String = ""
@export var enemy_category: StringName = &"manifestation"
@export var faction_id: StringName = &"enemy"
## Optional appearance-only Node2D scene; gameplay always uses the shared Enemy shell.
@export var visual_scene: PackedScene
@export var stats: EnemyStatsData
@export var perception: EnemyPerceptionData
@export var ai_profile: EnemyAIProfile
@export var abilities: Array[EnemyAbilityData] = []
@export var cooldown_multiplier: float = 1
@export var loot: Array[LootData] = []
@export var experience_reward: int = 0
@export var quest_enemy_id: String = "":
	set(value):
		quest_enemy_id = value
		# Compatibility for editor-resaved legacy definitions missing enemy_id.
		if enemy_id == &"" and not value.is_empty(): enemy_id = StringName(value)
@export var death_delay: float = 0.25
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id == &"" or faction_id == &"": errors.append("Enemy requires identity and faction")
	if stats == null or perception == null or ai_profile == null: errors.append("Enemy requires stats, perception and AI profile")
	else:
		errors.append_array(stats.validate())
		errors.append_array(perception.validate())
		errors.append_array(ai_profile.validate())
	if not is_finite(cooldown_multiplier) or cooldown_multiplier <= 0 or not is_finite(death_delay) or death_delay < 0 or death_delay > 30 or experience_reward < 0: errors.append("Invalid cooldown/reward/lifetime")
	var ids := {}
	for ability in abilities:
		if ability == null: errors.append("Missing ability"); continue
		errors.append_array(ability.validate())
		if ids.has(ability.ability_id): errors.append("Duplicate ability ID")
		ids[ability.ability_id] = true
	return errors

@export var enemy_tags: Array[StringName] = []
