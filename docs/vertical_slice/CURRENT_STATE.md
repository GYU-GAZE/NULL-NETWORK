# NULL NETWORK — CURRENT STATE

> Read this file first when resuming the project. Update it in the same pull request that changes the active phase.

## Resume in under five minutes

1. Read the **Current system** and **Next exact task** sections below.
2. Open the listed files only.
3. Run the listed validation scene before editing.
4. Check `DECISIONS.md` before changing a frozen rule.
5. Record new coverage in `TEST_MATRIX.md` before marking a phase complete.

## Stable baseline

- Base branch: `main`
- Last audited stable commit: `4aa63512a4b335d7cf7f2dff8cd6127f43e63652`
- Last completed system: combat presentation contracts and editable combat UI components
- Last validated workflow: Godot Project Validation run `#204`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 1 — Time and activity transactions**
- Status: Phase 0 documentation is complete in the current change; the legacy ConditionData block range is corrected from `0–5` to `0–11`.
- Architectural objective: make `ActivityManager` the only campaign-facing gateway that may advance `TimeManager`.

## Next exact task

Implement the activity transaction foundation in this order:

1. Create `data/templates/activity/activity_definition_data.gd`.
2. Create `data/templates/activity/activity_preview_data.gd`.
3. Create `core/autoloads/activity_manager.gd`.
4. Register `ActivityManager` in `project.godot`.
5. Add deterministic tests for preview, confirmation, cancellation, DAY→NIGHT crossing, end-of-day rejection and nested transaction reuse.
6. Only after the manager gate passes, integrate travel, EXAMINE and voluntary EXE combat.

Do not remove direct `TimeManager.advance_action()` calls until their replacement path is tested.

## Files in the current change

- `docs/vertical_slice/ROADMAP.md`
- `docs/vertical_slice/CURRENT_STATE.md`
- `docs/vertical_slice/DECISIONS.md`
- `docs/vertical_slice/TEST_MATRIX.md`
- `docs/vertical_slice/CONTENT_MANIFEST.md`
- `data/templates/condition_data.gd`

## Confirmed technical debt blocking Phase 1

- `apps/navigator/app_navigator.gd` advances time directly for travel, EXAMINE and combat resolution.
- `LocalAreaExeActor` computes combat cost after combat resolution; the canonical rule charges a voluntary combat when the player confirms entry.
- The current default EXE cost is one block; voluntary combat must use two blocks.
- There is no transaction ID shared by a paid parent activity and its child combat.
- There is no confirmation UI for time-consuming activities.
- There is no rule preventing an activity from crossing the absolute end of the day.
- Occupation schedule blocking does not exist yet; Phase 1 must expose a stable hook that Phase 8 can supply later.

## Known non-blocking gaps

- Navigator `DIALOGUE` mode has no dialogue player.
- Combat resolution does not yet apply persistent campaign rewards.
- The player combat loadout still comes from `CombatEncounter`, not a persistent partner.
- App installation and campaign persistence do not exist.

These are planned in later roadmap phases and must not be solved inside Phase 1.

## Validation commands

Run the existing baseline tests:

```bash
godot --headless --path . --editor --quit
godot --headless --path . tests/combat/combat_runtime_test.tscn
godot --headless --path . tests/combat/combat_layout_test.tscn
```

Phase 1 must add its own headless test scene and marker before integration reaches the Navigator.

## Completion rule

A phase is complete only when:

- its gate in `ROADMAP.md` is satisfied;
- the corresponding rows in `TEST_MATRIX.md` are `PASS`;
- this file points to the next phase and exact first task;
- the stable baseline and evidence are updated.
