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
- Last audited stable commit before the current change: `6e32556f47e55f257563b747aa22a1bae1e11c32`
- Last completed system: activity previews, confirmations and single-charge transactions
- Last validated workflow: Godot Project Validation run `#209`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 2 — CampaignState and content registries**
- Status: Phase 1 is complete and validated. Navigator travel, paid EXAMINE interactions and voluntary EXE combat no longer advance TimeManager directly.
- Architectural objective: create one serializable campaign source of truth and resolve immutable content through stable IDs.

## Next exact task

Implement the campaign state foundation in this order:

1. Create `operator_state_data.gd`, `tendency_state_data.gd`, `world_state_data.gd` and `inventory_state_data.gd`.
2. Create `core/autoloads/campaign_state.gd` with explicit defaults and a complete runtime reset.
3. Create `game_content_catalog.gd` and `game_content_catalog.tres`.
4. Create `core/autoloads/content_registry.gd` and reject duplicate or empty IDs.
5. Add tests that create, mutate and reset a campaign without restarting the executable.
6. Add tests that resolve at least one existing Module and reject a duplicate ID.

Do not begin SaveManager until CampaignState can export plain ID-based data and reset deterministically.

## Phase 1 implementation checkpoint

- `ActivityDefinitionData` owns cost and crossing policy in immutable content.
- `ActivityPreviewData` exposes final day, period, block, availability and warnings.
- `ActivityManager` owns confirmation, transaction IDs, charging and nested activity inclusion.
- `ActivityConfirmationDialog` is a queued global modal.
- Akihabara travel costs one block through `travel_akihabara.tres`.
- Voluntary Rattildus combat costs two blocks at FIGHT confirmation through `fight_rattildus.tres`.
- The activity test instantiates Navigator, travels, starts combat and proves resolution adds no second cost.
- Availability providers are ready for the Phase 8 occupation schedule without coupling it to Navigator.

## Known non-blocking gaps

- Navigator `DIALOGUE` mode has no dialogue player.
- Combat resolution does not yet apply persistent campaign rewards.
- The player combat loadout still comes from `CombatEncounter`, not a persistent partner.
- App installation and campaign persistence do not exist.
- No occupation provider is registered yet; only its stable ActivityManager contract exists.
- No current content uses `allow_cross_day`; the behavior is covered by preview tests for future events.

These are planned in later roadmap phases and must not be solved inside Phase 1.

## Validation commands

Run the existing baseline tests:

```bash
godot --headless --path . --editor --quit
godot --headless --path . tests/activity/activity_manager_test.tscn
godot --headless --path . tests/combat/combat_runtime_test.tscn
godot --headless --path . tests/combat/combat_layout_test.tscn
```

## Completion rule

A phase is complete only when:

- its gate in `ROADMAP.md` is satisfied;
- the corresponding rows in `TEST_MATRIX.md` are `PASS`;
- this file points to the next phase and exact first task;
- the stable baseline and evidence are updated.
