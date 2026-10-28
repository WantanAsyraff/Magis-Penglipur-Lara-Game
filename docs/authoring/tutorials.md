# Tutorials

[TutorialData](../../data/tutorials/tutorial-data.gd) and [TutorialPage](../../data/tutorials/tutorial-page.gd) are Resources. Existing examples are [npcs-quests.tres](../../data/tutorials/overworld/npcs-quests.tres) and its two page Resources. Keep content under data/tutorials/<topic>/; the reusable display is [tutorial-panel.tscn](../../components/panels/tutorials/tutorial-panel.tscn).

## Editor procedure

1. Right-click your tutorial content folder → New Resource → TutorialPage. Set page_title, multiline page_desc and optional page_image; save each reusable page. These are the actual three page fields, not Markdown or a slideshow engine.
2. Create TutorialData, set tutorial_title and add page Resources in pages order. The panel currently renders each page's title rather than displaying tutorial_title as a separate heading. No standalone validate method exists; ensure no null pages and at least one page.
3. On an inherited nonquest tutorial NPC, find TutorialComponent. Set has_tutorial=true, tutorial_panel_scene to the existing PanelTutorial scene and tutorial_data to your TutorialData.
4. Give the NPC a working DialogicComponent/timeline and interaction detector. npc.gd's nonquest dialogue-ended path calls try_show, then restores/continues normal flow. Quest NPC interactions have their own path and do not automatically invoke this nonquest tutorial callback.
5. Interact in gameplay, finish dialogue, read next/back through every page, then Done, Close and Escape. Confirm movement resumes and the temporary CanvasLayer is freed. Test a second interaction; there is no generic persistent “tutorial read once” state.
6. Export and test the NPC/parent scene. Resource and image references retain dependencies; no tutorial manifest/bake is needed.

TutorialComponent.try_show can be called from another deliberate local integration, but an arbitrary NPC with only tutorial_data and no invoking behavior will never open it. Custom sequencing or one-time progression flags need code using the existing component/QuestManager flags. After displaying a tutorial, npc.gd returns from its dialogue-ended callback rather than automatically calling its destination-transition _finish method; a tutorial-then-transition sequence needs explicit integration. PanelTutorial expects its unique UI node names; a replacement panel must expose compatible data and closed signal.

Troubleshooting: has_tutorial false, missing data/panel, empty/null pages, quest route bypassing nonquest tutorial, or a missing dialogue completion are actual causes. Completion: page refs valid, invocation reachable, paging/dismissal/input restoration checked, source/PCK dependencies and transient save policy understood. See [all fields](../reference/resource-reference.md#tutorialdata).
