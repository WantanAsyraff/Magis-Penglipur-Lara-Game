class_name QuestEventHooks extends RefCounted
static func receipt(context: SpellCastContext) -> String:
	if not context.state.has("quest_receipt"): context.state.quest_receipt = Crypto.new().generate_random_bytes(16).hex_encode()
	return context.state.quest_receipt
static func cast(context: SpellCastContext) -> void:
	var owner := GameplayEvent.owner_for(context.caster)
	if owner.is_empty() or context.spell == null: return
	GameplayEvent.service("QuestManager").call("publish", GameplayEvent.new(GameplayEvent.Type.SPELL_CAST, context.spell.spell_id, 1, owner, "cast:" + receipt(context)))
static func hit(context: SpellCastContext, target: Node2D) -> void:
	var owner := GameplayEvent.owner_for(context.caster)
	if owner.is_empty() or context.spell == null or not is_instance_valid(target): return
	var event := GameplayEvent.new(GameplayEvent.Type.SPELL_HIT, context.spell.spell_id, 1, owner, "hit:" + receipt(context) + ":" + str(target.get_instance_id()))
	event.metadata.target_id = String(target.get_meta("enemy_id", ""))
	GameplayEvent.service("QuestManager").call("publish", event)
static func status(context: SpellCastContext, target: Node2D, id: String) -> void:
	var owner := GameplayEvent.owner_for(context.caster)
	if owner.is_empty(): return
	var event := GameplayEvent.new(GameplayEvent.Type.STATUS_APPLIED, id, 1, owner)
	event.metadata.spell_id = context.spell.spell_id if context.spell else ""
	event.metadata.target_id = String(target.get_meta("enemy_id", ""))
	GameplayEvent.service("QuestManager").call("publish", event)
