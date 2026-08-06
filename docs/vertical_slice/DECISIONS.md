# NULL NETWORK — FROZEN VERTICAL SLICE DECISIONS

This log records canonical decisions that implementation must preserve. Change a frozen decision only through an explicit design decision in a dedicated pull request.

| ID | Decision | Architectural consequence | Source |
|---|---|---|---|
| DVS-001 | A day contains 12 DAY blocks and 12 NIGHT blocks. | Time conditions use `days_passed`, `current_period` and `current_action_block` with block range `0–11`. | GDD: Time and Actions |
| DVS-002 | Morning, noon, afternoon, evening and madrugada are presentation text only. | No new gameplay condition or save field may use those concepts. | Roadmap §2.1 |
| DVS-003 | Free activities cost 0; simple activities normally cost 1; complex activities normally cost 2 or more. | Cost belongs to data, not to UI-specific branches. | GDD: Action Costs |
| DVS-004 | A voluntary combat costs 2 blocks at confirmation. | The cost is committed before the encounter opens, never after its result. | GDD: Player-initiated Combat |
| DVS-005 | A combat embedded in a paid Lead, Incident, Data Center or event costs 0 additional blocks. | Parent and child share one `activity_transaction_id`. | GDD: Event-imposed Combat |
| DVS-006 | One narrative unit never charges twice for the same time interval. | Nested activities reuse the owning transaction instead of advancing time again. | Roadmap §2.2 |
| DVS-007 | Activities may cross DAY→NIGHT when allowed, but may not cross the absolute day boundary unless content explicitly permits it. | Preview calculates the final day, period and block before confirmation. | GDD: DAY and NIGHT Transition |
| DVS-008 | Every paid activity shows cost, final period/block, crossing information, availability and expiration risk before confirmation. | UI consumes `ActivityPreviewData`; it does not duplicate time math. | GDD: Confirmation and Transparency |
| DVS-009 | SCAN, PURGE, PURIFY and TAME occupy Timeline slots and add 25% progress per use. | Player Actions are combat actions, not a post-combat menu. | GDD: Player Actions |
| DVS-010 | VALOUR currently has no dedicated Player Action. | Do not invent a fifth action during the vertical slice. | GDD: Player Actions |
| DVS-011 | SAFE MODE allows historical checkpoints; COMMIT MODE exposes one living record. | Both modes share one save schema and differ through save policy. | GDD: Save Modes |
| DVS-012 | Resources define immutable content; saves contain mutable state and stable IDs. | Never serialize Nodes, scenes, textures, Resources, Callables or signals as campaign state. | Roadmap §4 |
| DVS-013 | The Prologue is `CampaignPhase.PROLOGUE`, not day zero. | Main campaign starts at `days_passed = 1`, DAY block 0. | Roadmap §21 |
| DVS-014 | Navigator owns presentation modes for World Map, Local Area, Dialogue and Combat. | Dialogue and Combat remain contained without app-to-app direct calls. | Roadmap §6 |
| DVS-015 | Apps communicate through signals and global services, not absolute Node paths or direct cross-app references. | Story events and app installation publish intents; presentation nodes respond. | Project rules |
| DVS-016 | UI never grants rewards or mutates campaign progression directly. | Services resolve rewards and state; UI only displays decisions and results. | Roadmap Definition of Done |
| DVS-017 | The vertical slice limits content volume, not structural quality. | Every system is final-form, data-driven and reusable beyond the Aquarium. | Project programming rule |
| DVS-018 | `APKData` is immutable species/form content; `PartnerStateData` is the persistent individual. | Saves contain partner values and stable IDs, while `CharacterLoadout` exists only as a combat snapshot. | GDD: APK and Partner progression; Roadmap Phase 9 |
| DVS-019 | Partner stats are recalculated from level-100 profiles, level and Allocation Points instead of accumulating rounded deltas. | Level-up, evolution and load produce deterministic stats; Stability maximum remains 100 and recovery is separate. | GDD: APK stat growth |
| DVS-020 | Save authorities restore before runtime snapshots that resolve them. | CampaignState must import before CombatSession; dynamic presentation sections may remain pending until their providers register. | Persistence dependency exposed by Phase 9 |
| DVS-021 | Applying combat resolution and finalizing the encounter are separate stable boundaries. | The resolved session remains saveable; rewards are idempotent; UI confirms exit only after the service result exists. | GDD combat consequences; Roadmap Phase 10 |
| DVS-022 | **Superseded by DVS-028.** Ordinary defeat remained recoverable only while Phase 10 lacked the irreversible lifecycle. | Do not restore the old generic one-HP policy for primary partners. | Historical Phase 10 boundary |
| DVS-023 | SCAN and PURGE extract only active Modules; PURIFY grants only Installed Passives; Species Signatures and other intrinsic traits are not extractable. | Reward profiles separate active and purification pools and ContentRegistry validates their Module kinds. | GDD: Player Actions and Module taxonomy |
| DVS-024 | Evolution occurs only during combat at declared stable windows and preserves level, EXP, individual identity and HP ratio. | Branches separate Core Requirements from alternative Catalysts; CombatManager rebuilds the partner snapshot after acceptance. | GDD: Evolution; Roadmap Phase 10 |
| DVS-025 | Lead and Incident Resources are immutable content; CampaignState stores only active/completed IDs and plain progress values. | `LeadIncidentManager` is the sole progression authority, and Forum/Navigator communicate through stable intents and signals rather than cross-app node references. | GDD: Leads and Incidents; Roadmap Phase 11 |
| DVS-026 | A Local Area population generation is stable for one campaign, location, day and period. | `SpawnTable` rolls deterministically and WorldState persists actor descriptors/resolution; reopening or restarting cannot reroll the same generation. | GDD: Map Location and SpawnTable; Roadmap Phase 11 |
| DVS-027 | A paid Incident owns its dialogue and included combat under one Activity transaction. | Time is charged once at confirmation; encounter resolution completes or returns the Incident to READY without adding another cost. | GDD: Action Costs and Incidents; DVS-005/DVS-006; Roadmap Phase 11 |
| DVS-028 | Partner Loss is controlled by `CombatResolutionData.partner_loss_policy`; ordinary EXE combat is definitive when the primary partner reaches 0 HP. | Combat content may explicitly be recoverable, definitive only on defeat, or definitive whenever HP reaches zero. The manager does not hardcode exceptions by app or encounter ID. | GDD: Partner Loss; Phase 14 implementation |
| DVS-029 | TURD is assigned automatically after the first Partner Loss; it is never acquired through TAME. | `TurdPartnerFactory` creates the Operator's emergency fallback when no persisted TURD exists. TAME is not a TURD acquisition path. | Project-owner clarification, 2026-08-06 |
| DVS-030 | Each Operator owns one persistent TURD individual. | TURD moves between `CampaignState.partner` and `OperatorStateData.partner_continuity.turd_reserve`; level, EXP, HP, Stability, affinity, allocations and equipped Modules cannot reset during this transition. | Project-owner clarification, 2026-08-06 |
| DVS-031 | TAME while TURD is active establishes a new primary partner and preserves TURD in reserve. Losing that replacement restores the same TURD. | Active-partner replacement and TURD continuity are separate operations; no second TURD is created while a valid reserve exists. | Project-owner clarification, 2026-08-06 |
| DVS-032 | **Superseded by DVS-034.** TURD temporarily retained the one-HP safeguard while Operator Loss had no runtime transition. | Do not restore the temporary safeguard after Phase 14.2. | Historical Phase 14.1 boundary |
| DVS-033 | Operator Loss does not reset campaign time or world consequences. | New Operator creation preserves `TimeManager`, infestation, completed events, completed Leads/Incidents and persistent world objects while resetting identity-owned state. | GDD: Operator Loss |
| DVS-034 | TURD reaching 0 HP in a definitive encounter immediately causes Operator Loss. | The current Operator and destroyed TURD are archived, `CampaignPhase.OPERATOR_LOSS` is entered and an irreversible checkpoint is requested. | GDD: Operator Loss; Phase 14.2 implementation |
| DVS-035 | A successor Operator starts without the previous Operator's identity, relationships, tendencies, active partner, money, inventory, learned Modules, Encyclopedia, browser history or app sessions. | Operator-scoped and destroyed-device state is cleared. Completed world history, the countdown and physical world remain authoritative. | GDD: Operator Loss and Legacy Recovery |
| DVS-036 | Operator Loss creates a persistent Legacy Site at the exact loss location. | The broken KubuOS Handtop seals potentially recoverable material/log data by stable IDs, but never restores the dead APK/TURD, affinity, friend list, ranking, reputation, tendencies or personal identity. | GDD: Legacy Site and Legacy Recovery |
| DVS-037 | The successor receives a clean device lifecycle. | Default apps reinstall through `AppInstallationManager`; Navigator is reinstalled only after the successor selects a starter and returns to `MAIN_CAMPAIGN`. | Phase 14.2 implementation |
| DVS-038 | Infestation consequences are authored in `CombatResolutionData`. | Partner Loss and Operator Loss increases may vary by encounter without hardcoded encounter IDs; Operator Loss cannot be configured lower than Partner Loss. | GDD: Area consequences; Phase 14.2 implementation |

## Change protocol

When a decision changes:

1. Add a new row; do not silently rewrite history.
2. Mark the superseded decision and reference its replacement.
3. Update `ROADMAP.md`, relevant Resources and tests in the same pull request.
4. Record migration impact on existing `.tres` and saves.
