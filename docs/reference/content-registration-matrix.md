# Content registration matrix

Creating a `.tres` does not universally register it. Reference-only dependencies are export-safe only if their parent is reachable. Paths below are actual repository locations; new content folders under them are conventions, not preexisting files.

| Content / schema | Placement | Runtime registration / consumer | Validation | Export requirement |
| --- | --- | --- | --- | --- |
| Academic field / FieldData | data/magis/fields/ | Assigned academic_fields on spell/course/subject; no global field browser | SpellValidator field refs; course/progression tests | Reachable parent reference |
| Course / CourseData | data/magis/ilmiah/ | SpellTreeView.course_data; GameSaveSchema.COURSES for completed-subject saving | AcademicValidator.validate_course + purchase checks | Course-view scene ref; persistence allowlist preload |
| Subject / subjectData | Course content/core-subjects/ | CourseData.subjects, contained_spells; no folder scan | Course graph and purchase requirements | Referenced by registered/reachable course |
| Player spell / SpellData | Top-level data/magis/spells/ | Spell_Library manifest, plus editor-only top-level discovery | SpellValidator and library duplicate/empty-incantation diagnostics | Run bake-spell-manifest.gd; review SPELLS preloads |
| Enemy-only legacy spell / SpellData | data/magis/legacy-enemy-spells/ | Direct ability/scene reference; not automatic player library | Shared validator | Reachable ability/scene ref; register separately only if intended player/save identity |
| Typed effects / SpellEffectDefinition + 15 subclasses | data/Resources/spell-effects/ scripts; content usually inline in spells | SpellData.effects, EnemyAbilityData.effects or nested children | Effect.validate, recursive SpellValidator, runtime accepts/budget | Referenced parent graph; no effect bake |
| Status behavior / manager entries | Existing effect config | Hitbox/actor/periodic handlers, or explicit Conditional/Chain marker consumption | Status/clear/resistance/stack tests | Parent effect ref; new mechanic needs handler code |
| Status presentation / StatusPresentation | scenes/ui/status-effects/status-presentation.gd | Script dictionary consumed by cached HUD icons | HUD tests/rendered focus/stack/expiry | Referenced HUD scene; not a Resource catalogue |
| Enemy definition / EnemyData | data/npc/enemies/definitions/ | Scene.enemy_data or SpawnData override; EnemyManifest.ENEMIES for quest IDs/drop discovery | EnemyData.validate and QuestRegistry | Explicit manifest/scene refs; no auto scan/baker |
| Enemy stats / EnemyStatsData | Enemy inline/reusable content | EnemyData.stats | validate() recursively via definition | Parent reference |
| Perception / EnemyPerceptionData | Enemy inline/reusable content | EnemyData.perception | validate(), real LOS/group scans | Parent reference |
| AI profile / EnemyAIProfile | data/npc/enemies/ai-profiles/ | EnemyData.ai_profile | validate() + utility eligibility tests | Parent reference |
| AI action / EnemyAIAction | Inline or profile content | EnemyAIProfile.actions | validate(), unique IDs in profile | Parent reference |
| Enemy ability / EnemyAbilityData | data/npc/enemies/abilities/ | EnemyData.abilities + compatible action kind/role/filter | validate(), loadout/range/LOS/mana tests | Parent and spell/effect references |
| Spawn choice / SpawnData | data/npc/enemies/spawn/ | EnemySpawner.spawn_pool | Valid enemy_scene/positive weights/placement; data.validate on override | Spawner scene refs; no global spawn registry |
| Legacy caster / NPCSpellcasterData | Existing data/npc/ content | Enemy.legacy_spellcaster through EnemyDefinitionAdapter | Resulting EnemyData validation; dormant fields documented | Direct referenced definition; prefer V2 for new content |
| Boss phase / BossPhaseData | data/npc/enemies/boss/<content>/ | Boss.phases ordered array | No standalone validator; boss tests + author review | Boss scene references phase Resources |
| Boss attack / BossAttackData | Same boss content directory | BossPhaseData.attacks weighted pools | No standalone validator; kind-specific scene/spell/geometry tests | Phase references attacks/dependencies |
| Item / ItemData | data/items/ | ItemManifest.ITEMS/LEGACY_LOOT OR loot/extras of a manifest-registered EnemyData | QuestRegistry identity/max_stack, inventory checks | Explicit manifest or registered enemy loot dependency |
| Loot / LootData | data/loot/ | EnemyData.loot, legacy loot table or fixed quest reward | validate(); fixed reward restrictions in QuestRegistry | Referenced parent; no independent loot scan |
| Crafting recipe / ItemData | Output item Resource | CraftingRoom.available_recipes; ingredient_1..3/qty_1..3 | Inventory plan and actual UI/capacity tests | Room/output/input refs, plus item registration for saves |
| Quest / QuestData | data/quests/ faculty/content directories | QuestDatabase.quests; QuestRegistry currently loads FLAC and Bakau paths only | QuestRegistry cross-reference/cycle/group/reward checks | Existing DB array or explicit new DB path in registry |
| Objective / QuestObjectiveData | Inline/reusable quest content | QuestData.objectives and confirmed GameplayEvent publishers | Registry + evaluator tests | Quest dependency |
| Group / QuestObjectiveGroup | Inline/reusable quest content | QuestData.objective_groups, objective.group_id | Satisfiable ALL/ANY group, no unknown memberships | Quest dependency |
| Database / QuestDatabase | data/quests/ | Hardcoded list in QuestRegistry; board assignment alone is insufficient | Entire registry, unique quest IDs | Registered DB path reference |
| NPC identity / NPCPresentation | data/npc/presentation/ | QuestNPCComponent.presentation; PRESENTATIONS manifest for resolve/contact UI | NPC identity, portrait, explicit offer/accessibility tests | Manifest or direct scene refs; assets/ portrait path allowlist |
| Safe NPC placement / NPCSpawnValidator | Inline/reusable placement config | RoomQuestManager.spawn_validator and marker arrays | Ground/body/approach/corridor tests | Spawner scene reference |
| World scene / SceneData | data/worlds/hubs/ | World_Manifest recursive scan → Scene_Registry | Scene IDs/refs, actual boot/spawn/return | bake-world-manifest.gd → world-manifest-paths.gd fallback |
| Elevator entry / ElevatorFloor | Inline or world content | ElevatorPortal.floors | Registered scene, valid marker, lock/UI tests | Elevator scene ref; destination SceneData registration |
| Tutorial / TutorialData | data/tutorials/<topic>/ | TutorialComponent.tutorial_data + invocation | Nonempty non-null pages; display/dismissal tests | NPC/component ref; no scan/baker |
| Tutorial page / TutorialPage | Same tutorial folder | TutorialData.pages | Page presentation and optional image refs | Parent ref |
| Lyrics / LyricLine, LRCParser | system/lyrics/ code; authored timestamp text in assets/ | LyricsManager.load_for_player(audio,path) | Parser and actual audio/scene lifecycle | Explicit raw-text export include if needed; not Resource classes |

## Actual tools

- [tools/validate-spells.gd](../../tools/validate-spells.gd): EditorScript. Open in Script editor and run Ctrl+Shift+X. It builds a fresh Spell_Library, prints errors/warnings and a count; it does not bake.
- [tools/bake-spell-manifest.gd](../../tools/bake-spell-manifest.gd): EditorScript. Scans top-level spell `.tres` files and rewrites SPELLS preloads. It does not recursively register new nested player spell folders.
- [tools/bake-world-manifest.gd](../../tools/bake-world-manifest.gd): EditorScript. Recursively scans hub `.tres` files, sorts paths and writes BAKED_PATHS. Use hyphens despite the runtime warning's old underscore spelling.
- [tools/test-enemies.py](../../tools/test-enemies.py), [test-quests.py](../../tools/test-quests.py), [test-physics.py](../../tools/test-physics.py): actual executable-runner wrappers described in [testing](testing-and-validation.md); not content registration utilities.
- [tools/validate-docs.py](../../tools/validate-docs.py): documentation-only link/path/schema/snippet checks; does not validate newly authored gameplay semantics or alter manifests.

IDs and retained references must match in source **and export**. Keep UID/path changes visible in review; see [content evolution](../architecture/save-load-architecture.md). A Resource can be directly spawnable but still unknown to quest/save registries.
