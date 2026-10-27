extends CharacterBody2D
# -------------------------
# EXPORTS
# -------------------------
@export_group("Visuals")
@export var npc_sprite: Texture2D:
	set(value):
		npc_sprite = value
		if is_inside_tree() and sprite:
			sprite.texture = value
@export_group("Overworld Transition")
@export var is_overworld_npc: bool = false
@export var destination_scene: PackedScene
@export var spawn_marker_override: String = ""
# -------------------------
# COMPONENTS (all optional)
# -------------------------
var wander: WanderComponent
var detection: DetectionComponent
var dialogic: DialogicComponent
var tutorial: TutorialComponent
var quest: QuestNPCComponent
var sprite: Sprite2D
# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	wander    = get_node_or_null("%WanderComponent")
	detection = get_node_or_null("%DetectionComponent")
	dialogic  = get_node_or_null("%DialogicComponent")
	tutorial  = get_node_or_null("%TutorialComponent")
	quest     = get_node_or_null("%QuestNPCComponent")
	sprite    = get_node_or_null("%Sprite2D")
	if npc_sprite and sprite:
		sprite.texture = npc_sprite
	if dialogic:
		dialogic.dialogue_ended.connect(_on_dialogue_ended)
	if detection:
		detection.interacted.connect(_on_interacted)
	else:
		print("[NPC] detection is NULL")
	if quest:
		quest.dialogue_requested.connect(_on_quest_dialogue_requested)
# -------------------------
# INTERACT
# -------------------------
func _on_interacted() -> void:
	print("[NPC] _on_interacted | quest=%s | dialogic=%s" % [quest, dialogic])
	if (dialogic and dialogic.is_open()) or QuestOfferDialog.is_open(): return
	if quest:
		quest.interact()
		return
	if dialogic:
		dialogic.start()
# -------------------------
# QUEST DIALOGUE
# -------------------------
func _on_quest_dialogue_requested(dialogue_text: String, _instance: QuestInstance) -> void:
	# Narrative completion is never an acceptance or reward action.
	if dialogic: await dialogic.start_direct_text(dialogue_text)
# -------------------------
# PHYSICS
# -------------------------
func _physics_process(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	if wander: wander.steer(delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
# -------------------------
# POST-DIALOGUE
# -------------------------
func _on_dialogue_ended() -> void:
	if quest: return
	if tutorial and await tutorial.try_show():
		return
	_finish()
func _finish() -> void:
	if is_overworld_npc and destination_scene:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			Player_Manager.last_player_position = player.global_position
		Player_Manager.previous_scene_path = get_tree().current_scene.scene_file_path
		if spawn_marker_override != "":
			Player_Manager.set_meta("next_spawn_marker", spawn_marker_override)
		await SceneManager.change_scene(destination_scene.resource_path)
