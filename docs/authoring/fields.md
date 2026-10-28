# Academic fields

## Purpose, schema and example

FieldData describes academic identity, not a combat dispatcher. Source: [field.gd](../../data/Resources/ilmu/field.gd). Save new definitions under `data/magis/fields/` with kebab-case filenames. [Physics](../../data/magis/fields/physics.tres) is the working example. FieldData has no standalone validate method.

| Property | Required? | Meaning |
| --- | --- | --- |
| field_id | Yes for validation | Stable StringName, such as `mathematics`; do not recycle a released ID |
| display_name | Yes for useful presentation | Human-readable label |
| description | Optional | Authored explanation |
| related_field_ids | Optional | Academic relationship metadata; does not automatically unlock or calculate combat bonuses |

## Editor procedure: add Mathematics

1. Right-click data/magis/fields/ → Create New → Resource → FieldData. Save as mathematics.tres.
2. Set field_id to `mathematics`, display_name to Mathematics and a description. Leave related_field_ids empty or add known academic IDs; these strings do not resolve a course automatically.
3. On each relevant SpellData, CourseData and subjectData, expand academic_fields and drag mathematics.tres into the typed array. References keep the field available in exports.
4. Author a course/subjects and a scene referencing that course, following [courses and subjects](courses-and-subjects.md). Merely adding the field does not add a selectable discipline to every UI.
5. If progression should require comprehension, put `mathematics: 1` in a subject's comprehension_requirements and author a deliberate reward/event that calls Player_Global_Data.set_comprehension. There is no automatic comprehension gain or new-field menu generator.
6. Add new course references to GameSaveSchema.COURSES before saving its completed subjects. This is a necessary registration code edit for campaign persistence, not a spell engine rewrite.

## Runtime, validation and export

SpellValidator checks non-null field references with nonempty field_id. AcademicValidator validates course subjects/prerequisite graph; Player_Global_Data checks comprehension before purchase. Run the Physics suite for existing progression, add checks for the new course and test its actual SpellTreeView scene. A field with no consumers is valid authored data but unreachable gameplay.

Troubleshooting: a field missing from progression usually has no assigned CourseData/SpellTreeView; a spell executing like existing physics is expected because delivery/effects, not academic labels, define mechanics. A related-field list is not a prerequisite list. New combat mechanics require an [effect extension](spell-effects.md), not a different field name.

Completion: unique ID; references assigned to all intended content; course exposed to players; comprehension source and requirements tested; course registered for saves; reference chain tested in PCK. See the [field property reference](../reference/resource-reference.md#fielddata).

## Minimal native Resource example

This hypothetical new FieldData uses only existing properties. Create it with the Editor steps above; no existing UID is copied. The documentation checker loads this example with Godot without adding permanent gameplay content.

```tres
[gd_resource type="Resource" script_class="FieldData" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/Resources/ilmu/field.gd" id="field"]

[resource]
script = ExtResource("field")
field_id = &"mathematics"
display_name = "Mathematics"
description = "An academic identity for authored mathematics courses and spells."
```
