# Assessment → Navigator onboarding handoff

This document records the runtime ownership boundaries for the first Operator synchronization sequence.

## Player-facing sequence

```text
Compatibility Assessment result
→ staged Tendencies
→ assigned APK record
→ ACCEPT PARTNER
→ partner overworld sprite materializes
→ Personality-driven first-impression line
→ Browser closes
→ pre-staged black Navigator becomes visible
→ Operator Safehouse local area is loaded behind the mask
→ radial reveal opens from the actual player position
→ local-area input is enabled
```

The canonical Assessment remains responsible for species, initial Tendencies, optional Variant data and the primary Operator trait used by the partner first impression. It does not own app/window/world transitions.

## Ownership

### Registration page

`apps/browser/sites/null_network/register/operator_creation_revamped.gd`

Owns result presentation, partner materialization and first-impression timing. It emits `onboarding_handoff_requested` after the final line. It does not close Browser or know how Navigator works.

`OperatorRegistrationHandoffRelay` converts that page-local signal into the global onboarding intent. The route-specific relay also keeps the obsolete `OPEN NULL CHANNEL` fallback hidden while the world handoff is active.

### Prologue coordinator

`systems/onboarding/prologue_onboarding_handoff_controller.gd`

Owns cross-app orchestration only:

- silently ensures Navigator is installed before the reveal;
- activates the Navigator WORKSPACE behind normal windows;
- waits for Browser to finish its normal close lifecycle;
- requests the Navigator reveal;
- waits for Navigator to report completion.

Browser and Navigator never call each other directly.

### Navigator

`apps/navigator/operator_loss_navigator.gd`

Owns Navigator-domain state:

- resolves the configured onboarding `MapLocation`;
- enters its `LocalAreaData`;
- keeps local-area interaction disabled during blackout;
- resolves the real rendered player position;
- invokes the reusable radial reveal presentation;
- commits the world-revealed flag/checkpoint;
- enables player interaction only after reveal completion.

### Reusable presentation

`systems/ui/effects/radial_reveal_overlay.gd`
`systems/ui/effects/radial_reveal_mask.gdshader`

The radial mask has no knowledge of Navigator, Browser, campaigns or APKs. It receives a global screen position plus timing parameters and only performs the visual reveal.

### Data

`data/templates/onboarding/prologue_onboarding_presentation_data.gd`
`data/content/onboarding/default_prologue_onboarding_presentation.tres`

The app IDs, onboarding location, persistence flag and reveal timing are authored in a Resource rather than hardcoded in the coordinator.

## Safehouse

The first world reveal currently targets the real greybox Local Area:

`data/content/navigator/areas/operator_safehouse/`

The safehouse is registered in the global content catalog and the Navigator world data, but `show_on_world_map = false`. This allows normal Navigator save/restore resolution without exposing the room as a travel node.

## Interrupted synchronization recovery

Starter synchronization is checkpointed before the presentation finishes. If the Browser session is restored with a partner already persisted but the world-revealed flag still false, `OperatorSuccessionRegistrationPage` reconstructs the pending candidate/primary trait from `OperatorStateData.onboarding_metadata` and replays the partner-arrival sequence. This prevents a save/load boundary from skipping the first-impression beat or leaving the campaign on the old forum fallback.

## Retired legacy behavior

`prologue_registration_completed.tres` no longer injects the temporary systems showcase, a forced NOVIRE, Akihabara discovery or `story.prologue.account_ready`. The legacy `integration.showcase.resume` event is no longer part of the canonical StoryEvent catalog. Those paths conflicted with the Assessment-assigned partner and the new Browser → Navigator transition.
