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
- Current subphase: **14.2 Operator Loss and Operator succession**
- Phase 12: Social, party participation, shared EXP and NPC-partner loss implemented.
- Phase 13.1 Profile: implemented and manually confirmed.
- Phase 13.2 Encyclopedia: typed foundation implemented; final behavior/UX deferred.
- Phase 13.3 Calendar: implemented and manually confirmed functional; final calendar UX deferred.
- Phase 14.1 Partner Loss/TURD: implemented and manually confirmed by the project owner.
- Phase 14.2 Operator Loss/succession: implementation and automated gate authored; runtime/CI validation pending.
- Latest implementation head before this documentation checkpoint: `ab86fb9c59b3c6f798c8580c44c10aa959561dab`

The campaign now supports the complete irreversible loss chain:

```text
primary partner reaches 0 HP in a definitive encounter
→ Partner Loss
→ defeated partner archived as LOST
→ TURD assigned automatically
→ TAME may establish a replacement partner
→ the same TURD remains preserved in reserve
→ replacement loss restores the same TURD
→ TURD reaches 0 HP
→ Operator Loss
→ Operator and TURD archived
→ persistent Legacy Site created at the loss location
→ successor Operator registration
→ successor starter selection
→ campaign continues on the same day and in the same world
```

## Canonical Phase 14 ownership

### Operator-owned state — reset on Operator Loss

```text
Operator identity and appearance;
active partner and TURD continuity;
tendencies;
money and inventory;
known Modules;
active Leads and active Incident progress;
Social/Friend List/affinity;
Encyclopedia knowledge;
forum read/watch state;
browser history and pins;
app session state;
installed-app state.
```

### Campaign/world-owned state — preserved

```text
TimeManager day, DAY/NIGHT and action block;
Update countdown;
world flags and numbers;
location infestation;
persistent world objects;
completed Leads and Incidents;
completed StoryEvents;
discovered locations;
Operator archive history;
Legacy Sites.
```

### Destroyed-device data

Before the old Operator state is cleared, the Legacy Site seals:

```text
money;
typed inventory;
known Module IDs;
Encyclopedia state;
forum/browser log state;
app session state.
```

This data is not granted automatically to the successor. Legacy Recovery is a separate irreversible activity.

## Next exact task

### First: validate Phase 14.2

Run:

```text
Godot --headless --path . tests/commitment/operator_loss_succession_test.tscn
```

Confirm:

```text
ordinary EXE resolution uses definitive loss policy;
primary Partner Loss still assigns TURD;
TURD at 0 HP resolves Operator Loss through CombatManager;
Operator and destroyed TURD are archived once;
current day, period and block remain unchanged;
world flags, completed Incident/Lead and infestation remain;
Operator Loss adds its authored infestation increase;
old relationships, tendencies, inventory, Modules, Encyclopedia and device sessions are cleared;
a typed Legacy Site is stored in WorldState.persistent_objects;
the broken KubuOS Handtop appears in the loss Local Area;
registration creates a successor without resetting the campaign;
starter selection reinstalls Navigator and returns to MAIN_CAMPAIGN;
save/reload preserves the successor, archived Operator, Legacy Site and world.
```

### Regression

Run:

```text
Godot --headless --path . tests/commitment/partner_loss_turd_continuity_test.tscn
Godot --headless --path . tests/combat/combat_campaign_resolution_test.tscn
Godot --headless --path . tests/campaign/campaign_state_test.tscn
Godot --headless --path . tests/save/save_manager_test.tscn
```

### Then: implement Phase 14.3 — Legacy Recovery

```text
successor finds a Legacy Site
→ inspect sealed recoverable data
→ preview exactly what can be restored
→ confirm an irreversible recovery activity
→ restore material/log data through typed services
→ mark the Legacy Site recovered
→ never restore dead APK/TURD, relationships, affinity, ranking, reputation, tendencies or identity
→ save/reload preserves the recovered boundary
```

## Active files

### Persistent loss and succession

```text
data/templates/apk/partner_continuity_state_data.gd
data/templates/commitment/legacy_site_state_data.gd
data/templates/campaign/operator_state_data.gd
systems/commitment/turd_partner_factory.gd
systems/commitment/partner_continuity_service.gd
systems/commitment/partner_loss_service.gd
systems/commitment/operator_loss_service.gd
systems/commitment/operator_succession_service.gd
systems/commitment/apk_succession_progression_service.gd
```

### Combat policy

```text
data/templates/combat/combat_resolution_data.gd
data/content/combat/resolutions/default_exe_resolution.tres
systems/combat/combat_campaign_manager.gd
systems/commitment/operator_loss_combat_manager.gd
systems/combat/combat_resolution_service.gd
apps/combat/resolution/combat_resolution_panel.gd
```

### Navigator and Legacy Site projection

```text
apps/navigator/operator_loss_navigator.gd
apps/navigator/app_navigator.tscn
apps/navigator/local_area/actors/local_area_legacy_site_actor.gd
apps/navigator/local_area/actors/local_area_legacy_site_actor.tscn
apps/navigator/local_area/spawning/local_area_spawn_point.gd
apps/navigator/local_area/spawning/legacy_aware_population_controller.gd
data/content/navigator/areas/akihabara/akihabara_local_area.tscn
```

### Runtime registration

```text
project.godot
```

### Validation

```text
tests/commitment/partner_loss_turd_continuity_test.gd
tests/commitment/partner_loss_turd_continuity_test.tscn
tests/commitment/operator_loss_succession_test.gd
tests/commitment/operator_loss_succession_test.tscn
.github/workflows/partner-loss-turd-validate.yml
.github/workflows/operator-loss-succession-validate.yml
```

## Phase 14.1 checkpoint — Partner Loss and persistent TURD

`CampaignState.partner` remains the active combat authority. `OperatorStateData.partner_continuity` owns only the inactive TURD reserve and permanent lost-partner history.

TURD moves rather than copies:

```text
active TURD
→ TAME
→ complete TURD PartnerState moves to reserve
→ replacement partner active
→ replacement Partner Loss
→ exact reserved TURD returns
```

Level, EXP, HP, Stability, affinity, allocations, known Modules, equipped Modules, personality and address term remain intact.

## Phase 14.2 checkpoint — Operator Loss and succession

### Combat boundary

`OperatorLossCombatManager` extends the existing campaign combat manager. It removes the temporary one-HP TURD repair while preserving the tactical runtime, party integration, save snapshots and ordinary Partner Loss code.

`CombatResolutionData` authors:

```text
partner_loss_policy;
partner_loss_infestation_increase;
operator_loss_infestation_increase.
```

The default EXE resolution is definitive at zero HP, adds `+1` infestation for Partner Loss and `+3` for Operator Loss.

### Operator archive

`OperatorLossService` creates one archive record containing:

```text
old Operator save data;
destroyed TURD save data;
loss day/action/location/encounter;
Legacy Site ID.
```

No new top-level save section was introduced. Existing `CampaignState.operator_history` and `WorldStateData.persistent_objects` remain the authorities.

### Successor lifecycle

```text
OPERATOR_LOSS
→ OperatorService registers successor
→ OPERATOR_CREATION
→ APKProgressionService selects starter
→ Navigator installed
→ MAIN_CAMPAIGN
```

The Prologue registration path remains unchanged because succession-specific behavior activates only when the campaign is already in `OPERATOR_LOSS`/`OPERATOR_CREATION` with archived history.

### Legacy Site presentation

The Legacy Site is a typed world object projected by a reusable population-controller extension. Akihabara currently contains the integration spawn point. Final art and recovery UI remain Phase 14.3 work.

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

Manual runtime confirmation: TURD assignment and continuity work.

### Phase 14.2

```text
Godot --headless --path . tests/commitment/operator_loss_succession_test.tscn
```

Dedicated workflow:

```text
.github/workflows/operator-loss-succession-validate.yml
```

## Known gaps

- Legacy Recovery is not implemented yet; the broken handtop currently supports inspection only.
- The exact final TURD balance and final assets are not authored. Current values are integration content.
- Akihabara is the integration location with a Legacy Site spawn point; final location layouts need their own authored LEGACY_SITE points where appropriate.
- Operator Loss presentation is functional but greybox; final death transition, device-failure effects and registration handoff need a UX/art pass.
- Profile, Encyclopedia and Calendar require later UX/art passes.
- Only NOVIRE has a complete starter integration Resource.
- No local Godot executable or observable GitHub Actions result is available in this tool environment; Phase 14.2 remains `READY`, not `PASS`.
