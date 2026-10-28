# Resource lifecycle

1. Author the exact custom Resource class in the Editor, save a `.tres` with explicit IDs and assign typed dependencies.
2. Validate both schema constraints and cross-resource references. A legal Inspector value can still be unusable (for example an enemy ability outside its effective target range).
3. Register via the actual manifest, database or scene export. Check [the matrix](../reference/content-registration-matrix.md).
4. Runtime services resolve the definition and create instance-local state. EnemyStatsComponent tracks HP; QuestInstance tracks progress; SpellCastContext carries source, modifiers and an execution budget.
5. Components consume the definition on actual input, AI intent or confirmed events. UI predicts or presents, never grants gameplay authority.
6. Persistence serializes supported stable IDs and runtime progression, then resolves Resources from trusted registries on load. It does not serialize raw SpellData objects or save to authored `.tres` files.
7. Exports must retain a preload/reference chain. Editor-only scans are not evidence of export completeness. Verify with a fresh PCK and a fresh process.

A Resource file sitting in an arbitrary directory is not automatically a catalogue entry. Conversely, nested stats/effects/pages need no global manifest when an already reachable parent references them. A `.tres` dependency can be an external Resource or an inline subresource; keep reusable definitions external and variants explicitly unique.

For new files, allow Godot to create asset identity. Duplicate in the Editor and set a new gameplay ID; do not hand-copy a released UID. Prefer Inspector-authoring to copying numeric enum values from old files. The complete exported field list is [schema checked](../reference/resource-reference.md).
