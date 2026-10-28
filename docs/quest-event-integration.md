# Quest gameplay events

Current handbook entry: [authoring/architecture guide](authoring/quests.md). Schema defaults and current source remain authoritative; any dated test paragraphs below retain their original verification scope.

`GameplayEvent` is a typed RefCounted envelope. Required fields are a valid enum type, nonempty event/owner/target identities and positive bounded quantity. New receipts default to a random 128-bit value. Replayed observations must reuse the original receipt. `source_instance_id`, `actor_id`, `tags` and `metadata` carry optional condition context; do not use display names as identity.

```gdscript
extends Node
# Call only from a confirmed, authoritative interaction; this is not an RPC.
func publish_lever(player: Node2D, interaction_receipt: String) -> bool:
    var event := GameplayEvent.new(
        GameplayEvent.Type.OBJECT_INTERACTED, "bakau_gate", 1,
        GameplayEvent.owner_for(player), "lever:" + interaction_receipt)
    event.metadata["opened"] = true
    return QuestManager.publish(event)
```

Only trusted authority publishes gameplay state. Runtime hooks use `GameplayEvent.service("QuestManager").call("publish", event)` to avoid compile-time autoload/resource cycles. No network RPC accepts arbitrary client event dictionaries.

| Publisher | Confirmation and attribution |
| --- | --- |
| EnemyQuestObserver | Enemy V2 death after hitbox; once-only guard and session-unique spawn ID; canonical enemy ID and tags; valid player damage credit |
| EnemyLootComponent | Authority/once death guard; independent entries; dropped objects inherit kill owner; spawning alone gives no collection progress |
| Inventory_Manager | Actual accepted quantity only; owner/capacity/receipt validation; removal after mutation; reward transaction deltas after commit |
| DroppedItem / ItemPickupComponent | Production collision delay and magnet, then central pickup; partial quantity remains; duplicate old ItemQuestComponent notification removed |
| SpellCastingComponent | Completed accepted cast, not rejected cast request; cast receipt |
| SpellExecutor | Successful target effect; cast-target receipt deduplicates multi-collider impacts |
| ApplyStatusEffect | Successful status application with canonical status target and cast/target receipt |
| QuestNPCComponent / QuestBoard | Interaction event at actual interaction; resource-driven quest identity remains outside hooks |
| DialogicComponent | Natural timeline completion only; cancelled close restores movement without completion event |
| QuestWorldEvent | Configured area/interaction publisher for location/object/flag, once per owner if requested |
| QuestManager / rewards | World flag changes and durable QUEST_COMPLETED event after successful hand-in |

An enemy casting a spell is not attributed to the local player. Explicit player ownership can transfer to owned projectiles/summons through CombatLifecycle. Unowned generic actors do not silently become the local player. A local event only reaches local instances; other-owner events cannot mutate the local inventory or claim local rewards. Actual remote inventory and party allocation remain future integration.

Inventory `add_item` returns the number accepted. Pickup receipts belong to the inventory service, not merely to objective evaluation. An unsuccessful acquisition does not consume a receipt; a partial drop uses a new receipt part for its retained remainder. Cumulative objectives ignore inventory removals and items held before acceptance. Held/delivery objectives always use reconciled current quantities.

Reward events are placed in a durable outbox with stable IDs before saving the claim. Immediate inventory notifications and recovered outbox notifications share IDs, so collection credit cannot repeat after a crash. The next save records drained receipts. The manager evaluates every eligible accepted quest independently and keeps its progress keyed by objective ID.

Legacy `notify_item_collected` and update-objective entry points remain trusted compatibility APIs. New gameplay code must use confirmed inventory events rather than calling them on spawn or overlap. This compatibility surface is not authorization for exposing native methods to clients.
