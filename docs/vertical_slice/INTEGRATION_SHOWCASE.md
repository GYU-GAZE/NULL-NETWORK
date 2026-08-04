# NULL NETWORK — PLAYABLE SYSTEMS SHOWCASE

This temporary, non-canon route exposes the systems completed through Roadmap Phase 11 inside a normal campaign. It exists so the game can be tested without test scenes or manual flag editing while the final Prologue and Week One content are still missing.

## Entry points

### New campaign

1. Create a campaign.
2. Complete `null.net/register`.
3. Registration creates a temporary NOVIRE partner, discovers Akihabara, prepares the forum account and unlocks the conditional dialogue choice.
4. The welcome StoryEvent installs and opens Navigator.
5. Complete the six-portrait welcome dialogue.
6. Browser opens the pinned `SYSTEMS FIELD TEST // AKIHABARA ROUTE` thread.

### Existing registered campaign

1. Load the campaign from Campaign Select.
2. `integration.showcase.resume` supplies any missing temporary starter, Akihabara discovery and account-ready flags.
3. The same welcome and field-test route continues without requiring a new campaign.

## Playable route

```text
Register or load a registered campaign
→ temporary NOVIRE PartnerState
→ Navigator installation
→ six-portrait dialogue
→ pinned forum guide
→ activate integration.field_test Lead
→ Navigator badge
→ confirm Akihabara travel
→ Local Area movement with WASD
→ interaction with E
→ deterministic common Rattildus population
→ voluntary combat confirmation
→ Modules and Player Actions
→ persistent combat resolution
→ Lead-owned Incident actor
→ included dialogue and combat under one paid Activity
→ Lead/Incident completion
→ save and reload
```

## Forum identity

The registered Operator is projected into `NetworkUserDatabase` at runtime. NULL CHANNEL displays the registered username in its header and exposes `My Profile`. The profile uses the Godot icon as a placeholder avatar until the authored avatar catalog exists.

## What each section proves

| Section | Systems exercised |
|---|---|
| Campaign creation/load | Bootstrap, SaveManager, SAFE/COMMIT policy, CampaignState |
| Register | OperatorService, occupations, schedules, tendencies, Effects, checkpoint |
| Temporary NOVIRE | APKData, PartnerStateData, ContentRegistry, progression snapshot |
| Navigator install | AppCatalog, AppInstallationManager, Dock live synchronization |
| Welcome dialogue | StoryEvent queue, DialogueManager, six portraits, conditions, choices, tendencies, paid choice |
| Forum guide | Forum routing, runtime player identity, persistent read state |
| Field-test Lead | `lead://` intent, LeadIncidentManager, Navigator badge, discovery |
| Akihabara travel | Activity preview, confirmation, one-block transaction, Local Area transition |
| Local Area | top-down movement, entry point, deterministic population, runtime state |
| Common EXE | voluntary two-block combat, persistent partner snapshot, encounter return |
| Player Actions | SCAN, PURGE, PURIFY and TAME at 25% per committed Timeline slot |
| Incident | one parent Activity owning dialogue, combat and resolution without double charge |
| Reload | Browser, windows, Navigator, dialogue/combat boundaries, population and campaign state |

## Test notes

- NEET is the easiest occupation for an uninterrupted pass because it has the fewest occupied schedule blocks.
- High School Student and Salaryperson may correctly reject voluntary travel or combat during occupied blocks. This is expected schedule behavior, not a broken Navigator route.
- The welcome dialogue exposes its conditional `[SPECIAL]` choice in the showcase.
- The Logic choice is paid and demonstrates Activity confirmation from Dialogue.
- The field-test Lead is `integration_field_test`; it reuses the Akihabara relay Incident without replacing the final Aquarium content.
- Save only at stable boundaries. Combat intentionally refuses saves while a cycle is executing.

## Temporary content

```text
data/content/events/integration_showcase_resume.tres
data/content/events/integration_field_test_ready.tres
data/content/events/integration_field_test_resume.tres
data/content/forum/threads/integration_field_test_button.tres
data/content/leads/integration_field_test_lead.tres
```

The route limits content quality, not system architecture. It uses the real StoryEvent, Effect, App, Dialogue, Lead, Incident, Local Area, Combat and Save pipelines. It should be removed or converted into an internal diagnostics route only after the final Prologue provides equivalent coverage.
