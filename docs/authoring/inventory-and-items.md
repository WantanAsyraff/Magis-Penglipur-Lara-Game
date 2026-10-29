# Inventory and items

[ItemData](../../data/items/item-data.gd) is the source of identity, presentation, stacks, supported effects and equipment compatibility. [Inventory_Manager](../../autoloads/inventory-manager.gd) owns transactions; Controls never edit quantities. See [inventory presentation](inventory-ui.md), [loot registration](items-and-loot.md) and [complete properties](../reference/resource-reference.md).

## Create an item

1. Create an ItemData Resource under data/items/ with a unique stable item_id, readable item_name, description and optional item_icon. Missing icons use a monogram; icons use nearest filtering. Keep published IDs unchanged.
2. Choose item_type. CONSUMABLE and FOOD support compatibility-mode manual restoration. EQUIPMENT requires explicit compatible slots. MATERIAL, WEAPON_MATERIAL and RARE_MATERIAL share the Materials filter. COMPONENT, QUEST_ITEM and KEY_ITEM retain separate filters. All Items includes every category.
3. Set positive max_stack and is_stackable. Nonstackable capacity is one per ID. Inventory capacity remains **64 distinct IDs**, not physical backpack positions or multiple stacks. Equipped items live outside the held dictionary; pending player drops reserve capacity.
4. Configure use_behavior and real effects using the table below. A name such as Mana Vial does not confer mana restoration: the existing component stays a component.
5. For equipment choose the equipment_slots flags. Weapon=1, Offhand=2, Robe=4, Accessory 1=8, Accessory 2=16; combine compatible bits. Zero means no new equip operation. Use the registered [student lab robe](../../data/items/equipment/student-lab-robe.tres) as a stat-free example. No armor, damage or universal stat modifier model is added.
6. Register the exact Resource in ItemManifest.ITEMS, or through loot/extras of a manifest-registered EnemyData. Recipes and quest references alone do not register an identity. Register canonical player spell references in Spell_Library before assigning spell_to_unlock.
7. Run ItemData.validate(), actual pickup/use/equip/drop and save/load tests. Check editor and exported Resource reachability. No new UI branch is needed for another item using these supported behaviors.

## Use behavior

| Behavior | Pickup | Use |
| --- | --- | --- |
| AUTOMATIC_COMPATIBILITY (default for old Resources) | Store quantity; XP/spell acquisition reward once per ID | FOOD/CONSUMABLE restore configured health/mana, consume one |
| MANUAL | Store without applying effects | Apply configured restoration, XP or unlearned spell; consume one |
| ACQUISITION_REWARD | Store; configured HP/mana/XP/spell once per ID | Disabled |
| NONE | Store without effects | Disabled |

Fish Meat now stores without healing. Inventory_Manager.use_item(item_id) checks authority, registered canonical data, ownership, live player/story/modal context and a meaningful effect before consuming exactly one. Health and mana use existing clamped stat APIs. Full bars or an already learned spell do not waste an ordinary item. allow_wasted_use is an explicit author override; an item still needs a supported effect. MANUAL XP is deliberately per consumed item, while compatibility/acquisition XP is once per identity, using existing acquisition_receipts. Direct add_item, crafting and reward plans do not replay pickup effects.

Manager actions return ItemActionResult with ok/message and optionally world_drop. Rejected operations leave quantities/equipment unchanged. Replacement equipment returns the old item in the same preflight plan; unequip fails if its return cannot fit. Materials, food and quest items cannot be newly equipped. Old saved zero-mask equipment can load and be unequipped, preserving prior inventories without permitting new arbitrary equips.

## Drops, capacity and quest semantics

Drop is a recoverable world transfer, not permanent disposal. The UI confirms a selected quantity and explains this policy. KEY_ITEM and QUEST_ITEM are always protected; can_drop=false protects other authored content. A live authoritative Player and unobstructed nearby spawn are required. Shape and line checks use the existing terrain layer. Failed creation preserves the stack.

A real DroppedItem receives a unique ledger token. It becomes collectible only after 0.8 seconds **and** the player has moved over 500 world units away. Returning picks up that quantity exactly once. Fresh drops cannot immediately magnet back. Transfers publish inventory events but do not farm cumulative collection objectives or acquisition rewards; held-item objectives reconcile actual held quantities.

**Safe Save V1 policy:** player drops reserve their original ID and stack capacity while outside the inventory. They return exactly once on area exit or on loading their saved ledger. World drop positions are not serialized. This prevents capacity races and item loss when Save V1 reconstructs worlds, but dropping does not permanently free capacity. Use, crafting and delivery remain ways to spend items. Unsupported persistent litter/discard behavior needs a separate future persistence design.

## Favorites and persistence

Favorites are stable IDs, toggled by the detail star, Y key or gamepad Y. The optional favorites array and drop_escrow dictionary live in the existing Quest V2 bundle inside Save V1. No schema version changes. Old bundles default to empty values; malformed fields, fractional quantities, invalid IDs/tokens or incompatible explicit equipment reject staging before mutation. Restore returns valid escrow once and reconciles held objectives. Profile reset clears favorites and receipts; UI selection/search/scroll are session-only.

Validate with tests/inventory-v2.tscn, inventory-v2-save writer/reader, quest-persistence, combat-feedback-save-v1 and the native preview. Test fixtures register temporary data only in their own test process and never grant campaign content.
