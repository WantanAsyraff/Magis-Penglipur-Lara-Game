# Persistent quest conversations

QuestManager owns `QuestConversationStore`. Progression remains authoritative in QuestInstance; chat is a projection of validated actions and lifecycle changes, not a replacement state machine.

## Records

QuestConversation contains a stable NPC/conversation identity, display name, portrait asset path, associated quest IDs, ordered entry dictionaries and the last read sequence. No live Node reference is stored. NPC respawns retain the same contact ID. The default contacts use `flac_ariff_npc`, `flac_hasan_npc`, `flac_sarah_npc` and `bakau_field_researcher`; new identities use the same Resource mechanism.

Each entry contains:

| Field | Meaning |
| --- | --- |
| entry_id | Stable receipt used for deduplication |
| event_type | Offer, decision, reaction or lifecycle event |
| quest_id | Stable resource identity |
| sender_type | npc / player / system |
| message_text | Actual authored narrative or validated player action |
| timestamp / sequence | Wall-clock value plus global monotonic display order |
| snapshot | Optional objective or reward values at the milestone |

Implemented events include OFFER_PRESENTED, PLAYER_ACCEPTED, PLAYER_DECLINED, OFFER_DISMISSED, NPC_REACTION, QUEST_STARTED, OBJECTIVE_UPDATED (objective completion milestone), QUEST_READY_FOR_HAND_IN, QUEST_COMPLETED, REWARD_CLAIMED and QUEST_EXPIRED. Partial objective progress is rendered from current quest state rather than appended for every event. Snapshot data is presentation history; clicking it cannot replay progression or rewards.

Each genuine reoffer gets a new token and may log a new decline/dismissal. Replaying the same token is rejected. Acceptance is instance-keyed and recorded once. Objective/readiness/completion/reward receipts are deterministic per instance so repeated signals or restoration do not duplicate them. A completed history and a newer quest can coexist under the same NPC.

## Save/restore

The version-2 quest snapshot gains an optional `conversations` dictionary. Existing v2 saves without it restore an empty store, preserving prior quest/inventory state. New snapshots include contacts, entries, read state and presentation references. Stage validates container structure, known quest references, sender types, monotonic sequence and unique nonempty entry receipts. Restore builds a fresh store and deduplication index, then replaces the live store; it does not append the saved history onto existing messages.

Current full-game restore replaces the staged conversation store without appending saved history or synthesizing missing lifecycle messages. SaveManager resumes the existing receipt-bearing durable reward outbox and repairs an interrupted next-quest offering after restoration commits. Normal lifecycle handlers record their deterministic messages when invoked. Campaign conversation changes are captured in the next manual/milestone/claim snapshot, not an independently written quest file; unsaved dialogue/read changes may be lost on abrupt termination. See [Save V1](save-system-v1.md) and [NPC authoring](authoring/npcs-and-dialogue.md).

Offer tokens, currently open panels and cooldown timers are transient. Loading replaces/dismisses an unresolved panel; the player approaches the NPC again. Live NPC components reacquire their restored instance from QuestManager rather than retaining stale RefCounted progress objects. Viewing a conversation updates in-memory read state; it becomes durable with the next full-game snapshot. Portrait/display fields are stored as data; image paths are restricted to existing asset image references for rendering.

The store is local-owner presentation data. Remote events cannot populate local contacts through normal lifecycle routing. Full multiplayer chat synchronization/party sharing is not implemented, consistent with the existing Quest V2 authority boundary. History currently has no archive/retention compaction policy.

## Verification

The accessibility suite checks accepted/declined decisions, sender alignment, recent contacts, multiple quests, objective cards, completed/reward history, no per-kill flood, repeated restore, read state and actual phone navigation. Separate Godot writer/reader processes verify that explicit decisions for two quests and their read state survive restart. Both tests run from source and a fresh exported PCK. Tests use isolated filenames; the accessibility snapshot includes the process ID to avoid collisions with rendered verification.
