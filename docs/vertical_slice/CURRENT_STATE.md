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
- Last audited stable commit before the current change: `60fcaeb885d71ab9cff29495e32c9e54e73d1b04`
- Last completed system: Phase 5 dynamic app catalog and installation
- Last validated workflow: Godot Project Validation run `#232`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Campaign marker: `CAMPAIGN_STATE_TEST: PASS`
- Save marker: `SAVE_MANAGER_TEST: PASS`
- Save runtime marker: `SAVE_RUNTIME_INTEGRATION_TEST: PASS`
- Conditions/effects marker: `CONDITIONS_EFFECTS_TEST: PASS`
- App catalog marker: `APP_CATALOG_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 6 — StoryEventManager**
- Status: Phase 5 is complete and validated. App definitions are ordered by an immutable AppCatalog; installations belong to CampaignState; AppInstallationManager applies conditions, effects and notifications; the Dock projects installed IDs live.
- Architectural objective: connect time, flags, Browser, Social, Navigator, dialogue and combat through queued, resumable StoryEvent Resources without direct app coupling.

## Next exact task

Begin Phase 6 in this order:

1. Inventory every signal that can make an event eligible: time, campaign flags, location and campaign load.
2. Create StoryEventData, StoryEventTriggerData, StoryEventStepData and StoryEventCatalog Resources with validation and stable IDs.
3. Add persisted event queue, active event ID, current step index and completion/repeat state to CampaignState.
4. Create StoryEventManager as a single queued executor that emits presentation intents instead of resolving Node paths.
5. Implement the initial step families listed in Roadmap §12 and resume only from stable step boundaries.
6. Complete `VS-070`: one real StoryEvent Resource queues from a trigger, advances, saves and resumes without duplicating completed steps.

## Phase 5 app catalog checkpoint

- `AppCatalog` is the single ordered immutable app list and is embedded into GameContentCatalog instead of duplicating its array.
- AppResource owns default-install, unlock Conditions, sort order, installation Effects and notification content; installed state remains ID-only in CampaignState.
- `AppInstallationManager` validates unlocks, keeps repeated installation idempotent, applies configured Effects and publishes KubuOS notifications.
- Browser is installed by default during campaign creation/load; Navigator remains absent until an UnlockAppEffectData succeeds.
- `KubuBottomDock` incrementally synchronizes catalog order against installed IDs, so live unlock does not rebuild existing icons.
- WindowManager and WorkspaceManager retain their existing singleton behavior for WINDOW and WORKSPACE apps.
- `VS-060` proves locked absence, live Navigator installation, ordered Dock icons, Effects, notification, save/load and singleton Browser/Navigator instances.

## Phase 4 conditions/effects checkpoint

- `ConditionRuleData` is the fail-closed base contract; `ConditionSetData` recursively composes `ALL`, `ANY` and `NONE` and detects cycles.
- Flag, time, location, tendency, affinity, partner and occupation rules query authoritative managers/state and accept stable context IDs where needed.
- `GameEffectContext` carries `source_id`, `target_id`, `location_id`, `activity_transaction_id` and `event_id` without runtime Nodes or Resources.
- `ConditionalEffectBundleData` lets any content Resource own conditions and an ordered effect list without UI-specific branches.
- Effects cover flags, numbers, tendencies, apps, locations, items, Modules, Leads and affinity; registered content IDs resolve through `ContentRegistry`.
- `CampaignState` exposes stable mutation APIs for tendency, inventory and affinity, with affinity stored inside the already persisted Social section.
- `ForumPost`, `ThreadButtonData` and `CombatSlotData` now consume `ConditionSetData`; all stale `.tres` references and the legacy `condition_data.gd` were removed.
- `GlobalTextCatalog` separates reusable UI text by buttons, labels, errors, confirmations, menus, generic messages and tab names; narrative text remains in narrative Resources.
- `VS-050` loads one composed `.tres`, evaluates every rule family, applies every effect family and round-trips the resulting campaign state.

## Phase 3 core persistence checkpoint

- `SaveSectionRegistry` enforces the four-method provider contract and imports all registered sections only after aggregate validation.
- `SaveMigrator` rejects older unsupported and future save versions before runtime mutation.
- `SaveManager` writes a verified temporary file, rotates the prior live file to a hidden technical backup and atomically replaces the official record.
- SAFE MODE writes visible checkpoint history and permits manual saves and historical loads.
- COMMIT MODE writes only the living record, rejects manual saves and rejects historical checkpoint selection.
- CampaignState, TimeManager, GameState and AppSessionStore implement the shared persistence contract without disk I/O.
- Browser history serializes URL/title metadata and resolves favicon Resources again at runtime instead of writing Texture2D objects.
- The save test proves aggregate round-trip, mode policy, future-version rejection and recovery from a corrupt live record.
- `GameBootstrap` is the executable entry point and instantiates `core/main.tscn` only after campaign creation or load succeeds.
- Campaign selection exposes historical checkpoints only in SAFE; COMMIT creation requires explicit acknowledgement and loads only its living record.
- `WindowManager` serializes open apps, focus and normalized window geometry; app scenes with dedicated providers are not duplicated in `AppSessionStore`.
- Navigator serializes location, plain numeric coordinates, interactable runtime state and active encounter context.
- CombatSession resolves Encounter, Character, Module, Status and Dummy IDs through `ContentRegistry`, restores typed runtime state and rebuilds the Timeline.
- Automatic checkpoints are queued at activity, time and stable combat-cycle boundaries; combat refuses saves while a cycle is executing.
- `VS-040` destroys the complete desktop tree and proves Browser tabs/thread, moved window, Akihabara position and active combat reconstruction on a second Bootstrap.

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
- Story events do not yet coordinate app opening, navigation, dialogue or encounters; this is the active Phase 6 task.
- Social and Encyclopedia have reserved plain state sections, but their typed domain models belong to Phases 12 and 13.
- No occupation provider is registered yet; only its stable ActivityManager contract exists.
- No current content uses `allow_cross_day`; the behavior is covered by preview tests for future events.

These are planned in their listed roadmap phases and must not be pulled forward into unrelated changes.

## Validation commands

Run the existing baseline tests:

```bash
godot --headless --path . --editor --quit
godot --headless --path . core/bootstrap/bootstrap.tscn --quit-after 2
godot --headless --path . tests/campaign/campaign_state_test.tscn
godot --headless --path . tests/activity/activity_manager_test.tscn
godot --headless --path . tests/conditions/conditions_effects_test.tscn
godot --headless --path . tests/apps/app_catalog_test.tscn
godot --headless --path . tests/save/save_manager_test.tscn
godot --headless --path . tests/save/save_runtime_integration_test.tscn
godot --headless --path . tests/combat/combat_runtime_test.tscn
godot --headless --path . tests/combat/combat_layout_test.tscn
```

## Completion rule

A phase is complete only when:

- its gate in `ROADMAP.md` is satisfied;
- the corresponding rows in `TEST_MATRIX.md` are `PASS`;
- this file points to the next phase and exact first task;
- the stable baseline and evidence are updated.
