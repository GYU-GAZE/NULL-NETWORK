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
- Roadmap phase: **Phase 15 — Construction of the Prologue**
- Phase 14.1 Partner Loss/TURD: manually confirmed by the project owner.
- Phase 14.2 Operator Loss/succession: runtime flow manually confirmed by the project owner on 2026-08-07.
- TURD now reaches real 0 HP and resolves Operator Loss; the obsolete one-HP compatibility safeguard has been removed.
- Operator registration now routes both first-time Operators and post-loss Operators to the same data-driven starter-selection page.
- Starter selection accepts both `PROLOGUE` and `OPERATOR_CREATION` when an Operator exists and no active partner exists.
- Player-facing starter-selection copy is context-neutral and does not reveal that another Operator previously existed.
- Initial PROLOGUE starter selection does not install/open Navigator early; succession still completes through the succession-aware progression service.
- Profile and Calendar are functional greyboxes; their final UX is deferred.
- Encyclopedia has a typed foundation, but its behavior and UX are deferred for redesign.

The current irreversible loss chain is:

```text
primary partner reaches 0 HP in a definitive encounter
→ Partner Loss
→ partner archived as LOST
→ TURD assigned automatically
→ TAME may establish a replacement partner
→ the same TURD remains in reserve
→ replacement loss restores that TURD
→ TURD reaches 0 HP
→ Operator Loss
→ Operator and TURD archived
→ broken KubuOS Handtop becomes a Legacy Site at the loss location
→ Browser opens normal Operator registration
→ registration opens the generic starter-selection page
→ new Operator selects a cataloged starter
→ Navigator installs for the post-loss flow
→ campaign continues on the same day and in the same world
```

The player-facing registration/starter pages do not identify the new Operator as a successor and do not expose the identity of the archived Operator.

## State ownership after Operator Loss

### Reset because it belonged to the lost Operator or destroyed device

```text
Operator identity and appearance;
active partner and TURD continuity;
tendencies;
money and inventory;
known Modules;
active Leads and active Incident progress;
Social, Friend List and affinity;
Encyclopedia knowledge;
forum read/watch state;
browser history and pins;
app sessions and installed-app state.
```

### Preserved because it belongs to the campaign or world

```text
campaign ID and save mode;
TimeManager day, DAY/NIGHT, action block and Update countdown;
world flags and numbers;
location infestation;
persistent world objects;
completed Leads, Incidents and StoryEvents;
discovered locations;
Operator archive history;
Legacy Sites.
```

Before clearing the old device, the Legacy Site seals money, typed inventory, known Module IDs, Encyclopedia data, forum/browser logs and app sessions. None of it is granted automatically to the next Operator.

## Next exact task

### Validate the shared registration → starter boundary

Run:

```text
tests/commitment/initial_starter_selection_page_test.tscn
tests/commitment/starter_selection_page_test.tscn
tests/commitment/operator_loss_real_damage_test.tscn
```

Expected markers:

```text
INITIAL_STARTER_SELECTION_PAGE_TEST: PASS
STARTER_SELECTION_PAGE_TEST: PASS
OPERATOR_LOSS_REAL_DAMAGE_TEST: PASS
```

Manual smoke tests:

```text
FIRST ACCOUNT
new campaign in PROLOGUE
→ register Operator at null.net/register
→ Browser opens null.net/select-starter
→ page contains no succession/previous-Operator language
→ choose NOVIRE
→ partner is created
→ campaign remains PROLOGUE
→ Navigator is not exposed before the Prologue installs it

OPERATOR LOSS
TURD reaches 0 HP through real combat damage
→ Operator Loss
→ register another Operator through the same visible registration page
→ same generic starter page opens
→ choose starter
→ Navigator installs
→ campaign returns to MAIN_CAMPAIGN on the same world/day
```

### Then continue Phase 15 — Prologue

The official roadmap still requires a playable no-debug Prologue:

```text
campaign creation / save-mode choice
→ KubuOS boot
→ denpa-channel
→ discover NULL NETWORK
→ Operator registration
→ starter selection
→ forum/download progression
→ NULL NETWORK installation
→ Navigator installation
→ first area
→ tutorial combat
→ transition to MAIN_CAMPAIGN Day 1
```

`Phase 14.3 — Legacy Recovery` remains designed in `TEST_MATRIX.md`, but it is deferred. `ROADMAP.md` explicitly lists complete Legacy Recovery outside the first vertical slice critical path.

After Phase 15, the roadmap continues with:

```text
Phase 16 — Build the first week through the Aquarium Incident
Phase 17 — Hardening, regression, UX and final validation
```

## Active files

### First-account registration and starter selection

```text
apps/browser/sites/null_network/register/operator_creation.gd
apps/browser/sites/null_network/register/operator_creation.tscn
apps/browser/sites/null_network/register/operator_succession_registration.gd
apps/browser/sites/null_network/register/operator_succession_registration.tscn
apps/browser/sites/null_network/starter_selection/starter_selection.gd
apps/browser/sites/null_network/starter_selection/starter_selection.tscn
data/content/sites/null network/nnwregister.tres
data/content/sites/null network/nnwstarterselection.tres
```

### Starter/progression authority

```text
data/templates/apk/apk_data.gd
data/content/apks/starters/novire_init.tres
systems/progression/apk_progression_service.gd
systems/commitment/apk_succession_progression_service.gd
core/autoloads/operator_service.gd
systems/commitment/operator_succession_service.gd
```

### Commitment and Operator Loss

```text
data/templates/apk/partner_continuity_state_data.gd
data/templates/commitment/legacy_site_state_data.gd
data/templates/campaign/operator_state_data.gd
systems/commitment/turd_partner_factory.gd
systems/commitment/partner_continuity_service.gd
systems/commitment/partner_loss_service.gd
systems/commitment/operator_loss_service.gd
systems/combat/combat_campaign_manager.gd
```

### Validation

```text
tests/commitment/initial_starter_selection_page_test.gd
tests/commitment/starter_selection_page_test.gd
tests/commitment/operator_loss_real_damage_test.gd
tests/commitment/operator_loss_succession_test.gd
tests/commitment/partner_loss_turd_continuity_test.gd
.github/workflows/starter-selection-validate.yml
.github/workflows/operator-loss-succession-validate.yml
.github/workflows/partner-loss-turd-validate.yml
```

## Architecture checkpoint

- `CampaignState.partner` remains the sole active combat-partner authority.
- `PartnerContinuityStateData` stores only inactive TURD state and permanent lost-partner history.
- `operator_history` archives Operators and destroyed TURDs.
- `WorldStateData.persistent_objects` owns Legacy Sites.
- `CombatResolutionData` authors recoverable/definitive loss policy and infestation consequences.
- Operator Loss state transitions belong to Services, not to Browser presentation scenes.
- Initial and post-loss Operator registration share the same visible registration/starter UX.
- Starter eligibility belongs to `APKData`; the Browser page is a generic projection of the APK catalog.
- The starter page may select during `PROLOGUE` for the first Operator or `OPERATOR_CREATION` after Operator Loss.
- Initial starter selection preserves `PROLOGUE`; post-loss starter selection completes succession and restores `MAIN_CAMPAIGN`.
- No new parallel save section was created.

## Known gaps

- Phase 15 Prologue content is not yet assembled end-to-end.
- Legacy Recovery is not implemented; the broken handtop currently supports inspection only and recovery is deferred outside the slice critical path.
- Final TURD balance and assets are not authored.
- Akihabara is the integration location with a Legacy Site spawn point; final areas require authored Legacy Site placement.
- Operator Loss, Legacy Site and starter-selection visuals are functional greyboxes requiring later UX/art passes.
- Only NOVIRE has a complete selectable starter Resource; the Prologue gate ultimately requires five functional starters.
- The new first-account starter-selection regression is authored but still needs Godot/CI runtime confirmation.
