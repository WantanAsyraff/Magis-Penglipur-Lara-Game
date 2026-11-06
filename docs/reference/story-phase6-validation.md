# Phase 6 validation record

This record distinguishes automated evidence from a complete player walkthrough. Godot 4.7.2 headless editor import parses the authored database and Story Editor validator. `tests/story/story-prologue-migration.tscn` checks four production edges, five canonical stages, reachability, blocked premature transitions, accepted arrival, practical gates, receipts and the terminal stage. The environment scene fixture loads the authored school receiver and portal. Further commands and results belong in the handover for the exact working tree revision.

Godot 4.7.2 headless checks on this working tree:

| Check | Result |
| --- | --- |
| Editor import and script parsing | No errors |
| Production migration | 25 checks, 0 failures |
| Real prologue scene wiring | 15 checks, 0 failures |
| Headless player-control walkthrough: house intro skip, movement and portal to school, school skip, physical Chill cast, exam exit to FLAC, after-paper skip, save/reload | 22 checks, 0 failures; process exits 134 after assertions |
| Production Save V1 fresh-process writer/reader | 13 / 21 checks, 0 failures, both exit 0 |
| Natural intro, interruption and both sequence skips with StoryDirector | 14 checks, 0 failures; process exits 134 after assertions |
| Story foundation, transitions, world and save suites | 24 / 20 / 28 / 20 checks, 0 failures |
| Story debugger core and UI | 21 / 10 checks, 0 failures |
| Quest pipeline | 172 checks, 0 failures |
| Editor authoring create/reopen | 67 / 6 checks, 0 failures |
| Web debug PCK | Generated, about 102 MB; packed production migration test passes 25 checks |
| Web release export | NOT RUN to completion: Godot 4.7.2 Web release templates are absent |

Existing baseline issues remain: the Save V1 writer reports one six-particle-pool assertion failure (60 checks); the cutscene skip and prologue inventory suites print zero-failure assertions but exit 134 during shutdown. The new cutscene integration and player-control walkthrough suites have the same abnormal shutdown. The Inventory V2 save writer also exits 134 after zero-failure assertions; its reader passes 10 checks when rerun sequentially. Environment persistence writer and reader each pass 4 checks when run sequentially. Headless Story Editor GUI mode cannot capture a viewport texture, so graphical input interaction is unverified.

The headless walkthrough used actual F1, movement, interaction and spell incantation input in the authored campaign scenes, then checked saved FLAC position after reload. It started the house intro through the scene controller because `--quest-test-mode` intentionally suppresses the automatic new-game intro. A complete human visual playthrough and HUD review at 1280×720 and 1920×1080 remain unverified. Headless tests and a debug PCK do not prove those interactions or release-mode debugger gating. Test data was isolated under task-specific `XDG_DATA_HOME` directories with `--quest-test-mode`; real player saves were not touched.
