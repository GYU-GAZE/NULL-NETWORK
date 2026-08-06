# NULL NETWORK — CURRENT STATE

> Read this file first when resuming the project. Update it whenever the active phase or next exact task changes.

## Resume in under five minutes

1. Read **Current system** and **Next exact task**.
2. Open only the files listed under **Active files**.
3. Run the validation scenes under **Required validation**.
4. Check `DECISIONS.md` before changing frozen rules.
5. Update `TEST_MATRIX.md` before declaring a gate complete.

## Current system

- Base branch: `main`
- Roadmap phase: **Phase 14 — Commitment, Partner Loss, TURD and Operator Loss**
- Current subphase: **14.1 Partner Loss and persistent TURD continuity**
- Phase 12: implemented; party participation and shared EXP were manually confirmed.
- Phase 13.1 Profile: implemented and manually confirmed.
- Phase 13.2 Encyclopedia: typed foundation implemented; final behavior and UX deferred by project-owner decision.
- Phase 13.3 Calendar: implemented and manually confirmed functional; final calendar-like UX deferred.
- Phase 14.1: implementation authored; runtime/CI validation pending.
- Latest implementation head before this documentation checkpoint: `5f075d3a9301bb6f05a6ea35c48df5e2fca68844`

The campaign loop now reaches the first permanent Operator-partner consequence:

```text
primary partner reaches 0 HP in a definitive encounter
→ Partner Loss
→ defeated partner is archived as LOST
→ location infestation increases
→ TURD is assigned automatically
→ campaign continues
```

TURD continuity is Operator-owned:

```text
TURD active
→ TURD gains levels, affinity, allocation and equipped Modules
→ TAME establishes a new primary partner
→ TURD moves into the inactive reserve without resetting
→ new primary partner is later lost
→ the same TURD returns with the same state
```

## Canonical Phase 14 decisions

- TURD is never obtained through TAME.
- TURD is assigned automatically after the first Partner Loss.
- Each Operator owns one persistent TURD state.
- TAME while TURD is active changes only the active primary partner; TURD is preserved in reserve.
- Losing a replacement primary partner restores the same TURD.
- TURD reaching 0 HP leads to Operator Loss. The full Operator Loss transition is the next subphase.
- Days, countdown and world state do not reset during Operator Loss.

## Next exact task

### First: validate Phase 14.1

Run:

```text
Godot --headless --path . tests/commitment/partner_loss_turd_continuity_test.tscn
Godot --headless --path . tests/combat/combat_campaign_resolution_test.tscn
```

Confirm:

```text
TURD resolves from ContentRegistry;
ordinary EXE combat uses a data-driven definitive Partner Loss policy;
NOVIRE at 0 HP is archived and replaced automatically by TURD;
TURD progression and equipped Modules persist through TAME;
a later primary Partner Loss restores the same TURD;
lost-partner history and infestation survive save/reload;
TURD at 0 HP reports the Operator Loss boundary.
```

### Then: implement Phase 14.2 — Operator Loss

```text
TURD reaches 0 HP
→ archive current Operator and TURD
→ set CampaignPhase.OPERATOR_LOSS
→ preserve TimeManager and WorldState
→ create a persistent Legacy Site record at the loss location
→ return to Operator creation
→ register a new Operator inside the same campaign
→ reset identity-owned state only
→ keep days, countdown, infestation and world consequences
```

## Active files

### Commitment state and rules

```text
data/templates/apk/partner_continuity_state_data.gd
data/templates/campaign/operator_state_data.gd
systems/commitment/turd_partner_factory.gd
systems/commitment/partner_continuity_service.gd
systems/commitment/partner_loss_service.gd
```

### Combat integration

```text
data/templates/combat/combat_resolution_data.gd
data/content/combat/resolutions/default_exe_resolution.tres
systems/combat/combat_campaign_manager.gd
systems/combat/combat_resolution_service.gd
```

### TURD content and registry

```text
data/content/apks/system/turd_init.tres
data/content/game_content_catalog.tres
```

### Validation

```text
tests/commitment/partner_loss_turd_continuity_test.gd
tests/commitment/partner_loss_turd_continuity_test.tscn
tests/combat/combat_campaign_resolution_test.gd
.github/workflows/partner-loss-turd-validate.yml
.github/workflows/godot-validate.yml
```

## Phase 14.1 architecture

### Active partner authority

`CampaignState.partner` remains the single active partner used by Profile, progression and combat. Existing systems do not need a parallel active-partner API.

### Operator-owned continuity

`OperatorStateData.partner_continuity` owns:

```text
turd_reserve
lost_partner_history
```

The reserve contains a complete `PartnerStateData`, including:

```text
APK ID and integrity;
nickname and personality;
level and current EXP;
HP and Stability;
affinity;
allocation points and allocated stats;
known and equipped active Modules;
secondary passive Module.
```

The save still stores only JSON-safe dictionaries and stable IDs. Legacy Operator saves without `partner_continuity` load with an empty continuity state.

### Data-driven loss policy

`CombatResolutionData.partner_loss_policy` supports:

```text
RECOVERABLE
DEFINITIVE_ON_DEFEAT
DEFINITIVE_AT_ZERO_HP
```

The ordinary EXE resolution is authored as `DEFINITIVE_AT_ZERO_HP`. Special tutorial, narrative or protected encounters may use a recoverable policy without combat-manager hardcode.

### Irreversible consequences

Partner Loss and TAME request irreversible checkpoints. Partner Loss also:

```text
archives the lost PartnerState;
increases current-location infestation by one;
marks the matching Encyclopedia entry LOST when one exists;
emits partner/operator/world state changes for projections.
```

## Prior phase checkpoints

### Phase 12

NPC identity, Friend List, Social conversations, objective-owned party membership, party combat injection, shared EXP and permanent NPC-partner loss are implemented.

### Phase 13

- Profile is a read-only projection of Operator and partner state.
- Encyclopedia has a typed confirmed-knowledge foundation but requires redesign.
- Calendar is a read-only projection of time, occupation and known events; its current UX requires redesign.

## Required validation

### Phase 14.1

```text
Godot --headless --path . tests/commitment/partner_loss_turd_continuity_test.tscn
```

Dedicated workflow:

```text
.github/workflows/partner-loss-turd-validate.yml
```

### Regression gate

```text
Godot --headless --path . tests/combat/combat_campaign_resolution_test.tscn
Godot --headless --path . tests/campaign/campaign_state_test.tscn
Godot --headless --path . tests/save/save_manager_test.tscn
Godot --headless --path . tests/profile/operator_profile_app_test.tscn
```

## Known gaps

- Operator Loss is not implemented yet. Active TURD temporarily retains the one-HP compatibility repair until Phase 14.2 replaces it with the definitive transition.
- Legacy Site state and world spawning are not implemented yet.
- The exact final TURD balance and final assets are not authored. Current stats and visuals are integration values constrained only by the GDD requirement that TURD be extremely weak and use basic Modules.
- Profile, Encyclopedia and Calendar require later UX/art passes.
- Only NOVIRE has a complete starter integration Resource.
- No local Godot executable or observable GitHub Actions status is available in this tool environment; Phase 14.1 remains `READY`, not `PASS`.
