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
- Current subphase: **Phase 13 integrated validation**
- Phase 12 implementation: complete; party participation and shared EXP were manually confirmed in runtime.
- Phase 13.1 Profile: implemented and manually confirmed in runtime.
- Phase 13.2 Encyclopedia: typed architecture and greybox app implemented; behavior/UX is explicitly deferred for later redesign by project-owner decision.
- Phase 13.3 Calendar: implemented; automated gate is authored and awaits runtime/CI confirmation.
- Latest implementation head before this documentation checkpoint: `74a9c4fb61ad3e12acfd150712ecc73c7dc62f71`

The reusable campaign loop currently supports:

```text
Forum or Social source
→ persistent Lead
→ Navigator badge and Local Area Incident
→ paid Activity
→ Dialogue
→ Combat
→ centralized rewards and Encyclopedia observation
→ Profile and Calendar projections
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

Validate the Calendar and then close the integrated Phase 13 gate.

### First

Run:

```text
tests/calendar/calendar_app_test.tscn
```

Confirm:

```text
Calendar absent before Operator registration;
occupation registration auto-installs Calendar;
current date, weekday, DAY/NIGHT, hour and action block project correctly;
occupation schedule is converted into occupied time ranges;
remaining free blocks update after time advances;
Update 1.0 appears at the authoritative countdown day;
active Leads and available Incidents appear without revealing inactive content;
Calendar state reconstructs after save/reload.
```

### Then

Create or extend the integrated Phase 13 gate:

```text
combat resolves
→ Profile reflects EXP/tendencies
→ Encyclopedia contains the confirmed EXE record
→ Calendar contains routine and next known event
→ save/restart
→ all three projections remain coherent
```

After that gate is confirmed, advance to **Phase 14 — Commitment, Partner Loss, TURD and Operator Loss**.

## Active files

### Calendar foundation

```text
data/templates/calendar/calendar_event_data.gd
data/templates/calendar/calendar_catalog.gd
data/templates/content/calendar_game_content_catalog.gd
systems/calendar/calendar_projection_service.gd
apps/calendar/calendar_app.gd
apps/calendar/calendar_app.tscn
data/content/calendar/calendar_catalog.tres
data/content/calendar/events/update_1_0.tres
data/content/apps/app_calendar.tres
```

### Catalog and installation integration

```text
data/content/game_content_catalog.tres
data/content/apps/kubu_os_app_catalog.tres
core/autoloads/app_installation_manager.gd
```

### Validation

```text
tests/calendar/calendar_app_test.gd
tests/calendar/calendar_app_test.tscn
.github/workflows/calendar-app-validate.yml
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

`EncyclopediaEntryData`, `EncyclopediaRecordData`, `EncyclopediaStateData` and `EncyclopediaCatalog` provide typed confirmed-knowledge content and state.

The existing `CampaignState.encyclopedia_state` remains the only save section. `EncyclopediaService` materializes typed runtime state, migrates legacy dictionaries and writes canonical JSON-safe data back to the same section.

Combat records `seen`, `scanned`, `defeated`, `purged`, `purified`, `tamed`, `lost`, known Modules, locations and evolutions through idempotent observation IDs.

The current app and behavior do not match the final desired Encyclopedia experience. Do not expand or polish this UI until its intended information architecture is redefined with the project owner.

## Phase 13.3 checkpoint — Calendar

### Immutable content

`CalendarEventData` supports:

```text
absolute game-day events;
weekly events;
Update 1.0 countdown anchored events;
all-day or block-timed events;
visibility Conditions;
availability Conditions;
stable source and location IDs;
priority and event kind.
```

`CalendarCatalog` registers authored events through `CalendarGameContentCatalog`. The initial integration content is `calendar.update_1_0`.

### Projection

`CalendarProjectionService` is read-only and merges:

```text
TimeManager date and action-block state;
OccupationData weekly schedules;
visible authored CalendarEventData;
active Leads;
available Incidents.
```

It does not save duplicate dates, occupation routines, Leads or Incidents. These remain owned by their original systems.

### App installation and UI

- Calendar declares `OccupationConditionData.HAS_ANY` and auto-installs after Operator registration.
- The app shows an eight-day window so D-7 Update 1.0 is visible.
- Occupied occupation blocks are collapsed into readable contiguous time ranges.
- The UI refreshes from time, campaign, Lead, Incident and catalog signals.
- Current visuals are greybox and intentionally separable from projection logic.

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

### Phase 13 Calendar

```text
Godot --headless --path . tests/calendar/calendar_app_test.tscn
```

Dedicated workflow:

```text
.github/workflows/calendar-app-validate.yml
```

## Known gaps

- Current Profile ranking is projected from runtime `NetworkUserData`; a dedicated ranking progression authority does not yet exist.
- Profile and Calendar visuals use greybox/placeholder assets and need later UX/art passes.
- Encyclopedia behavior and UX are intentionally deferred for redesign.
- Calendar can project authored hangout events, but no player-facing hangout scheduling authority exists yet.
- `known_evolutions` is supported by typed Encyclopedia state, but final evolution-discovery authorship is not yet wired to `EvolutionManager`.
- The `integration_field_test` and Aquarium Relay are system-integration content, not final Week One narrative content.
- Only NOVIRE has a complete starter integration Resource.
- Operator Partner Loss remains recoverable until Phase 14 implements TURD and Operator Loss.
- Calendar and Encyclopedia tests have not been executed in this tool environment because no local Godot executable or observable GitHub Actions result is available.
