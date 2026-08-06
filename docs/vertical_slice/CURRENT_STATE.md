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
- Phase 14.1 Partner Loss/TURD: manually confirmed by the project owner.
- Phase 14.2 implementation: complete and awaiting runtime/CI validation.
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
→ Browser opens successor registration
→ registration opens the data-driven starter-selection page
→ successor selects a cataloged starter
→ Navigator installs
→ campaign continues on the same day and in the same world
```

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

Before clearing the old device, the Legacy Site seals money, typed inventory, known Module IDs, Encyclopedia data, forum/browser logs and app sessions. None of it is granted automatically to the successor.

## Next exact task

### Validate Phase 14.2

Run:

```text
tests/commitment/operator_loss_succession_test.tscn
tests/commitment/starter_selection_page_test.tscn
```

Expected markers:

```text
OPERATOR_LOSS_SUCCESSION_TEST: PASS
STARTER_SELECTION_PAGE_TEST: PASS
```

The gates confirm:

```text
TURD at 0 HP resolves Operator Loss through CombatManager;
Operator and destroyed TURD are archived once;
day, period, block and countdown do not reset;
world progression and authored infestation remain;
old personal/device state does not leak to the successor;
a typed Legacy Site persists and appears in the loss Local Area;
null.net/register redirects successor registration to null.net/select-starter;
the selection page lists only APKData marked selectable_as_starter;
selecting a starter reinstalls Navigator and returns to MAIN_CAMPAIGN;
save/reload preserves the successor, archive, Legacy Site and world.
```

Regression:

```text
tests/commitment/partner_loss_turd_continuity_test.tscn
tests/combat/combat_campaign_resolution_test.tscn
tests/campaign/campaign_state_test.tscn
tests/save/save_manager_test.tscn
```

After validation, implement **Phase 14.3 — Legacy Recovery**:

```text
successor finds a Legacy Site
→ inspect a typed recovery preview
→ confirm one irreversible recovery Activity
→ restore only authored material/log data
→ mark the site recovered
→ never restore dead APK/TURD, relationships, affinity, tendencies, ranking, reputation or identity
→ save/reload preserves the boundary
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

### Combat policy and presentation

```text
data/templates/combat/combat_resolution_data.gd
data/content/combat/resolutions/default_exe_resolution.tres
systems/combat/combat_campaign_manager.gd
systems/commitment/operator_loss_combat_manager.gd
systems/combat/combat_resolution_service.gd
apps/combat/resolution/combat_resolution_panel.gd
```

### Legacy Site and Navigator handoff

```text
apps/navigator/operator_loss_navigator.gd
apps/navigator/app_navigator.tscn
apps/navigator/local_area/actors/local_area_legacy_site_actor.gd
apps/navigator/local_area/actors/local_area_legacy_site_actor.tscn
apps/navigator/local_area/spawning/local_area_spawn_point.gd
apps/navigator/local_area/spawning/legacy_aware_population_controller.gd
data/content/navigator/areas/akihabara/akihabara_local_area.tscn
```

### Successor registration and starter selection

```text
data/templates/apk/apk_data.gd
data/content/apks/starters/novire_init.tres
apps/browser/sites/null_network/register/operator_succession_registration.gd
apps/browser/sites/null_network/register/operator_succession_registration.tscn
apps/browser/sites/null_network/starter_selection/starter_selection.gd
apps/browser/sites/null_network/starter_selection/starter_selection.tscn
data/content/sites/null network/nnwregister.tres
data/content/sites/null network/nnwstarterselection.tres
core/autoloads/simulated_dns.tscn
```

`APKData.selectable_as_starter` and `starter_sort_order` are the data authority. The page contains no list of NOVIRE, VOCALYTE, WIZIP, TROJAW or PABUBU IDs. Currently only NOVIRE has a complete integration Resource and is therefore the only selectable entry.

### Runtime registration

```text
project.godot
```

### Validation

```text
tests/commitment/partner_loss_turd_continuity_test.gd
tests/commitment/operator_loss_succession_test.gd
tests/commitment/starter_selection_page_test.gd
.github/workflows/partner-loss-turd-validate.yml
.github/workflows/operator-loss-succession-validate.yml
.github/workflows/starter-selection-validate.yml
```

## Architecture checkpoint

- `CampaignState.partner` remains the sole active combat-partner authority.
- `PartnerContinuityStateData` stores only inactive TURD state and permanent lost-partner history.
- `operator_history` archives Operators and destroyed TURDs.
- `WorldStateData.persistent_objects` owns Legacy Sites.
- `CombatResolutionData` authors recoverable/definitive loss policy and infestation consequences.
- Successor-specific behavior is added through subclasses registered as autoloads; initial campaign registration remains compatible.
- Starter eligibility belongs to `APKData`; the Browser page is a generic projection of the APK catalog.
- No new parallel save section was created.

## Known gaps

- Legacy Recovery is not implemented; the broken handtop currently supports inspection only.
- Final TURD balance and assets are not authored.
- Akihabara is the integration location with a Legacy Site spawn point; final areas require authored Legacy Site placement.
- Operator Loss, Legacy Site and starter-selection visuals are functional greyboxes requiring later UX/art passes.
- Only NOVIRE has a complete selectable starter Resource.
- No local Godot executable or observable GitHub Actions result is available in this tool environment. Phase 14.2 remains `READY`, not `PASS`.
