# Documentation maintenance policy

A change to a Resource schema, exported property, public API, registration path, validator, save migration or authoring workflow must update its canonical handbook page **in the same change**. Preserve historical implementation reports/counts; link them to current instructions rather than rewriting old measurements as new ones.

| Subsystem | Implementation source of truth | Canonical guide |
| --- | --- | --- |
| Academics | data/Resources/ilmu/, AcademicValidator, player-data purchase methods | Fields and courses/subjects |
| Spells | SpellData, SpellValidator, resolver/casting/delivery/executor, Spell_Library | Spells/effects/statuses |
| Enemies | data/npc/enemies/, Enemy components, EnemyManifest | Enemy definitions/AI/abilities |
| Bosses | Boss, BossPhaseData, BossAttackData and actual arena/HUD | Boss authoring |
| Items/loot/crafting | ItemData, LootData, Inventory_Manager, CraftingUI | Items/loot and crafting |
| Quests/givers | QuestRegistry/Manager/Instance/evaluator/reward/save/conversation services, NPC components | Quests and NPC/dialogue |
| Worlds/tutorials | SceneData, World_Manifest, Scene_Registry, ZoneRoot, tutorial components | World/tutorial guides |
| Campaign persistence | SaveManager, GameSaveSchema/Store, QuestSaveService | Save V1 and save/load architecture |

Every new Resource-driven system needs its schema/source, step-by-step authoring guide, working example, real validation method, explicit registration/export procedure and persistence note. Add its class-to-guide mapping to tools/validate-docs.py; the checker fails when a newly discovered first-party Resource has no guide. Update field notes and run --write-reference after reviewing actual runtime consumers. Generated consumer links are source navigation, not behavioral proof.

Before merge run documentation validation and relevant engine/content checks. Maintain one canonical authoring page per family; old entry points should redirect instead of accumulating contradictory instructions. Include new/updated files, actual commands/results and unverified limits in the change description.
