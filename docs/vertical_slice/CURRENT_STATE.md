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
- Current subphase: **13.1 Profile App**
- Phase 12 implementation: complete; automated gates are authored and awaiting an observable CI result.
- Latest implementation head before this documentation checkpoint: `25ebad2e2677e3718e3afe7d3e024f64433cd31f`

The project now supports the reusable campaign loop:

```text
Forum or Social source
→ persistent Lead
→ Navigator badge and Local Area Incident
→ paid Activity
→ Dialogue
→ Combat
→ centralized resolution
→ persistent campaign reaction
```

The Social branch additionally supports:

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

Finish the Profile gate, then begin the typed Encyclopedia architecture.

### First

Run:

```text
tests/profile/operator_profile_app_test.tscn
```

Confirm:

```text
Profile absent before starter selection;
Profile auto-installs when a valid PartnerState appears;
Operator identity, occupation, server and ranking project correctly;
all four tendencies render;
partner level, EXP, affinity, integrity and calculated stats render;
four equipped Modules render;
known Modules and inventory resolve from catalog IDs;
live mutations refresh the open app;
save/reload preserves the installation and projected values.
```

### Then create

```text
data/templates/encyclopedia/encyclopedia_entry_data.gd
data/templates/encyclopedia/encyclopedia_state_data.gd
data/templates/encyclopedia/encyclopedia_catalog.gd
systems/encyclopedia/encyclopedia_service.gd
apps/encyclopedia/encyclopedia_app.gd
apps/encyclopedia/encyclopedia_app.tscn
data/content/apps/app_encyclopedia.tres
```

The existing plain `CampaignState.encyclopedia_state` must be migrated rather than replaced with a second save authority.

## Active files

### Profile foundation

```text
systems/profile/profile_projection_service.gd
apps/profile/app_operator_profile.gd
apps/profile/app_operator_profile.tscn
apps/profile/partner_stage/profile_partner_stage.gd
apps/profile/partner_stage/profile_partner_stage.tscn
data/content/apps/app_profile.tres
```

### Generic app installation

```text
data/templates/app_resource.gd
core/autoloads/app_installation_manager.gd
data/content/apps/kubu_os_app_catalog.tres
```

### Validation

```text
tests/profile/operator_profile_app_test.gd
tests/profile/operator_profile_app_test.tscn
.github/workflows/profile-app-validate.yml
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

### Social runtime and UI

- `SocialService` is the mutation authority.
- `SocialInboxProjectionService` delivers unlocked content without falsely marking every conversation as read.
- The Social App projects friends, presence, unread state, history, choices, affinity and party status without owning narrative state.
- Significant Social interactions use `ActivityManager` and can apply Conditions and Effects.

### Party

- Active friends with valid `party_loadout` enter ordinary eligible encounters automatically.
- `CombatEncounter.active_party_slots` controls how many Social party members may be injected; zero creates an explicitly solo encounter.
- Membership records an `owner_id`, so only the owning Lead, Incident or event removes that temporary member.
- Completing a combat alone never removes the party. Content must author an explicit leave Effect at the correct narrative boundary.

### EXP and permanent loss

- Total combat EXP is split among living eligible APK allies.
- Dummies never occupy an EXP share.
- An APK at zero HP or marked defeated receives no EXP.
- Remainders are distributed deterministically by allied slot order.
- NPC partner EXP, level, HP and Stability persist separately from immutable `CharacterLoadout` content.
- An NPC partner reaching zero HP is marked permanently lost and removed from active party membership; friendship remains.
- Operator Partner Loss, TURD and Operator Loss remain Phase 14 responsibilities.

### Phase 12 validation scenes

```text
tests/social/npc_social_foundation_test.tscn
tests/social/social_conversation_engine_test.tscn
tests/social/social_app_test.tscn
tests/social/friend_party_combat_test.tscn
tests/combat/party_experience_distribution_test.tscn
```

Manual confirmation received:

```text
Ganbarekun enters ordinary Rattildus combat with his partner.
```

Automated markers authored:

```text
NPC_SOCIAL_FOUNDATION_TEST: PASS
SOCIAL_CONVERSATION_ENGINE_TEST: PASS
SOCIAL_APP_TEST: PASS
FRIEND_PARTY_COMBAT_TEST: PASS
PARTY_EXPERIENCE_DISTRIBUTION_TEST: PASS
```

These markers describe expected successful output; no current CI run has been observed for the latest implementation head.

## Phase 13.1 checkpoint — Profile App

### Architecture

```text
CampaignState / ContentRegistry / NetworkUserDatabase
→ ProfileProjectionService
→ OperatorProfileApp
```

`ProfileProjectionService` is read-only. It resolves stable IDs into runtime display data and never writes a second Profile save section.

### Profile projects

```text
Operator nickname and real name;
NULL NETWORK username;
occupation;
server;
ranking label;
VALOUR, LOGIC, SYNC and SELF;
partner species, nickname, form and integrity;
level and current-level EXP progress;
HP, Stability and calculated stats;
personality and address term;
affinity;
Allocation Points;
equipped Modules;
known active and secondary passive Modules;
money and typed inventory entries.
```

### Partner stage

`ProfilePartnerStage` is a reusable `SubViewportContainer` scene with separated backdrop, floor, shadow, sprite and overlay layers. The current art is greybox, but future room props, animation, lighting and interaction can be added without rewriting the Profile projection or replacing the root scene.

### Installation policy

`AppResource.auto_install_when_unlocked` provides generic condition-driven installation. The Profile app declares a `PartnerConditionData.HAS_ANY` condition and installs when a valid partner exists. APK progression does not call Profile directly.

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

Dedicated workflow:

```text
.github/workflows/profile-app-validate.yml
```

## Known gaps

- Current Profile ranking is projected from the runtime `NetworkUserData`; a dedicated ranking progression authority does not yet exist.
- Profile visuals use greybox art and the repository placeholder icon.
- Encyclopedia remains a plain dictionary and must become a typed state/service projection next.
- Calendar Resources and app do not exist yet.
- The `integration_field_test` and Aquarium Relay are system-integration content, not final Week One narrative content.
- Only NOVIRE has a complete starter integration Resource.
- Operator Partner Loss remains recoverable until Phase 14 implements TURD and Operator Loss.
- Latest Profile and Phase 12 tests have not been executed in this tool environment because no local Godot executable or observable GitHub Actions result is available.
