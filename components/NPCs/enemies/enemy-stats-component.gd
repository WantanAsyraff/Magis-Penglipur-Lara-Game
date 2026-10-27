class_name EnemyStatsComponent extends Node
var config: EnemyStatsData
var regen_remaining: float = 0
var recently_received_damage: float = 0
func configure(value: EnemyStatsData) -> void:
	config = value
	var enemy := get_parent()
	enemy.max_health = config.max_health
	enemy.current_health = config.max_health
	enemy.spell_mana = config.max_mana
	enemy.move_speed = config.move_speed
	enemy.chase_speed = config.chase_speed
	enemy.set_meta("outgoing_damage_multiplier", config.outgoing_multiplier)
	var h: HitboxComponent = enemy.hitbox
	h.damage_reduction = config.defense
	h.damage_multiplier = config.incoming_multiplier
	h.knockback_resistance = config.knockback_resistance
	h.status_resistances = config.status_resistances.duplicate()
	h.has_mana = config.max_mana > 0
	h.damage_taken.connect(receive_damage)
	h.healed.connect(heal)
	h.mana_drained.connect(drain)
func tick(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	if enemy.get_meta("combat_dead", false): return
	regen_remaining = maxf(0, regen_remaining - delta)
	recently_received_damage = maxf(0, recently_received_damage - delta * 10)
	if regen_remaining <= 0:
		heal(config.health_regen * delta)
		if not enemy.hitbox.effects.has("mana_drain"):
			enemy.spell_mana = minf(config.max_mana, enemy.spell_mana + (config.mana_regen + enemy.hitbox.effects.magnitude("buff_mana_regen")) * delta)
func receive_damage(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	if enemy.get_meta("combat_dead", false) or amount <= 0: return
	regen_remaining = config.regen_delay
	recently_received_damage += amount
	enemy.current_health = maxf(0, enemy.current_health - amount)
	enemy.enemy_hurt.emit(amount)
	if enemy.current_health <= 0: enemy.die()
	else: enemy.react_to_damage()
func heal(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	if not enemy.get_meta("combat_dead", false): enemy.current_health = minf(config.max_health, enemy.current_health + maxf(amount, 0))
func drain(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	enemy.spell_mana = maxf(0, enemy.spell_mana - maxf(amount, 0))
func consume(amount: float) -> bool:
	if not SpellExecutor.is_authoritative(self): return false
	var enemy := get_parent()
	if not is_finite(amount) or amount < 0 or enemy.spell_mana < amount or enemy.get_meta("combat_dead", false): return false
	enemy.spell_mana -= amount
	if amount > 0: regen_remaining = config.regen_delay
	return true
func restore(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var enemy := get_parent()
	enemy.spell_mana = minf(config.max_mana, enemy.spell_mana + maxf(0, amount))
