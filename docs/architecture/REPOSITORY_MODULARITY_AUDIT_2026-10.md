# NULL NETWORK — Repository Modularity Audit (2026-10)

## Scope and evidence

This is a **repository-wide first-pass inventory plus targeted source-code inspection**, not a claim that all code has been line-reviewed or completely refactored.

Baseline: `main` at `b8c642b3ef142a96962a115cb999933839e80d93`.

The feature branch `refactor/modularity-pass-1` contains the first concrete repair and modularity extractions.

Git tree inventory at the audit checkpoint:

- **388** GDScript (`.gd`) files, including test scripts.
- **39** GDScript files of at least 12,000 bytes.
- Largest controllers / scripts verified by direct source inspection:

| File | Lines | Functions | Current ownership |
| --- | ---: | ---: | --- |
| `apps/combat/combat_manager.gd` | 5,061 | 156 | Encounter state, targeting, effects, formulas and combat save codec |
| `apps/browser/sites/null_network/register/operator_creation.gd` | large | multiple | Registration state machine and page-level UI flow |
| `core/autoloads/save_manager.gd` | 923 | 38 | Campaign save orchestration and restore |
| `core/autoloads/campaign_state.gd` | 944 | 59 | Operator and campaign persistent state |
| `systems/startup/startup_presentation.gd` | 841 | 37 | Boot/menu visual sequencing |
| `apps/navigator/app_navigator.gd` | 1,048 | 39 | Navigator view, location flow and save/session state |
| `apps/forum/forum_app.gd` | 784 | 56 | Thread browsing, filters, lists and local state |
| `systems/window_manager/window_manager.gd` | 812 | 47 | Window lifecycle, layout and persisted window state |

Large file size is **a review trigger, not proof of incorrect architecture**. No new managers or autoloads should be created solely to reduce line counts.

## Confirmed structural failures repaired in this branch

### Browser PAGE_SCROLL

Before: `ScrollSiteContainer` was a `VBoxContainer` while navigation temporarily retained multiple page roots. VBox layout stacked those roots. The homepage's original `Control` root did not propagate its dynamic content minimum height to the scrolling container.

Now:

- `apps/browser/browser_page_scroll_host.gd`: dedicated overlay `Container` for transition roots, with computed minimum document size. ScrollContainer owns the Y viewport, motion player owns animated X.
- `apps/browser/app_browser.tscn`: matches the overlay host type; address bar top padding reduced by 1 px to satisfy the existing 40 px chrome budget.
- `apps/browser/browser.gd`: strongly typed reference to the shared host.
- `data/content/sites/null network/nnw_homepage.tscn`: homepage uses `MarginContainer` root to propagate natural document height.
- `tests/browser/browser_page_scroll_origin_test.gd`: verifies exact top/bottom and footer accessibility on entry and Back.
- `.github/workflows/browser-validation.yml`: independent Browser CI suite, so unrelated desktop-window tests do not block Browser regressions.

The authored Get Started page intentionally has no portal footer. Its regression does not recreate the removed footer.

### Reusable app UI

Before: Calendar, Profile and registration presentation controllers instantiated authored lists and card layouts using raw UI node constructors and inline style construction.

Now:

- `apps/calendar/components/calendar_day_button.{gd,tscn}`
- `apps/calendar/components/calendar_event_card.{gd,tscn}`
- `apps/profile/components/profile_tendency_row.{gd,tscn}`
- `apps/profile/components/profile_value_row.{gd,tscn}`
- `apps/browser/sites/null_network/register/assessment_result_summary.{gd,tscn}`
- `apps/browser/sites/null_network/register/assessment_result_tendency_row.{gd,tscn}`
- `apps/browser/sites/null_network/register/partner_arrival_stage.{gd,tscn}`

Parent scenes supply `PackedScene` dependencies, app controllers pass state and subscribe to signals, and the components own their appearance and local presentation. No new autoloads were introduced.

The parent scene must add instantiated children to the tree **before** calling `setup()` on components that use `@onready` references. This lifecycle boundary is covered by Calendar/Profile CI.

## Priority architecture debt remaining

### Priority 1 — CombatManager decomposition

**Verified:** `apps/combat/combat_manager.gd` combines functions such as `_execute_effects`, `_apply_damage`, `_calculate_damage`, `resolve_targets`, `_serialize_team`, `_deserialize_actor`, `import_save_data` and `export_save_data`.

Next extraction contracts:

1. Combat save codec for serialization/deserialization, preserving the existing save section and data format.
2. Targeting resolver for queries/target eligibility/slot relations.
3. Formula evaluator for damage and effective stats.
4. Effect executor for effect application, statuses, stability, redirects and dummies.
5. Keep `CombatManager` as encounter/cycle orchestrator and public signal owner.

Do this as **separate tested changes**, with `tests/combat/combat_runtime_test.tscn`, `tests/combat/combat_layout_test.tscn` and the campaign-resolution tests as gates. No broad behavior rewrite.

### Priority 2 — OperatorCreationPage decomposition

**Verified:** `apps/browser/sites/null_network/register/operator_creation.gd` still owns the full registration flow and many page-specific UI actions. This pass extracted result and completion components, but did **not** fully split registration.

Follow the already documented boundaries in `TECH_DEBT_AND_AUTHORING_BOUNDARIES.md`: account, appearance, method, manual allocation, assessment, result, completion. Keep flow order and persistence in the coordinator. Move shared restore/presentation semantics from succession specialization to the base flow when the complete refactor is tested.

### Priority 3 — Large presentation owners

The following files require focused component and dependency review, **without asserting duplication not yet demonstrated**:

- `systems/startup/startup_presentation.gd`
- `apps/navigator/app_navigator.gd` and `apps/navigator/world_map/navigator_world_map_view.gd`
- `apps/forum/forum_app.gd`
- `systems/window_manager/window_manager.gd`
- `apps/combat/app_combat.gd`
- `core/autoloads/social_service.gd`

Follow existing `.tscn`, `.tres`, signal and state-ownership boundaries rather than building parallel systems.

### Priority 4 — Global save/state review

`SaveManager` and `CampaignState` are legitimately global responsibilities. Verify serialization compatibility, cross-app access boundaries and event ownership before splitting them. Size alone does not justify making new autoloads.

## Validation baseline and interpretation

At `main` commit `b8c642b3ef142a96962a115cb999933839e80d93`, the following GitHub Actions jobs were already failing: Desktop Shell, Profile App, Operator Loss Succession, Godot Project, Starter Selection and Encyclopedia App. Calendar, Social Foundation and Partner Loss/TURD passed.

This branch repaired Profile tests for the level-3 starter progression contract; Calendar, Profile, Assessment Result and the new Browser suite have subsequently passed in the PR checks. Other baseline failures must be investigated as **separate verified defects**, not rebranded as regressions from the Browser/UI extraction.

## Rules for the next refactor

- Preserve authored `.tres` and save schemas unless a migration is explicitly implemented.
- Prefer scenes and Resources for repeated visual components; avoid hardcoded `PackedScene` paths inside controllers.
- Preserve signals, local presentation semantics and separation of app subsystems.
- Keep reusable code in existing services/components; avoid a generic utility framework without repeated domain behavior.
- Add regression coverage for every extracted boundary before removing the old implementation.
- Do not merge an architectural rewrite simply because it imports. Runtime behavior and save/restore boundaries must pass their tests.
