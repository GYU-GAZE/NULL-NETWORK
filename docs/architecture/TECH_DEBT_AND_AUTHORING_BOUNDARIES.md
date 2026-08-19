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

## Compatibility layer: SiteActionButton legacy fields

`apps/browser/site_action_button.gd` still contains old direct fields for flags, numbers, visibility, alerts and navigation.

Status: **compatibility only**.

New gameplay state logic must use `SiteActionData.conditions` and `SiteActionData.effects`.

Do not add new legacy enums/fields when a reusable `ConditionRuleData` or `GameEffectData` can express the behavior.

UI-local visibility may remain local when it is presentation-only and not campaign state.

Removal criterion: migrate every existing Browser scene away from legacy gameplay-state fields, then delete those fields in one explicit migration.

## Stabilizer: BrowserPageScrollHost

`apps/browser/browser_page_scroll_host.gd` waits for Godot container layout to settle before reasserting the page-scroll origin.

Status: **intentional centralized stabilizer**.

This is acceptable while it is the single location handling the deferred `VBoxContainer -> ScrollContainer` layout interaction.

Do not copy `await process_frame` / scroll-reset logic into individual sites.

Refactor criterion: if another independent Browser layout bug requires additional frame-wait logic, replace this stabilizer with an explicit Browser site-host lifecycle rather than stacking more waits.

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
