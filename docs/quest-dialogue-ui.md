# Quest dialogue, offers and phone UI

## One coordinated interaction

An in-range focused NPC publishes interaction, runs the existing Dialogic introduction, then opens `quest-offer-dialog.tscn`. Natural introduction completion leaves the quest AVAILABLE. It never calls acceptance. Escape/interruption cancels the narrative without activating anything. Legacy `confirm_offer_complete()` is intentionally a no-op; the old `npc.gd` dialogue callback no longer accepts or grants rewards.

The centered native offer card shows the NPC portrait/name, region/category, quest title, NPC narrative, description, objectives, prerequisites, reward icons/quantities and separate Decline/Accept buttons. A ScrollContainer handles long content; the frame is bounded to 920×820 and fits smaller viewports. It uses the Bitter font and navy/green quest palette. Native buttons supply mouse, keyboard focus, hover/pressed/disabled states and the existing Godot UI actions. Physical controller hardware was not tested.

`QuestOfferDialog.show_offer` obtains a manager-issued token bound to the current instance, NPC and local owner. The manager validates availability, prerequisites, identity and authority. `decide_offer(token, action)` is the sole presentation decision path. Repeated token/button activation cannot repeat a decision. Accept calls the central state transition and records the real player choice; it gives no completion rewards. Decline records a choice and resource-defined response while leaving the quest AVAILABLE. Default cooldown is zero, allowing reoffer; an optional presentation cooldown is runtime policy. Dismiss is separate and never invents a decline.

On a decision the native card disables its actions and yields visibility to Dialogic for the configured acceptance/decline response. The offer retains the input lock until that sequence ends or is cancelled. Closing the reaction does not undo an already accepted/declined decision. Each layer restores its prior movement value rather than always enabling movement. Pause, Escape, NPC/source despawn, scene replacement and restored/replaced live tokens dismiss unresolved panels. One global current panel prevents duplicates. Pending UI tokens are transient and are not restored as approvals.

The Bakau board retains its discoverable list of ten quests, including locked prerequisites, in `quest-catalogue.tscn`. **View offer** closes the paused catalogue before opening the same explicit-decision card. All ten Bakau quests and all four FLAC quests use this shared flow. The catalogue's explicit hand-in button and the NPC's confirmed hand-in still route through the central exactly-once reward service.

## NPC identity and authored text

`NPCPresentation` provides stable `npc_id`, display name, portrait fallback, optional Dialogic character Resource, portrait/timeline identity, optional offer text, accepted/declined responses and optional reoffer cooldown. The FLAC presets reference the existing Ariff, Hasan and Sara Dialogic characters and their existing portrait assets. `resolved_portrait()` reads the character's default portrait where available. The field researcher uses the existing NPC sprite fallback. No portraits are keyed by quest ID.

QuestNPCComponent resolves presentation from stable NPC identity or an explicitly assigned Resource. Identity mismatch is rejected by the manager. Existing FLAC offer, progress and completion strings remain intact as fallbacks. Quest Resource narrative takes precedence for the selected quest: the same NPC can offer unrelated tasks, and several old NPC lines mention different materials. This keeps the visible offer consistent with its actual objectives without rewriting the original dialogue assets. `QuestData.dialogue_accepted` and `dialogue_declined` override identity responses when authored. A custom presentation can provide an offer override. Dialogic receives its presentation identity separately from the canonical NPC event identity, preventing portrait aliases from changing objective targets.

XP and currency use new native SVG symbols in `assets/ui/quests/`; items use their actual ItemData icons and configured reward quantities. Existing leaf placeholders remain for items without final art. Reward rendering reads Resources and does not embed quest-specific item paths.

## Messaging app

The existing phone quest icon and stable QuestUI scene UID remain. Its app is now embedded in the existing 448×640 PhoneBG instead of changing scenes. Launching it does not save/teleport player position or invoke SceneManager. Back inside a conversation returns to contacts; Back at contacts emits `back_pressed` to restore the phone launcher. The world interact action is blocked while the phone is selected.

Contacts show avatar, name, last actual message, latest status, sequence/order and unread dot. Recent activity sorts first. Multiple quests share a stable NPC contact; completed and declined records remain. Details show left NPC bubbles, right player-choice bubbles, system milestones and read-only live quest cards with reward icons. Declined cards explicitly say Declined; they are not active objectives. Historical messages have no Accept/Claim callbacks.

`QuestWidgets` supplies the shared theme, contact preview, sender bubbles, quest/progress/completion card and reward preview. Text wraps at phone width. Every kill updates the current objective card, but only meaningful objective/readiness/completion milestones add messages. No per-kill message flood is generated.

See the [conversation model](quest-conversation-model.md) for persistence and [placement guide](npc-spawn-accessibility.md) for approach/focus authoring. The actual render command and screenshot list are in [integration tests](bakau-integration-tests.md).
