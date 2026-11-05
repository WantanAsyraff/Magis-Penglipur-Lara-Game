# Arcs and chapters

Create `StoryArcData` with lowercase stable `arc_id`, `display_name`, `description`, `chapters`, and `initial_chapter_id`. Create each `StoryChapterData` with `chapter_id`, `chapter_name`, `synopsis`, `stages`, and `initial_stage_id`. Add the arc to `data/story/definitions/story-database.tres`. IDs must be unique across the database and stay stable across releases. Array order is presentation order only. Run the story foundation fixture after editing. Phase 1 does not advance chapters.
