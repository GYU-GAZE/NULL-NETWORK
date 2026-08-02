# NULL NETWORK — VERTICAL SLICE TEST MATRIX

States: `PLANNED`, `READY`, `PASS`, `FAIL`, `BLOCKED`.

| ID | Phase | Precondition | Actions | Expected result | State | Evidence |
|---|---:|---|---|---|---|---|
| VS-000 | Baseline | `main@4aa6351` imports in Godot 4.6.3 | Run combat runtime test | Modular combat, barrier, repeated execution, dummies and presentation events pass | PASS | Godot Project Validation #204 |
| VS-001 | Baseline | `main@4aa6351` imports in Godot 4.6.3 | Run combat layout test | Editable combat scenes and 2×/1× layout pass | PASS | Godot Project Validation #204 |
| VS-010 | 0 | Fresh project resume | Read `CURRENT_STATE.md` | Active phase, next file, next behavior and validation command found in under five minutes | READY | Manual gate after merge |
| VS-011 | 0 | Roadmap docs exist | Search decision IDs and content manifest | Frozen rules and required slice content are traceable | READY | Documentation review |
| VS-020 | 1 | DAY block 6–11 | Evaluate legacy `ConditionData` with matching range | Condition may match all twelve blocks | PASS | Validation #209 · `ACTIVITY_MANAGER_TEST: PASS` |
| VS-021 | 1 | DAY block 11, activity cost 2, crossing allowed | Build preview and confirm | Final time is NIGHT block 1; cost applies exactly once | PASS | Validation #209 · `ACTIVITY_MANAGER_TEST: PASS` |
| VS-022 | 1 | NIGHT block 11, activity cost 2, cross-day denied | Build preview | Activity rejected with required and available blocks | PASS | Validation #209 · `ACTIVITY_MANAGER_TEST: PASS` |
| VS-023 | 1 | Paid activity preview visible | Cancel confirmation | Time and transaction state remain unchanged | PASS | Validation #209 · `ACTIVITY_MANAGER_TEST: PASS` |
| VS-024 | 1 | Parent activity cost 2 owns transaction | Start child encounter with same transaction ID | Child combat adds no cost | PASS | Validation #209 · `ACTIVITY_MANAGER_TEST: PASS` |
| VS-025 | 1 | Travel to a different district | Confirm travel | Exactly one block is spent before area transition completes | PASS | Validation #209 · Navigator integration |
| VS-026 | 1 | Voluntary EXE interaction | Confirm FIGHT | Exactly two blocks are spent before encounter; result adds no cost | PASS | Validation #209 · Navigator integration |
| VS-027 | 1 | Confirmation dialog is open | Close owning app/window | No time is spent and request is cancelled | PASS | Validation #209 · dialog/source cancellation |
| VS-030 | 2 | Empty runtime | Create, mutate, export, reset and restore campaign | All tested sections round-trip as plain ID-based data and reset without restarting | PASS | Validation #215 · `CAMPAIGN_STATE_TEST: PASS` |
| VS-031 | 2 | Catalog contains existing Module, App and Location IDs | Resolve IDs; submit duplicate and empty IDs | Correct Resources resolve; invalid catalogs are rejected without replacing the valid registry | PASS | Validation #215 · `CAMPAIGN_STATE_TEST: PASS` |
| VS-040 | 3 | Browser, Navigator and Combat have runtime state | Save after one combat cycle; restart | Tabs, windows, area, position and combat reconstruct from IDs | PLANNED | — |
| VS-041 | 3 | Previous save exists | Interrupt atomic replacement | Official save remains valid or technical backup restores it | PLANNED | — |
| VS-050 | 4 | Composite content condition | Evaluate time, flag and tendency rules | ALL/ANY/NONE composition is deterministic | PLANNED | — |
| VS-060 | 5 | Navigator is locked | Apply installation effect | Dock adds one Navigator icon live and save preserves it | PLANNED | — |
| VS-070 | 6 | Eligible StoryEvent exists | Advance time or set trigger flag | Event queues and resumes from saved step index | PLANNED | — |
| VS-080 | 7 | Dialogue with conditional choices | Save at a node and reload | Node effects do not execute twice | PLANNED | — |
| VS-090 | 8 | Operator creation open | Allocate trends and choose occupation | Exactly 15 points required; profile and schedule persist | PLANNED | — |
| VS-100 | 9 | Persistent partner exists | Enter and leave combat | Combat loadout is a snapshot; HP, STB, EXP and Modules return to PartnerState | PLANNED | — |
| VS-110 | 10 | EXE survives four Player Action slots | Use SCAN/PURGE/PURIFY/TAME | Per-target progress reaches 100% and correct resolution is applied | PLANNED | — |
| VS-120 | 11 | Aquarium thread provides Lead | Follow Lead to district | Badge, activity, dialogue, combat and forum reaction share state | PLANNED | — |
| VS-130 | 12 | NPC contact is known | Receive DM and invite NPC | History, affinity and temporary party membership persist | PLANNED | — |
| VS-140 | 13 | Combat resolved | Open Profile, Encyclopedia and Calendar; restart | Progress, EXE record and known event persist | PLANNED | — |
| VS-150 | 14 | Definitive test encounter | Lose partner, recover through TAME, then lose TURD | Partner Loss, Operator Loss, new Operator and world day continuity are coherent | PLANNED | — |
| VS-160 | 15 | New campaign | Complete Prologue without debug | Operator, starter, apps, tutorial and location restore after restart | PLANNED | — |
| VS-170 | 16 | Main Campaign Monday begins | Play through Aquarium Incident | Week advances even with ignored Leads and ends with observable state differences | PLANNED | — |

## Evidence rule

A row becomes `PASS` only when it links to a stable commit or CI run and names the automated marker or exact manual reproduction. A failing row must include the first failing assertion or reproduction step.
