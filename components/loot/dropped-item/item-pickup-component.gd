# ItemPickupComponent.gd
extends Area2D
class_name ItemPickupComponent

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var _parent_item: DroppedItem
var _is_collectible: bool = false

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────

func init_component(parent: DroppedItem) -> void:
	_parent_item = parent

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_parent_item.modulate.a = 0.5
	get_tree().create_timer(0.2).timeout.connect(_make_collectible)

func _make_collectible() -> void:
	_is_collectible = true
	_parent_item.modulate.a = 1.0

	for body in get_overlapping_bodies():
		_on_body_entered(body)

# ─────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	print("[Pickup] Detected collision with: ", body.name)
	if not _is_collectible:
		return
	if body.is_in_group("player"):
		print("[Pickup] Is Player! Applying loot...")
		_apply_loot_logic()
		_parent_item.queue_free()

# ─────────────────────────────────────────
# INTERNAL LOGIC
# ─────────────────────────────────────────

func _apply_loot_logic() -> void:
	var loot = _parent_item.loot_data
	if not loot:
		push_warning("[ItemPickupComponent] No LootData found on %s" % _parent_item.name)
		return
	if not loot.item:
		push_warning("[ItemPickupComponent] LootData has no ItemData assigned on %s" % _parent_item.name)
		return

	var data: ItemData = loot.item
	var quantity: int = _parent_item.quantity

	print("--- Picking up: %s (ID: %s) x%d ---" % [data.item_name, data.item_id, quantity])

	# 1. Inventory
	Inventory_Manager.pickup(data, quantity)

	# 2. Health
	if data.health_restore > 0:
		var old_hp = Player_Global_Data.p_curr_health
		Player_Global_Data.restore_health(data.health_restore)
		print(" >> Health: %d -> %d (+%d)" % [old_hp, Player_Global_Data.p_curr_health, data.health_restore])

	# 3. Mana
	if data.mana_restore > 0.0:
		var old_mp = Player_Global_Data.p_curr_mana
		Player_Global_Data.restore_mana(data.mana_restore)
		print(" >> Mana: %.1f -> %.1f (+%.1f)" % [old_mp, Player_Global_Data.p_curr_mana, data.mana_restore])

	# 4. EXP
	if data.exp_reward > 0:
		var old_exp = Player_Global_Data.player_exp
		Player_Global_Data.player_exp += data.exp_reward
		print(" >> EXP: %d -> %d (+%d)" % [old_exp, Player_Global_Data.player_exp, data.exp_reward])

	# 5. Spells
	if data.spell_to_unlock:
		print(" >> Unlocking Spell: ", data.spell_to_unlock.spell_name)
		Player_Global_Data.add_spell(data.spell_to_unlock)

	# 6. Quests
	for obj_id in data.quest_objective_ids:
		if obj_id != "":
			print(" >> Quest Progress: ", obj_id)
			for instance in QuestManager.get_all_active():
				if instance.status == QuestInstance.Status.ACTIVE:
					for obj in instance.quest_data.objectives:
						if obj.objective_id == obj_id:
							QuestManager.update_objective(instance.instance_id, obj_id, 1)
							break

	print("---------------------------------------")
