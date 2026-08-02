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
- Last audited stable commit before the current change: `c6685ce7333a3d6d92f8c30162ee4dcf0cfdb15d`
- Last completed system: serializable campaign state and ID-based content registry
- Last validated workflow: Godot Project Validation run `#215`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Campaign marker: `CAMPAIGN_STATE_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 3 — SaveManager, boot and save modes**
- Status: Phase 2 is complete and validated. CampaignState exports and restores plain ID-based data, resets deterministically and owns world flags/numbers. ContentRegistry resolves the current catalog and rejects invalid catalogs atomically.
- Architectural objective: aggregate save sections, write them atomically and restore the complete runtime through a boot flow shared by SAFE and COMMIT policies.

## Next exact task

Implement the persistence contract before creating campaign selection UI:

1. Create `core/save/save_constants.gd` with schema version, paths and technical-backup names.
2. Create `core/save/save_section_registry.gd` with the final section-provider contract.
3. Adapt CampaignState, GameState and TimeManager to the contract without adding disk I/O to them.
4. Create `core/save/save_migrator.gd` and make unsupported future versions fail safely.
5. Create `core/autoloads/save_manager.gd` with temporary write, validation, technical backup and atomic replacement.
6. Test an in-process aggregate round-trip and interrupted replacement before building `bootstrap.tscn` or save-selection UI.

Do not couple SAFE/COMMIT UI policy to section serialization. Both modes use the same schema.

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
- Save files, boot flow, campaign selection and SAFE/COMMIT runtime policy do not exist.
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
