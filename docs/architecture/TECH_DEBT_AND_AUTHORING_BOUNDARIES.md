# NULL NETWORK — Technical Debt and Authoring Boundaries

This file records intentional compatibility layers and the places that should be refactored before they grow. It exists to stop temporary stabilization code from silently becoming the content-authoring API.

## Current architectural rule

Ordinary content authoring must not require edits to global managers.

Browser content should be authored through:

- `WebsitePage`
- `WebsiteCatalog`
- page `.tscn` scenes
- `SiteActionData`
- shared Conditions / GameEffects

Dialogue content should be authored through:

- `DialogueData`
- `DialogueNodeData`
- `DialogueChoiceData`
- shared Conditions / GameEffects
- `data/content/game_content_catalog.tres`

Presentation should be authored through scenes/themes/motion Resources rather than page-specific timing hacks.

## Completed cleanup: SiteActionButton gameplay-state duplication

The old `SiteActionButton` directly implemented its own flag/number/gameplay-condition pipeline. Existing Browser usages were migrated and those direct gameplay-state authoring fields were removed.

Current rule:

```text
SiteActionButton
└── SiteActionData
    ├── ConditionRuleData / ConditionSetData
    └── GameEffectData[]
```

Do not reintroduce direct persistent-state mutation fields to the Button when a shared Condition or GameEffect can express the behavior.

UI-local presentation behavior may remain local when it is genuinely non-persistent.

## Browser PAGE_SCROLL host

`apps/browser/browser_page_scroll_host.gd` is the explicit layout owner for Browser-managed scrolling.

Status: **final shared Browser infrastructure**.

The host is a `Container`, not a `VBoxContainer`. Browser navigation temporarily keeps the outgoing and incoming page roots alive together, so those roots must overlay at the same document origin while `UiMotionPlayer` owns their horizontal transition.

The host also reports the largest page minimum size to `ScrollContainer`. Scroll range therefore comes from authored page content instead of from frame waits or per-site pixel corrections.

Rules:

- PAGE_SCROLL page roots must expose their real content minimum size through normal Container layout.
- Do not add per-site scroll clamping, fake spacer heights or repeated `await process_frame` resets.
- Do not make the page host own horizontal transition coordinates; that axis belongs to `UiMotionPlayer`.
- Browser-managed and self-managed scrolling remain separate `WebsitePage.OverflowPolicy` contracts.

## Hotspot: OperatorCreationPage

`apps/browser/sites/null_network/register/operator_creation.gd` currently coordinates multiple flow pages and owns a large amount of page-specific presentation logic.

Status: **works, but is the primary UI decomposition target**.

Do not add unrelated new onboarding subsystems directly to this file.

Target decomposition:

```text
OperatorCreationPage
  coordinator / shared flow state

AccountRegistrationPage
AppearanceRegistrationPage
CompatibilityMethodPage
ManualAllocationPage
AssessmentPage
AssessmentResultPage
RegistrationCompletePage
```

Each page controller should own its local UI and expose signals/data to the coordinator. The coordinator remains responsible for flow order, shared saved state and registration completion.

Perform this decomposition only as a dedicated refactor with regression coverage; do not split the file opportunistically while fixing unrelated bugs.

## UI composition rule

Repeated visual structures belong in scenes/components, while app controllers project data into those components.

Current extracted examples:

- Calendar day entries: `CalendarDayButton`.
- Calendar event entries: `CalendarEventCard`.
- Profile tendency entries: `ProfileTendencyRow`.
- Profile key/value entries: `ProfileValueRow`.
- Registration result summary: `AssessmentResultSummary` + `AssessmentResultTendencyRow`.
- Registration partner arrival: `PartnerArrivalStage`.

Creating a node in code is still valid when the node is genuinely ephemeral behavior, such as a short-lived materialization particle. A controller should not construct a reusable card, panel, row or authored layout tree with `.new()` calls.

Do not create global helper managers merely to remove tiny local helpers. A three-line local cleanup function is preferable to a generic abstraction with no shared domain contract.

## Hotspot: CombatManager

`apps/combat/combat_manager.gd` remains the largest systemic decomposition target.

Status: **stable enough to use, too broad to keep growing**.

The manager currently owns encounter coordination together with effect execution, targeting, formulas, runtime slot state and save serialization. New combat features must not add another responsibility category directly to this file.

Target extraction order:

```text
CombatManager
  encounter lifecycle / cycle orchestration / public signals

CombatTargetingService
  target resolution / validity / slot relation queries

CombatFormulaService
  effective stats / damage and formula evaluation

CombatEffectExecutor
  effect application / status / stability / redirects / dummies

CombatStateCodec
  combat save serialization / deserialization
```

Extract these boundaries one at a time under the existing combat regression suite. Do not rewrite the 5k-line manager in one untestable migration.

## Compatibility layer: Operator succession presentation restore

`OperatorSuccessionRegistrationPage` currently suppresses replayed presentation while Browser state is being restored.

Status: **localized debt**.

The final owner of `FRESH / NAVIGATION / RESTORE` presentation context should be the base operator-creation flow, because restore semantics are not succession-specific.

Refactor this together with `OperatorCreationPage` decomposition so the change is tested once instead of creating another intermediate abstraction.

## Browser route registration

`SimulatedDNS` no longer owns the production route list directly. Production routes live in:

```text
data/content/sites/website_catalog.tres
```

`registered_sites` remains on `SimulatedDNS` only as a compatibility/testing fallback.

New production sites go into `WebsiteCatalog`, not the autoload scene.

## Motion ownership

- Large global transitions: `KubuTransitionManager`.
- Reusable local UI micro-motion: `UiMotionPlayer` + `UiMotionProfileData`.
- Specialized app motion may remain specialized when the generic player would make it less clear.

Do not create another global motion autoload.

Do not duplicate generic enter/exit/confirm/reject tweens inside new pages.

## Definition of a bad workaround

A fix should be rejected or centralized if it introduces any of the following into authored content:

- magic pixel offsets required for one resolution;
- repeated `await process_frame` in individual pages;
- direct calls between unrelated apps;
- new global flags read directly from arbitrary UI scripts when a Condition Resource should be used;
- gameplay state mutation directly in site scenes when a GameEffect Resource should be used;
- `find_child()` / absolute SceneTree searches as production coupling;
- duplicated Browser/window/dialogue logic in a content scene.

A temporary stabilizer is acceptable only when it has one owner, explains why it exists, and has regression coverage.
