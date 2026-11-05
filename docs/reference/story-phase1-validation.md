# Story Phase 1 validation

Branch: `feature/story-pipeline-phase1-foundation`; base: `bd320fe9cf889247232c0f8cc14f4f2acfe40e92`.

Godot 4.7 Flatpak editor import completed with no script errors. `tests/story/story-foundation.tscn` ran with `--quest-test-mode`: 24 checks, 0 failures. Godot emitted a shutdown resource warning (27 resources in use). Save V1 schema and paths were not changed. Quest Pipeline regression: 172 checks, 0 failures. Web PCK exported (98 MB) and the story fixture passed from the pack: 24 checks, 0 failures. Quest persistence writer: 4 checks, 0 failures; fresh reader: 7 checks, 0 failures. Full prologue walkthrough has not yet been verified.

Command: `flatpak run --command=sh org.godotengine.Godot -c 'export XDG_DATA_HOME=/home/wantansirap/.cache/story-phase1-tests; exec /app/bin/godot-bin --headless --path /home/wantansirap/Projects/Magis-Penglipur-Lara-Game res://tests/story/story-foundation.tscn -- --quest-test-mode'`.

Phase 1 limitations: chapter/stage and typed transient values reset on successful restore; no transition/action engine, durable choices, or independent story receipts. Authoring starts in `data/story/definitions/story-database.tres` and is performed through typed Inspector Resources.
