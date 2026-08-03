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

## Change protocol

When a decision changes:

1. Add a new row; do not silently rewrite history.
2. Mark the superseded decision and reference its replacement.
3. Update `ROADMAP.md`, relevant Resources and tests in the same pull request.
4. Record migration impact on existing `.tres` and saves.
