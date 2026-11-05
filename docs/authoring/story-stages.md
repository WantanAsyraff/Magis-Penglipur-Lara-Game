# Stages

Create `StoryStageData` with `stage_id`, `display_name`, `description`, and `objective_hint`. Add it to a chapter's `stages` array and set the chapter's `initial_stage_id` to a member. The authored prologue uses `prologue.wake_up`, `prologue.leave_house`, `prologue.reach_school`, `prologue.spm_practical`, and `prologue.after_exam`. These are definitions; the current stage is persisted through SaveManager after a successful save. Do not attach rewards to stage definitions.
