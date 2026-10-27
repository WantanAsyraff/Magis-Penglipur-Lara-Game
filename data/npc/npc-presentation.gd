class_name NPCPresentation extends Resource
@export var npc_id: String = ""
@export var display_name: String = "Quest giver"
@export var portrait: Texture2D
@export var dialogic_character: Resource
@export var dialogue_identity: String = ""
@export_multiline var offer_dialogue: String = ""
@export_multiline var accepted: String = "Alright! I'll be counting on you. Come back when you've finished."
@export_multiline var declined: String = "No worries! Come find me if you change your mind."
@export var reoffer_cooldown: float = 0
static func resolve(id: String) -> NPCPresentation:
	var manifest_path: String = "res://data/npc/presentation/manifest.gd"
	var manifest: Variant = load(manifest_path)
	var presentations: Array = manifest.PRESENTATIONS
	for presentation in presentations:
		if presentation.npc_id == id: return presentation
	var result := NPCPresentation.new()
	result.npc_id = id
	result.dialogue_identity = id
	result.display_name = id.replace("_", " ").capitalize()
	result.portrait = load("res://assets/temp/player-temp.png")
	return result

func resolved_portrait() -> Texture2D:
	if dialogic_character:
		var portraits: Variant = dialogic_character.get("portraits")
		var preferred: Variant = dialogic_character.get("default_portrait")
		if portraits is Dictionary and portraits.has(preferred):
			var image_path := String(portraits[preferred].get("export_overrides", {}).get("image", "")).trim_prefix('"').trim_suffix('"')
			if image_path.begins_with("res://assets/") and ResourceLoader.exists(image_path):
				var texture: Texture2D = load(image_path)
				if texture: return texture
	return portrait
static func for_conversation(conversation: QuestConversation) -> NPCPresentation:
	var result := resolve(conversation.npc_id).duplicate() as NPCPresentation
	if not conversation.display_name.is_empty(): result.display_name = conversation.display_name
	if conversation.portrait_path.begins_with("res://assets/") and ResourceLoader.exists(conversation.portrait_path) and conversation.portrait_path.get_extension().to_lower() in ["png", "jpg", "jpeg", "svg", "webp"]:
		result.dialogic_character = null
		result.portrait = load(conversation.portrait_path)
	return result
