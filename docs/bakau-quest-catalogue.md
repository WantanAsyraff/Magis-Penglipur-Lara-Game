# Bakau quest catalogue

Current handbook entry: [authoring/architecture guide](authoring/quests.md). Schema defaults and current source remain authoritative; any dated test paragraphs below retain their original verification scope.

Ten new nonrepeatable Technology & Science quests (faculty 6), region `bakau`, pool `technology_science`, hand-in `bakau_field_researcher`. All collection is cumulative after acceptance; samples are not consumed. Narrative about freshness, simultaneous surveys and comparative batches does not imply an invented timer, reset or same-life rule. Prerequisites require successful hand-in.

| ID | Quest | Objectives | Prerequisite | XP | Item reward |
| --- | --- | --- | --- | --- | --- |
| quest_bakau_001 | Haruan Hitam Cull | Haruan ×8 | None | 120 | 2 × Mana Vial (Low Grade) |
| quest_bakau_002 | Specimen: Haruan | Mixed Fish Samples ×5 (any of drop_001, drop_002, drop_003) | quest_bakau_001 | 80 | 4 × Tech Scrap (Low Grade) |
| quest_bakau_003 | Pepatung Patrol | Pepatung ×6 | None | 100 | 1 × Mana Vial (Low Grade) |
| quest_bakau_004 | Wings & Antennae | Dragonfly Wings ×3; Dragonfly Antenna ×2 | quest_bakau_003 | 90 | 4 × Tech Scrap (Low Grade) |
| quest_bakau_005 | Ketam Clearance | Ketam ×10 | None | 130 | 4 × Mana Vial (Low Grade) |
| quest_bakau_006 | Shell Harvest | Crab Shell ×4; Crab Claw ×3 | quest_bakau_005 | 100 | 4 × Mana Vial (Low Grade) |
| quest_bakau_007 | Mana Fauna Survey | Haruan ×5; Pepatung ×4; Ketam ×6 | None | 280 | 6 × Mana Vial (Low Grade) |
| quest_bakau_008 | Field Sample Bundle | Fish Meat ×2; Dragonfly Scales ×2; Crab Shell ×2 | quest_bakau_006 | 220 | 6 × Tech Scrap (Low Grade) |
| quest_bakau_009 | Swarm Suppression | Haruan ×12; Ketam ×8 | quest_bakau_007 | 240 | 6 × Mana Vial (Low Grade) |
| quest_bakau_010 | Rare Tissue Samples | Fish Bone ×3; Dragonfly Antenna ×2; Crab Claw ×1 | quest_bakau_008 | 200 | 6 × Tech Scrap (Low Grade) |

Mana Vial retains ID `craft_cons_001` and path `data/items/components/mana-vile-low-grade.tres`; only the displayed spelling is corrected. Its existing zero mana effect is preserved: the quest grants the item, not an invented restoration effect. Tech Scrap retains ID `craft_cons_004` and its existing Resource. No Bakau currency reward is added. All item reward min/max quantities are identical.

## Source narrative

### quest_bakau_001 — Haruan Hitam Cull

Their population density in the water channels is disrupting ambient mana flow readings. Clear them out.

### quest_bakau_002 — Specimen: Haruan

Fresh specimens only. The mana degradation rate on dead haruan is faster than anything I've documented.

### quest_bakau_003 — Pepatung Patrol

Airborne mana signatures keep corrupting my sensor drones. I need the source dealt with.

### quest_bakau_004 — Wings & Antennae

The wing membrane refracts mana in ways I haven't seen before. Could be useful for conductor research.

### quest_bakau_005 — Ketam Clearance

They've colonised the root platforms entirely. My field team can't set foot in the zone.

### quest_bakau_006 — Shell Harvest

Stone crab shell density increases with ambient mana exposure. I need samples from the deeper platforms.

### quest_bakau_007 — Mana Fauna Survey

A full zone sweep. I need disruption data across all three fauna types simultaneously — partial readings are useless to me.

### quest_bakau_008 — Field Sample Bundle

I need a comparative batch — same collection run, all three specimens. Cross-contamination is a concern if you do it separately.

### quest_bakau_009 — Swarm Suppression

The water and land channels are feeding each other's population growth. Cut both at once or the numbers bounce back within days.

### quest_bakau_010 — Rare Tissue Samples

These are the low drop components. I know it's tedious — but the mana retention in structural tissue is unlike anything from a regulated zone.

## Availability and playability

The four starting quests are 001, 003, 005 and 007. Chains are 001→002, 003→004, 005→006→008→010, and 007→009. These are prerequisite unlocks; the catalogue does not auto-accept them. The board shows all ten, including locked requirements. Crocodile intentionally has no eleventh quest.

Every quest is exercised through production board acceptance, actual enemy death or dropped-item acquisition, ready state, board hand-in, exact XP/item change and repeated-claim rejection in `tests/quest-pipeline.gd`. The field lab offers normal combat, natural drops and manual collection as well as safe debug spawning/defeat controls. See [test instructions](bakau-integration-tests.md).
