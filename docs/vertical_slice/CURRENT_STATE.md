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
- Last audited stable commit before the current change: `f35f051d297c9295366f264963ff906b46b4d82c`
- Last completed system: versioned atomic save core and SAFE/COMMIT persistence policy
- Last validated workflow: Godot Project Validation run `#219`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Campaign marker: `CAMPAIGN_STATE_TEST: PASS`
- Save marker: `SAVE_MANAGER_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 3 — SaveManager, boot and save modes**
- Status: Phase 3 core persistence is complete and validated. The shared registry aggregates providers, SaveMigrator rejects unsupported versions, SAFE exposes historical checkpoints, COMMIT keeps one living record, and a corrupt live file recovers from the hidden technical backup.
- Architectural objective: finish Phase 3 by registering scene-owned state, restoring an active combat between cycles and routing executable startup through the campaign Bootstrap.

## Next exact task

Implement boot and scene-owned persistence in this order:

1. Create `core/bootstrap/bootstrap.tscn` and `bootstrap.gd` as the only executable entry point.
2. Create the campaign selection and new-campaign panels using `SaveManager.list_campaigns()`, `list_checkpoints()`, `create_campaign()` and `load_campaign()`.
3. Make `WindowManager` a `window_states` provider and snapshot every open app before export.
4. Make Navigator a `navigator_state` provider with plain coordinate data and active activity/combat context.
5. Make CombatManager a `combat_session` provider that serializes Resources as content IDs and accepts saves only between logical cycles.
6. Add the full `VS-040` restart reconstruction test before marking Phase 3 complete.

Do not couple SAFE/COMMIT UI policy to section serialization. Both modes use the same schema.

## Phase 3 core persistence checkpoint

- `SaveSectionRegistry` enforces the four-method provider contract and imports all registered sections only after aggregate validation.
- `SaveMigrator` rejects older unsupported and future save versions before runtime mutation.
- `SaveManager` writes a verified temporary file, rotates the prior live file to a hidden technical backup and atomically replaces the official record.
- SAFE MODE writes visible checkpoint history and permits manual saves and historical loads.
- COMMIT MODE writes only the living record, rejects manual saves and rejects historical checkpoint selection.
- CampaignState, TimeManager, GameState and AppSessionStore implement the shared persistence contract without disk I/O.
- Browser history serializes URL/title metadata and resolves favicon Resources again at runtime instead of writing Texture2D objects.
- The save test proves aggregate round-trip, mode policy, future-version rejection and recovery from a corrupt live record.

## Phase 2 implementation checkpoint

- `OperatorStateData`, `TendencyStateData`, `InventoryStateData` and `WorldStateData` own typed mutable subsections.
- `CampaignState` creates, exports, validates, restores and resets a campaign without restarting the executable.
- Exported state contains values and stable IDs only; no Node, Resource, scene, texture, Callable or signal is serialized.
- `GameState` preserves its public flag/number API while delegating authoritative storage to `CampaignState.world_state`.
- `GameContentCatalog` declares APK, Module, Item, Occupation, App, Location, Dialogue, StoryEvent, Lead and Incident categories.
- `ContentRegistry` builds category-scoped indexes atomically and preserves the last valid registry when a candidate contains null, empty or duplicate IDs.
- The default catalog currently indexes eight Modules, Browser, Navigator and Akihabara.

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
- Boot flow, campaign selection UI and scene-owned save providers do not exist yet.
- WindowManager, Navigator and CombatManager are not registered in the aggregate save yet.
- Social and Encyclopedia have reserved plain state sections, but their typed domain models belong to Phases 12 and 13.
- No occupation provider is registered yet; only its stable ActivityManager contract exists.
- No current content uses `allow_cross_day`; the behavior is covered by preview tests for future events.

These are planned in later roadmap phases and must not be solved inside Phase 1.

## Validation commands

Run the existing baseline tests:

```bash
godot --headless --path . --editor --quit
godot --headless --path . tests/campaign/campaign_state_test.tscn
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
