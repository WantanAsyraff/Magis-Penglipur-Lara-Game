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

## Called by DroppedItem.gd during its _ready() loop.
func init_component(parent: DroppedItem) -> void:
	_parent_item = parent
	
	# Connect signal if not already connected via editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Start as slightly transparent to show it's "dropping"
	_parent_item.modulate.a = 0.5
	
	# Grace period (0.2s) to prevent instant pickup and allow "Pop" physics
	get_tree().create_timer(0.2).timeout.connect(_make_collectible)

func _make_collectible() -> void:
	_is_collectible = true
	_parent_item.modulate.a = 1.0 # Visual cue: Item is now "solid"
	
	# Check if player is ALREADY standing on it after the timer
	for body in get_overlapping_bodies():
		_on_body_entered(body)

# ─────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	# 1. ADD THIS PRINT TO DEBUG
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
	var data = _parent_item.loot_data
	if not data:
		push_warning("[ItemPickupComponent] No LootData found on %s" % _parent_item.name)
		return

	print("--- Picking up: %s (ID: %s) ---" % [data.item_name, data.item_id])

	# 1. Health
	if data.health_restore > 0:
		var old_hp = Player_Global_Data.p_curr_health
		Player_Global_Data.restore_health(data.health_restore)
		print(" >> Health: %d -> %d (+%d)" % [old_hp, Player_Global_Data.p_curr_health, data.health_restore])
	
	# 2. Mana
	if data.mana_restore > 0.0:
		var old_mp = Player_Global_Data.p_curr_mana
		Player_Global_Data.restore_mana(data.mana_restore)
		print(" >> Mana: %.1f -> %.1f (+%.1f)" % [old_mp, Player_Global_Data.p_curr_mana, data.mana_restore])
		
	# 3. EXP
	if data.exp_reward > 0:
		var old_exp = Player_Global_Data.player_exp
		Player_Global_Data.player_exp += data.exp_reward
		print(" >> EXP: %d -> %d (+%d)" % [old_exp, Player_Global_Data.player_exp, data.exp_reward])
		
	# 4. Currency (Ringgit)
	if data.currency_reward > 0:
		var old_amt := Player_Global_Data.p_curr_ringgit
		Player_Global_Data.p_curr_ringgit += data.currency_reward
		print(" >> Currency: RM%.2f -> RM%.2f (+%d)" % [old_amt, Player_Global_Data.p_curr_ringgit, data.currency_reward])

	# 5. Spells
	if data.spell_to_unlock:
		print(" >> Unlocking Spell: ", data.spell_to_unlock.spell_name)
		Player_Global_Data.add_spell(data.spell_to_unlock)

	# 6. Quests
	if data.is_quest_item and data.quest_objective_id != "":
		print(" >> Quest Progress: ", data.quest_objective_id)
		for instance in QuestManager.get_all_active():
			if instance.status == QuestInstance.Status.ACTIVE:
				for obj in instance.quest_data.objectives:
					if obj.objective_id == data.quest_objective_id:
						QuestManager.update_objective(instance.instance_id, data.quest_objective_id, 1)
						break
	print("---------------------------------------")
