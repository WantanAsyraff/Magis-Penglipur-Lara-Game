class_name InteractionReceiver extends Node
signal activated
signal progress(hits: int, charge: float)
var rule: InteractionRule
var hits := 0
var charge := 0.0
var completed := false
var _casts: Dictionary = {}
var _spell_depth := 0
func begin_spell() -> void:
	_spell_depth += 1
func end_spell() -> void:
	_spell_depth = maxi(0,_spell_depth-1)
func reset() -> void:
	hits = 0; charge = 0; completed = false; _casts.clear()
func receive_event(event: InteractionRule.Event, magnitude: float = 0) -> void:
	if _spell_depth > 0 or not SpellExecutor.is_authoritative(self): return
	if rule == null or event != rule.event or magnitude < rule.minimum_magnitude: return
	_accept(magnitude)
func receive_spell(context: SpellCastContext, effect: SpellEffectDefinition) -> void:
	if rule == null or not SpellExecutor.is_authoritative(self) or context == null or _casts.has(context.cast_id): return
	if rule.event not in [InteractionRule.Event.SPELL,InteractionRule.Event.DAMAGE,InteractionRule.Event.STATUS,InteractionRule.Event.IMPULSE,InteractionRule.Event.PROJECTILE]: return
	if rule.required_capability != &"" and not get_parent().has_meta(StringName(String(rule.required_capability).replace("-","_"))): return
	var kind := "Any"
	var magnitude := 0.0
	if effect is DamageEffect: kind = "Damage"; magnitude = effect.amount
	elif effect is ApplyStatusEffect: kind = "Status"; magnitude = effect.magnitude
	elif effect is KnockbackEffect: kind = "Impulse"; magnitude = effect.force
	elif effect is VectorEffect: kind = "Impulse"; magnitude = effect.strength
	elif effect is HealEffect: kind = "Healing"; magnitude = effect.amount
	if rule.effect_kind != "Any" and rule.effect_kind != kind: return
	if rule.event == InteractionRule.Event.DAMAGE and kind != "Damage": return
	if rule.event == InteractionRule.Event.STATUS and kind != "Status": return
	if rule.event == InteractionRule.Event.IMPULSE and kind != "Impulse": return
	if rule.event == InteractionRule.Event.PROJECTILE and LegacySpellAdapter.delivery_for(context.spell) != SpellData.Delivery.PROJECTILE: return
	if rule.required_status != &"":
		if not effect is ApplyStatusEffect or effect.status != String(rule.required_status): return
		var hitbox := get_parent().get_node_or_null("HitboxComponent") as HitboxComponent
		if hitbox == null or not hitbox.effects.has(String(rule.required_status)): return
	if magnitude < rule.minimum_magnitude: return
	_casts[context.cast_id] = true
	if _casts.size() > 128: _casts.erase(_casts.keys()[0])
	_accept(float(context.spell.upfront_cost) + context.spell.channel_duration*context.spell.mana_per_second)
func _accept(energy: float) -> void:
	if completed and not rule.reset_after_activation: return
	hits += 1
	charge += maxf(0,energy)
	progress.emit(hits,charge)
	if hits >= rule.required_hits and charge >= rule.required_charge:
		completed = true
		activated.emit()
		if rule.reset_after_activation:
			hits = 0; charge = 0; completed = false
