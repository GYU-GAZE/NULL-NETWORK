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
- Roadmap phase: **Phase 13 — Profile, Encyclopedia and Calendar**
- Current subphase: **13.3 Calendar**
- Phase 12 implementation: complete; party participation and shared EXP were manually confirmed in runtime.
- Phase 13.1 Profile: implemented and manually confirmed in runtime.
- Phase 13.2 Encyclopedia: implemented; automated gate is authored and awaits runtime/CI confirmation.
- Latest implementation head before this documentation checkpoint: `0d081c077991e67efc569c7fd964d8c37cad98dd`

The reusable campaign loop currently supports:

```text
Forum or Social source
→ persistent Lead
→ Navigator badge and Local Area Incident
→ paid Activity
→ Dialogue
→ Combat
→ centralized rewards and Encyclopedia observation
→ persistent campaign reaction
```

The Social and party branch supports:

```text
NetworkUserData identity
→ NPCData
→ Friend List
→ persistent chat
→ affinity
→ objective-owned party membership
→ PARTY_MEMBER combat actor
→ shared EXP
→ permanent NPC-partner loss
```

## Next exact task

Implement Phase 13.3 Calendar in this order:

1. Audit `TimeManager`, occupation schedules, StoryEvents, Leads, Incidents and existing Social hangout state.
2. Create immutable `CalendarEventData` and `CalendarCatalog` Resources.
3. Create a read-only Calendar projection service that merges authored events with current campaign/time state.
4. Keep known/hidden event state as stable IDs and plain values inside the existing campaign save architecture.
5. Create the Calendar app and condition-driven app Resource.
6. Complete the integrated Phase 13 gate: combat updates Profile and Encyclopedia; Calendar shows the next known event; all survive restart.

### Create next

```text
data/templates/calendar/calendar_event_data.gd
data/templates/calendar/calendar_catalog.gd
systems/calendar/calendar_projection_service.gd
apps/calendar/calendar_app.gd
apps/calendar/calendar_app.tscn
data/content/apps/app_calendar.tres
tests/calendar/calendar_app_test.gd
tests/calendar/calendar_app_test.tscn
```

## Active files

### Encyclopedia foundation

```text
data/templates/encyclopedia/encyclopedia_entry_data.gd
data/templates/encyclopedia/encyclopedia_record_data.gd
data/templates/encyclopedia/encyclopedia_state_data.gd
data/templates/encyclopedia/encyclopedia_catalog.gd
data/templates/conditions/encyclopedia_condition_data.gd
data/templates/content/encyclopedia_game_content_catalog.gd
systems/encyclopedia/encyclopedia_service.gd
systems/encyclopedia/encyclopedia_projection_service.gd
apps/encyclopedia/encyclopedia_app.gd
apps/encyclopedia/encyclopedia_app.tscn
data/content/encyclopedia/encyclopedia_catalog.tres
data/content/encyclopedia/entries/exe_rattildus.tres
data/content/apps/app_encyclopedia.tres
```

### Combat integration

```text
systems/combat/combat_resolution_service.gd
```

### Validation

```text
tests/encyclopedia/encyclopedia_app_test.gd
tests/encyclopedia/encyclopedia_app_test.tscn
.github/workflows/encyclopedia-app-validate.yml
```

## Phase 12 checkpoint — NPCs, Social and minimal party

### Immutable content

- `NPCData`, `NPCRoutineEntryData`, `NPCPersonalityData` and `NPCCatalog` define people, routines, presentation and party capability.
- NPCs reference existing `NetworkUserData` instead of duplicating forum identity.
- `ChatProfileData`, `ChatConversationData`, `ChatMessageData`, `ChatChoiceData` and `SocialInteractionData` define immutable Social content.
- Ganbarekun is integration content, not final Week One narrative authorship.

### Mutable state

`FriendListSocialStateData` persists only JSON-safe values and stable IDs:

```text
known contacts;
friend IDs;
affinity;
message history;
unread counts;
known presence;
completed interactions;
party memberships and owner IDs;
NPC partner progression and permanent-loss state.
```

Known NPC and friend are distinct concepts. The Social contact list is exactly the player's Friend List.

### Party, EXP and loss

- Active friends with valid `party_loadout` enter ordinary eligible encounters automatically.
- `CombatEncounter.active_party_slots` controls how many Social party members may be injected; zero creates an explicitly solo encounter.
- Membership records an `owner_id`, so only the owning Lead, Incident or event removes that temporary member.
- Completing a combat alone never removes the party. Content authors an explicit leave Effect at the correct narrative boundary.
- Total combat EXP is split among living eligible APK allies.
- Dummies never occupy an EXP share.
- An APK at zero HP or marked defeated receives no EXP.
- NPC partner EXP, level, HP and Stability persist separately from immutable `CharacterLoadout` content.
- An NPC partner reaching zero HP is marked permanently lost and removed from active party membership; friendship remains.
- Operator Partner Loss, TURD and Operator Loss remain Phase 14 responsibilities.

Manual runtime confirmation received:

```text
Ganbarekun enters ordinary Rattildus combat with his partner.
Profile installs and opens with the expected projected campaign data.
```

## Phase 13.1 checkpoint — Profile

```text
CampaignState / ContentRegistry / NetworkUserDatabase
→ ProfileProjectionService
→ OperatorProfileApp
```

`ProfileProjectionService` is read-only. It resolves stable IDs into presentation data and never writes a second Profile save section.

The app projects Operator identity, occupation, ranking, server, all four tendencies, partner identity and affinity, level/EXP, HP/Stability, calculated stats, Allocation Points, equipped/known Modules, money and typed inventory.

`ProfilePartnerStage` is an extensible `SubViewportContainer` scene. The current presentation is greybox; future room props, lighting, animation and interactions do not require changes to campaign progression.

`AppResource.auto_install_when_unlocked` provides generic condition-driven installation. Profile declares `PartnerConditionData.HAS_ANY` instead of being installed directly by APK progression.

## Phase 13.2 checkpoint — Encyclopedia

### Immutable content

`EncyclopediaEntryData` owns confirmed presentation and references:

```text
entry identity and kind;
subject APK;
summary;
SCAN, defeat, PURGE, PURIFY, TAME and loss notes;
related Module IDs;
related location IDs;
related evolution APK IDs.
```

`EncyclopediaCatalog` registers entries through `EncyclopediaGameContentCatalog`. Combat reward profiles are validated against registered Encyclopedia IDs.

### Mutable state

`EncyclopediaRecordData` and `EncyclopediaStateData` track independently:

```text
seen;
scanned;
defeated;
purged;
purified;
tamed;
lost;
known_modules;
known_locations;
known_evolutions;
per-milestone counters;
idempotent observation IDs;
first and last update action indices.
```

The existing `CampaignState.encyclopedia_state` remains the save section. `EncyclopediaService` materializes typed runtime state, migrates legacy `discovered`/`encountered` dictionaries and commits canonical JSON-safe dictionaries back to that same section.

### Combat and app projection

- `CombatResolutionService` records one observation per resolved enemy through `EncyclopediaService`.
- SCAN, PURGE, PURIFY and TAME are recorded independently.
- Confirmed Modules and the current location are attached to the entry without storing Resources in the save.
- Observation IDs prevent one resolved combat from being counted twice.
- `EncyclopediaProjectionService` resolves IDs for the UI but owns no state.
- The app installs automatically after the first confirmed entry and exposes search, kind filter, milestones, confirmed notes and resolved references.
- Forum data remains community/speculative information; Encyclopedia entries represent confirmed player observations.

## Required validation

### Phase 12

```text
Godot --headless --path . tests/social/npc_social_foundation_test.tscn
Godot --headless --path . tests/social/social_conversation_engine_test.tscn
Godot --headless --path . tests/social/social_app_test.tscn
Godot --headless --path . tests/social/friend_party_combat_test.tscn
Godot --headless --path . tests/combat/party_experience_distribution_test.tscn
```

### Phase 13 Profile

```text
Godot --headless --path . tests/profile/operator_profile_app_test.tscn
```

Manual Profile runtime check: confirmed working by the project owner.

### Phase 13 Encyclopedia

```text
Godot --headless --path . tests/encyclopedia/encyclopedia_app_test.tscn
```

Dedicated workflow:

```text
.github/workflows/encyclopedia-app-validate.yml
```

## Known gaps

- Current Profile ranking is projected from runtime `NetworkUserData`; a dedicated ranking progression authority does not yet exist.
- Profile and Encyclopedia visuals use greybox/placeholder assets and need a later UX/art pass.
- Calendar Resources and app do not exist yet.
- `known_evolutions` is supported by typed Encyclopedia state, but final evolution-discovery authorship is not yet wired to `EvolutionManager`.
- The `integration_field_test` and Aquarium Relay are system-integration content, not final Week One narrative content.
- Only NOVIRE has a complete starter integration Resource.
- Operator Partner Loss remains recoverable until Phase 14 implements TURD and Operator Loss.
- The latest Encyclopedia test has not been executed in this tool environment because no local Godot executable or observable GitHub Actions result is available.
