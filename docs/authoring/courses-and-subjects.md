# Courses, subjects and academic classes

CourseData groups subjects; subjectData defines one purchasable unit and its unlocked spells. Their schemas are [course.gd](../../data/Resources/ilmu/course.gd) and [subject.gd](../../data/Resources/ilmu/subject.gd). The lowercase `s` in **subjectData** is the actual class_name to search. Existing placement is `data/magis/ilmiah/physics-field/`, with subject Resources under core-subjects/. [physical-science.tres](../../data/magis/ilmiah/physics-field/physical-science.tres) references all twelve verified Physics subjects.

## Inspector requirements

| Resource/fields | Configure |
| --- | --- |
| Course course_id/course_name | Unique stable ID and visible title |
| Course subjects | Non-null subjectData array in intended curriculum order |
| Course prerequisites | Completed **subject IDs**, not course IDs; checked during purchase |
| Course academic_fields | FieldData references; classification, not automatic UI registration |
| Course archetype/description/comprehension/difficulty | Authored presentation; subject cost uses the subject's values, not course difficulty |
| Subject subject_id/subject_name/subject_icon | Stable unique ID, visible name, optional texture |
| Subject prerequisites | Subject IDs; no cycles; cross-course IDs must be satisfied explicitly |
| Subject contained_spells | Non-null SpellData references; purchase learns them but does not automatically equip |
| Subject difficulty_level | Inspector 1–5; cost uses at least 1 |
| Subject magis_comprehension | Novice / Intermediate / Advanced / Expert; cost multiplier 1 / 1.5 / 2.25 / 3.5 |
| Subject comprehension_requirements | Field ID → minimum integer rank; no implicit rank award |
| Subject subject_archetype/magis_archetype | Existing string enum values; descriptive classification, not a player-class system |
| Subject field_of_study/theoretical_foundation/casters_notes | Academic text shown by study presentation |

All exported fields/defaults are in the [reference](../reference/resource-reference.md#coursedata). Required playable data is stricter than “a Resource can be saved”: include IDs, names, valid contained spells, coherent prerequisites and an accessible UI.

## Complete example: one field, one course, three subjects

This is a hypothetical exercise using existing schema fields, not shipped content.

1. Create mathematics.tres as described in [Fields](fields.md), field_id `mathematics`.
2. Make `data/magis/ilmiah/mathematics-field/` and its core-subjects/ folder. Right-click → New Resource → CourseData; save foundations.tres. Set course_id `math-foundations`, course_name Mathematics Foundations, magis_archetype Ilmiah, academic_fields [mathematics.tres]. Leave course prerequisites empty initially.
3. Create three subjectData files named mathematics-001.tres through mathematics-003.tres. Give IDs `MATH-001`, `MATH-002`, `MATH-003`, appropriate names, subject_archetype Mathematics, magis_archetype Ilmiah, magis_comprehension Novice and difficulty_level 1. Set academic_fields to Mathematics on each.
4. First subject prerequisites: []; second: [MATH-001]; third: [MATH-002]. Leave comprehension_requirements empty until a rank-awarding path exists, or the course will be deliberately locked.
5. Assign an already registered SpellData to each contained_spells array, or create new spells using the spell guide and register them. Teaching an already learned spell is not a second reward; add_spell ignores duplicates.
6. Put the three subject Resources in CourseData.subjects. Do not place Resources into the prerequisites string array.
7. Duplicate the existing `scenes/spell-tree/spell-tree.tscn` to a new course view, retaining its SpellTreeView script and required unique UI nodes. Assign course_data = foundations.tres in Inspector. Run F6 to inspect layout; entry via a world/NPC is required to populate the normal previous-scene return path.
8. Create a SceneData for that course-view scene under data/worlds/hubs/, give it a new scene_id, bake world paths and add a portal/elevator/NPC route from a campaign room. [World authoring](worlds-and-scenes.md) explains transition and return state. The course view is UI, so SaveManager will not save directly there; return to a campaign ZoneRoot before saving.
9. Add foundations.tres to `GameSaveSchema.COURSES` alongside Physics. Without this code registration, MATH subject IDs fail full-save validation. No Player.gd or effect execution change is needed.
10. Enter via that route, buy MATH-001 with sufficient XP, confirm XP debit once and the spell in My Spells, equip it, then buy MATH-002/003 in order. Attempt a repeated purchase and a locked purchase. Save in the campaign room and load in a fresh process/PCK.

## Purchase behavior and testing

Player_Global_Data.purchase_subject calls can_purchase_subject. With a course argument, the subject must belong to it and AcademicValidator must accept it. Both subject prerequisites and course prerequisites are completed subject IDs. Cost is `int(30 * max(difficulty_level,1)^2 * multiplier * (1 + contained_spells.size()*0.25))`. Completion is committed before XP/spell signals to avoid reentry double purchases. Experience is also a curriculum currency; do not independently deduct it in UI.

AcademicValidator detects missing IDs, duplicate subjects and in-course cycles; it is not a global cross-course catalogue. Verify new cross-course references yourself. A “class” in this guide means a subject/course. `p_role` is an identity string; no formal Resource-driven character class, profession-stat progression or subclass unlock system exists. GDScript class_name registers script types and is unrelated to academic classes.

Common mistakes: course IDs in subject prerequisite arrays, shared Resource edits affecting Physics, unregistered contained spells, comprehension requirements without a source, or exposing a new view but omitting its save allowlist. Completion: run AcademicValidator and Physics regression, manually traverse the new view, test single purchase/unlocks, and verify source/PCK/fresh-process persistence.
