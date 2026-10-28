# Additional data and legacy configuration

The Resource inventory includes every first-party Resource class, including inherited SpellEffectDefinition subclasses. Built-in Godot assets such as Texture2D, SpriteFrames, Theme, StyleBox, AudioStream and PackedScene retain standard Inspector creation/import workflows; they are dependencies, not additional project gameplay catalogues.

## Legacy NPCSpellcasterData

Source: [spellcaster-npc.gd](../../data/Resources/spellcaster-npc.gd). The existing [dudeman-test.tres](../../data/npc/enemies/dudeman-test.tres) retains this schema under data/npc/. Prefer EnemyData for new enemies. To use a legacy definition, create NPCSpellcasterData through New Resource, configure caster_id/name, spell_pool and stats, and assign the Enemy root's legacy_spellcaster export. EnemyDefinitionAdapter.from_spellcaster constructs an instance-local EnemyData and cautious-spellcaster profile; it does not mutate the original Resource.

Consumed mapping: max_hp/max_mana, HP/mana regen and delay, base_defense, move_speed, preferred_range/too_close_threshold, stun/dot/impairment resistance, spell_pool, preferred/forbidden_spell_types and exp_reward. Preferred types affect ability weight; forbidden types omit the ability. Healing/buff/summon role inference uses the legacy spell's category/delivery. Fields such as portrait/species/archetype/comprehension, mana shield, aggression/react window/delays/combo/counter probabilities, low_mana_threshold and spell-drop hooks are preserved schema data but do not gain new runtime mechanics through this adapter. Exact defaults and all properties are [listed here](../reference/resource-reference.md#npcspellcasterdata).

Validate the resulting EnemyData and run enemy tests; ensure registered enemy identity and source references if using it for quests/export. For ordinary new content follow EnemyData instead of building a second spellcaster controller. There is no formal player-character-class Resource; p_role and similar strings are identity labels.

## Lyrics and audio

[LRCParser](../../system/lyrics/lrc.gd) and [LyricLine](../../system/lyrics/lyric-line.gd) are script classes, **not Resource types**. LyricsManager.load_for_player takes an AudioStreamPlayer and a text path. Authored lines have a timestamp like `[00:12.34]` followed by text; the parser sorts them, and LyricsOverlay presents lyric_changed. Use original/authorized text; the handbook does not reproduce song lyrics.

Import/assign an AudioStream on the scene's AudioStreamPlayer, provide a timestamp text asset, then call the existing load_for_player method from the scene's playback integration. A new song's audio assignment can be data-only; introducing a new timeline-to-lyrics binding needs that existing API invocation. Plain text files opened by FileAccess may require an export include filter; test the actual pack rather than assuming Resource import retains arbitrary text. There is no song Resource registry or persisted lyric playback. Call stop on the appropriate lifecycle boundary and test pause/scene exit manually.

## Other scene configuration

ElevatorFloor and NPCSpawnValidator are covered by [worlds](worlds-and-scenes.md) and [NPCs](npcs-and-dialogue.md). QuestWorldEvent, CampaignCheckpoint, portal settings, jump pads, ladders, keys and locked doors are Node/component exports rather than new Resource schemas; configure their existing scenes and interaction/collision contracts. Persistent key/door/nonrespawning prop flags use WorldPersistence, not a separate authored WorldState Resource. Status presentation is a lightweight script registry; there is no unimplemented icon Resource to create.

No additional first-party Resource-derived gameplay schema is intentionally left without a reference/guide mapping. Vendor Dialogic Resources remain vendor-owned and are integrated through project dialogue assets; this handbook documents project integration rather than rewriting the addon's manual/API.
