# Dialogue variants

Add a StoryDialogueResolver child to an NPC. Create StoryDialogueVariant Resources with stable `variant_id`, `priority`, a DialogicTimeline or `direct_text`, and optional StoryCondition Resources. Higher priority wins; equal priorities sort by variant ID. The existing DialogicComponent remains the runtime. QuestNPCComponent still handles quest offers and hand-ins before story variants are considered.

## Make an NPC Change Dialogue After a Quest

1. Add `StoryDialogueResolver` as an NPC child; keep its existing `DialogicComponent` and `npc_timeline` for fallback.
2. Create `StoryQuestCondition`, set a registered `quest_id`, and select `required_status = HANDED_IN` when hand-in is required.
3. Create `StoryDialogueVariant` with a stable lower-case `variant_id`, an existing `timeline`, optional `dialogue_identity`, and a higher `priority` than other eligible variants. Add the quest condition to `conditions`, then add the variant to the resolver's `variants` array.
4. Run before and after quest hand-in. The existing quest offer, Accept/Decline and hand-in interactions retain priority. For a one-time conversation, set `once_only` and complete it naturally; interruption leaves it available.

The completion receipt is written into StoryState only after DialogicComponent reports a completed conversation, then included in the normal campaign save. Older `story_dialogue:*` world flags remain readable for compatibility. For Yunira, use a test fixture until a production NPC and canonical variant timelines are verified.

Story variants pass `dialogue_identity` as a portrait identity. They do not publish a quest dialogue-completed event. QuestNPCComponent retains its existing interaction priority.
