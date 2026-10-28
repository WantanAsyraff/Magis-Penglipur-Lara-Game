# Registries and manifests

[The registration matrix](../reference/content-registration-matrix.md) is the operational source of truth. This page explains why there are several mechanisms.

- Spell_Library first preloads `data/magis/spell-manifest.gd`. Under `OS.has_feature("editor")`, it also discovers top-level `.tres` files in `data/magis/spells/` and reports missing manifest entries. It does not recursively discover legacy enemy spells. Use bake-spell-manifest.gd for a new player spell.
- QuestRegistry reads ItemManifest.ITEMS/LEGACY_LOOT and EnemyManifest.ENEMIES. It additionally registers items and explicit extras on each registered enemy's loot entries. Enemy IDs come from those definitions. Then it loads only the FLAC and Bakau database paths listed in its constructor and validates quests/cycles/rewards.
- Enemy scenes can directly reference definitions even before a global entry exists, but quest kill validation needs the enemy manifest. A QuestBoard's assigned database does not expand QuestRegistry's hardcoded database list.
- World_Manifest recursively scans SceneData files under data/worlds/hubs/. If the scan returns no paths, it uses the baked world paths. Scene_Registry stores their IDs and PackedScenes. Bake world paths before export; the code's underscore-spelled warning is an outdated message, not the filename to run.
- NPCPresentation.resolve reads a manually maintained PRESENTATIONS array. Direct QuestNPCComponent assignment supplies an identity to that NPC; add an entry to the manifest for consistent later conversation resolution.
- Courses/fields/subjects, effects, loot, AI actions, phases and tutorial pages are reached through parent Resource/scene references. There is no universal course browser or automatic recipe database. Campaign saves additionally restrict completed subject IDs to GameSaveSchema.COURSES.

Baking tools are EditorScripts, invoked in Godot's Script editor with Ctrl+Shift+X. Enemy/item/presentation manifests require an explicit GDScript preload/reference edit; that is content registration, not a reason to rewrite gameplay controllers. No automatic bake tools exist for those manifests.
