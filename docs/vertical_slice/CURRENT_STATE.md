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
- Last audited stable commit before the current change: `6c1af9fec831034a6c0f3ce31031fedf13943d5c`
- Last completed system: Phase 10 Player Actions, campaign combat resolution and combat-only evolution
- Last validated workflow: Godot Project Validation run `#261`
- Activity marker: `ACTIVITY_MANAGER_TEST: PASS`
- Campaign marker: `CAMPAIGN_STATE_TEST: PASS`
- Save marker: `SAVE_MANAGER_TEST: PASS`
- Save runtime marker: `SAVE_RUNTIME_INTEGRATION_TEST: PASS`
- Conditions/effects marker: `CONDITIONS_EFFECTS_TEST: PASS`
- App catalog marker: `APP_CATALOG_TEST: PASS`
- Story event marker: `STORY_EVENT_MANAGER_TEST: PASS`
- Dialogue marker: `DIALOGUE_SYSTEM_TEST: PASS`
- Operator marker: `OPERATOR_CREATION_TEST: PASS`
- APK progression marker: `APK_PROGRESSION_TEST: PASS`
- Combat campaign resolution marker: `COMBAT_CAMPAIGN_RESOLUTION_TEST: PASS`
- Runtime marker: `COMBAT_RUNTIME_TEST: PASS`
- Layout marker: `COMBAT_LAYOUT_TEST: PASS`

## Current system

- Roadmap phase: **Phase 11 — Leads, Incidents and Local Area population**
- Status: Phase 10 is complete and validated. Combat now enters from persistent PartnerState, executes Modules and Player Actions in one Timeline, resolves campaign rewards once and can evolve at stable cycle boundaries.
- Architectural objective: connect forum/community discoveries to reusable Leads, Incidents and condition-driven Local Area populations without hardcoded Aquarium paths.

## Next exact task

Begin Phase 11 in this order:

1. Audit existing forum link actions, Navigator badges, `MapLocation.spawn_table`, Local Area interactables and the reserved Lead/Incident catalog categories.
2. Create typed `LeadData`, `LeadStageData`, `LeadCatalog`, `IncidentData` and `IncidentStageData` Resources with stable IDs, conditions, expiration and Effects.
3. Make CampaignState's existing active/completed Lead IDs the authoritative mutable progression, with stage state added as plain ID/value data only when required by the Resources.
4. Implement `LocalAreaSpawnPoint` and `LocalAreaPopulationController` against each MapLocation's existing SpawnTable, restoring resolved actors instead of rerolling them.
5. Connect one forum link to one Lead, badge, paid Incident, dialogue, combat resolution and forum reaction through the shared services.
6. Complete `VS-120`, including save/restart at a stable Lead or Incident boundary.

## Phase 10 combat completion checkpoint

- `PlayerActionData` and `PlayerActionProgressData` define SCAN, PURGE, PURIFY and contextual TAME as Timeline replacements; every committed slot adds 25% to one stable target UID.
- `PlayerActionService` owns assignment legality, one-per-target/encounter policy, PURGE/PURIFY/TAME exclusions and completion state.
- SCAN selects one active Module; PURGE marks the target for increased EXP and deterministic active extraction; PURIFY grants only an installed passive; duplicate Modules convert to configured EXP.
- TAME removes the target without marking it defeated and replaces PartnerState as PURIFIED only after PURIFY; direct TAME creates an EXE-integrity partner.
- `CombatResolutionService` is the sole authority for snapshot write-back, EXP, drops, Modules, tendencies, Encyclopedia discovery, partner replacement and outcome Effects.
- Terminal combat state remains serializable after victory, defeat or escape. Rewards are idempotent and the session finalizes only when presentation confirms the return boundary.
- `CombatTendencyLog` accumulates data-driven temporary behavior; `CombatStyleRuleData` converts at most two points into the campaign at resolution.
- `EvolutionBranchData` separates Core Requirements, alternative Catalysts and stable combat windows. The authored NOVIRE VALOUR branch proves an end-of-cycle offer, immediate stat recalculation and unchanged level/EXP.
- Rattildus provides the integration reward profile, non-extractable Species Signature, transferable installed passive and tameable APK content; it does not replace the final tutorial content pass.
- Defeat remains recoverable. Partner Loss, TURD/LOST and Operator Loss stay reserved for Phase 14.
- `VS-110` proves normal victory, all four Player Actions, active/passive rewards, duplicate conversion, Combat Style, Encyclopedia, level-up, both TAME integrity paths, evolution, escape, defeat and save/restart at 25% progress.

## Phase 9 APK, partner, inventory and progression checkpoint

- `APKData`, personality, address-term, growth-profile and level-reward Resources own immutable species/form content; `PartnerStateData` owns the current individual as JSON-safe values and IDs.
- `CharacterLoadout` is now an entry snapshot. `CombatSlotData.PLAYER_PARTNER` resolves allied slot `0` from CampaignState and writes HP, Stability and equipped Modules back only at a stable result boundary.
- `APKProgressionService` owns controlled personality/address selection, starter creation, the canonical EXP curve through level 100, level rewards and Allocation Points.
- `APKStatCalculator` derives stats from level-100 profiles on demand, keeps Stability at 100 and supports the GDD's weighted growth-lineage recalculation without cumulative rounding.
- Typed `InventoryEntryData` is the inventory source of truth while supported legacy `item_counts` saves remain readable.
- Campaign schema 4 persists complete PartnerState and migrates known legacy `partner_id` values through the same creation service.
- Save sections restore authoritative campaign state before dependent runtime snapshots, allowing an active `PLAYER_PARTNER` CombatSession to reconstruct exactly.
- The cataloged NOVIRE integration starter has the GDD's level-100 profile, three controlled personalities, three address-term choices, four initial Modules and a level-2 Module reward.
- `VS-100` proves formulas, starter individuality, inventory resolution, combat snapshot/write-back, EXP, level-up, reward, allocation, legacy migration and save/restart.

## Phase 8 Operator and occupation checkpoint

- `OperatorProfileData` owns personal identity, NULL NETWORK account, Tokyo/Japan server binding, occupation, avatar, gender and pronouns.
- `AppearanceData` persists body, face, eyes, three clothing layers, hat and facial accessory as stable IDs.
- `OccupationData` and `OccupationScheduleData` define economy, starting location, recurring income, routine event hooks and occupied weekday/action blocks as Resources.
- The catalog contains NEET, High School Student and Salaryperson. Their schedules remain editable data; no app or scene hardcodes occupation rules.
- `OperatorService` is the sole registration authority, requires exactly 15 tendency points and registers one ActivityManager availability provider.
- Schedule availability rejects both activities begun inside an occupied block and activities whose cost crosses into one; StoryEvent-owned routines remain allowed.
- Recurring income advances from the persisted last-payment day and cannot duplicate after save/load.
- `null.net/register` hosts the diegetic creation UI; `prologue.registration_started` opens it and `prologue.registration_completed` reacts to the authoritative registration flag.
- Campaign save schema 3 stores the profile and appearance as plain values while continuing to read prior supported schemas.
- `VS-090` creates all three occupations, rejects a 14-point allocation without mutation, saves/reloads the complete Operator and verifies schedule blocking and weekly income.

## Phase 7 dialogue checkpoint

- `DialogueData`, `DialogueNodeData`, `DialogueChoiceData`, `DialoguePortraitState` and `DialogueSpeakerData` are immutable validated Resources resolved by stable ID.
- `DialogueManager` owns the registered `dialogue_session` save section: active dialogue/node, executed node effects, selected choices and optional StoryEvent boundary.
- Node conditions skip deterministically through `next_node_id`; choice conditions refresh from authoritative flags and campaign state.
- Node effects execute at most once per stable node/effect key. Choice Effects use `GameEffectContext`; tendency changes use CampaignState.
- Paid choices request ActivityManager and transition only after confirmation and charging; cancellation leaves the current node unchanged.
- `DialoguePlayer` is contained by Navigator's DIALOGUE mode and renders three portrait slots on each side, speaker, text, conditional buttons and Advance.
- Local Area DIALOGUE interactions and StoryEvent START_DIALOGUE share the same manager instead of parallel pipelines.
- `dialogue.prologue.null_network_welcome` is the integration Resource; it does not replace the final Phase 15 Prologue dialogue content.
- `VS-080` destroys and rebuilds Main at the choice node and after a paid choice, proving effects, tendencies, time cost, selected choice and StoryEvent acknowledgement do not duplicate.

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
- The default catalog currently indexes eight Modules, Browser, Navigator, Akihabara, the Prologue integration StoryEvent and its dialogue gate.

## Phase 1 implementation checkpoint

- `ActivityDefinitionData` owns cost and crossing policy in immutable content.
- `ActivityPreviewData` exposes final day, period, block, availability and warnings.
- `ActivityManager` owns confirmation, transaction IDs, charging and nested activity inclusion.
- `ActivityConfirmationDialog` is a queued global modal.
- Akihabara travel costs one block through `travel_akihabara.tres`.
- Voluntary Rattildus combat costs two blocks at FIGHT confirmation through `fight_rattildus.tres`.
- The activity test instantiates Navigator, travels, starts combat and proves resolution adds no second cost.
- The ActivityManager availability-provider contract is now consumed by the Phase 8 occupation schedule without coupling it to Navigator.

## Known non-blocking gaps

- Only NOVIRE has an authored starter integration Resource; the other four Prologue starter choices remain final content work.
- Social and Encyclopedia have reserved plain state sections, but their typed domain models belong to Phases 12 and 13.
- Only the NOVIRE VALOUR evolution branch and Rattildus campaign reward profile are authored integration content; the remaining branches and EXE families belong to later content work.
- Lead/Incident Resources and condition-driven Local Area population do not exist yet; this is the active Phase 11 task.
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
godot --headless --path . tests/dialogue/dialogue_system_test.tscn
godot --headless --path . tests/operator/operator_creation_test.tscn
godot --headless --path . tests/progression/apk_progression_test.tscn
godot --headless --path . tests/combat/combat_campaign_resolution_test.tscn
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
