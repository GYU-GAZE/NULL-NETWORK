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
- Last audited stable commit before the current change: `941d7559eacaf50ce4adeeae7383043faf4eb4fc`
- Last completed system: Phase 6 queued and resumable StoryEvent execution
- Last validated workflow: Godot Project Validation run `#236`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Campaign marker: `CAMPAIGN_STATE_TEST: PASS`
- Save marker: `SAVE_MANAGER_TEST: PASS`
- Save runtime marker: `SAVE_RUNTIME_INTEGRATION_TEST: PASS`
- Conditions/effects marker: `CONDITIONS_EFFECTS_TEST: PASS`
- App catalog marker: `APP_CATALOG_TEST: PASS`
- Story event marker: `STORY_EVENT_MANAGER_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 7 — Dialogue system**
- Status: Phase 6 is complete and validated. StoryEvent Resources are triggered by campaign, time, flags and location; StoryEventManager queues and executes them at persisted step boundaries through typed service and presentation intents.
- Architectural objective: execute data-driven Visual Novel scenes inside Navigator, with conditional choices, one-time node effects and mid-scene save/load.

## Next exact task

Begin Phase 7 in this order:

1. Inventory Navigator's reserved DIALOGUE mode, current interaction contract and StoryEvent `START_DIALOGUE` intent.
2. Create DialogueData, DialogueNodeData, DialogueChoiceData, DialoguePortraitState and DialogueSpeakerData with stable IDs and validation.
3. Add persisted dialogue ID, current node ID, executed node effects and selected choices to CampaignState or a dedicated registered save provider.
4. Build DialoguePlayer inside Navigator with six portrait slots, conditional choices and no direct campaign mutation from UI.
5. Route node and choice effects through the Phase 4 effect context; route paid choices through ActivityManager.
6. Complete `VS-080`: save at a dialogue node, rebuild the runtime and prove node effects are not executed twice.

## Phase 6 StoryEvent checkpoint

- `StoryEventCatalog` is the immutable ordered source for event Resources; `ContentRegistry` resolves events by stable ID.
- Trigger Resources cover campaign create/load, time, flag, location and manual triggers with optional filters.
- `StoryEventManager` owns eligibility, priority queueing, repeat/interruption policy and one-at-a-time step execution without absolute Node paths.
- The twelve Roadmap step families dispatch through global services or typed signals: alerts, notifications, apps, Browser navigation, dialogue, encounters, locations, installation, Leads, Effects, Activities and event chaining.
- CampaignState persists queued event IDs, active event/step boundary, waiting state, completed IDs and repeat metadata as JSON-safe values.
- External dialogue/encounter boundaries acknowledge completion by event and step ID; already-completed steps are not redispatched after reload.
- `story.prologue.null_network_welcome` is the integration Resource proving Browser open/navigation, alert/notification, Navigator installation, dialogue intent, Effects and completion save.
- `VS-070` destroys and rebuilds Main while the event waits for dialogue, then proves the exact step resumes once and the ONCE event cannot repeat.

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

- Navigator `DIALOGUE` mode has no dialogue player; this is the active Phase 7 task.
- Combat resolution does not yet apply persistent campaign rewards.
- The player combat loadout still comes from `CombatEncounter`, not a persistent partner.
- No dialogue runtime consumes the StoryEvent dialogue intent yet; the persisted StoryEvent boundary is ready for Phase 7 acknowledgement.
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
godot --headless --path . tests/events/story_event_manager_test.tscn
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
