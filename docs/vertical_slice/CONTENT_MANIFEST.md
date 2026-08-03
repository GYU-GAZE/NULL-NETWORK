# NULL NETWORK — VERTICAL SLICE CONTENT MANIFEST

This file tracks content required to prove the systems. It does not replace the system roadmap. Stable IDs below are canonical where the roadmap already freezes them; descriptive entries receive IDs only when their content is authored.

States: `EXISTS`, `PARTIAL`, `MISSING`, `BLOCKED`.

## Shared system content

| Content | Minimum slice quantity | State | Blocking phase | Notes |
|---|---:|---|---:|---|
| Occupations | 3 | MISSING | 8 | NEET, High School Student, Salaryperson |
| Starter APKs | 5 | MISSING | 9 | NOVIRE, VOCALYTE, WIZIP, TROJAW, PAZUZU; greybox art allowed |
| Initial partner personalities | At least 1 valid result per starter | MISSING | 9 | Selection remains controlled by APK data |
| Initial district | 1 | PARTIAL | 11 | Akihabara test area exists; canonical Prologue starting area remains content work |
| Tutorial EXE | 1 | PARTIAL | 10 | Rattildus test encounter exists but lacks campaign resolution |
| Player Actions | 4 | MISSING | 10 | SCAN, PURGE, PURIFY, TAME |
| Core apps | 6 | PARTIAL | 5/13 | Browser and Navigator exist; Profile, Encyclopedia, Social and Calendar do not |
| Global UI text catalog | 1 | EXISTS | 4 | Interface text only; narrative stays in narrative Resources |
| StoryEvent integration gate | 1 | EXISTS | 6 | `story.prologue.null_network_welcome` proves orchestration and persistence; it does not replace the final Phase 15 Prologue sequence |
| Dialogue integration gate | 1 | EXISTS | 7 | `dialogue.prologue.null_network_welcome` proves six portraits, conditions, Effects, paid choice and persistence; final narrative dialogue remains Phase 15/16 content |

## Prologue

| ID/content | Type | State | Blocking phase | Completion condition |
|---|---|---|---:|---|
| `prologue.boot` | Story Event | MISSING | 6 | Starts diegetic KubuOS boot |
| `prologue.denpa_opened` | Story Event | MISSING | 6 | Detects intended denpa-channel entry |
| `prologue.null_link_clicked` | Story Event | MISSING | 6 | Opens NULL CHANNEL path |
| `prologue.registration_started` | Story Event | MISSING | 8 | Opens Operator creation |
| `prologue.registration_completed` | Story Event | MISSING | 8 | Persists Operator and tendencies |
| `prologue.forum_unlocked` | Story Event | MISSING | 6 | Makes forum available |
| `prologue.welcome_available` | Story Event | MISSING | 6 | Publishes only the tutorial thread |
| `prologue.welcome_read` | Story Event | MISSING | 6 | Detects completed reading |
| `prologue.download_available` | Story Event | MISSING | 6 | Unlocks download page |
| `prologue.app_installed` | Story Event | MISSING | 5/6 | Installs NULL NETWORK app state |
| `prologue.starter_selected` | Story Event | MISSING | 9 | Creates PartnerState |
| `prologue.navigator_installed` | Story Event | MISSING | 5/6 | Adds Navigator live |
| `prologue.first_area_entered` | Story Event | MISSING | 6/11 | Opens initial Local Area |
| `prologue.first_encounter_started` | Story Event | MISSING | 6/10 | Starts tutorial combat |
| `prologue.first_encounter_completed` | Story Event | MISSING | 6/10 | Applies persistent result |
| `prologue.completed` | Story Event | MISSING | 6 | Enters Main Campaign at Day 1, DAY block 0 |
| denpa-channel food thread | Website content | MISSING | 15 | Contains spammer link to NULL NETWORK |
| `null.net` | Website page | PARTIAL | 15 | NULL CHANNEL foundation exists; Prologue route must be finalized |
| `null.net/introduction` | Website page | MISSING | 15 | Explains game fiction |
| `null.net/get-started` | Website page | MISSING | 15 | Guides registration and install |
| `null.net/rankings` | Website page | PARTIAL | 15 | Uses existing ranking/user data |
| `null.net/register` | Website page | MISSING | 8/15 | Hosts Operator creation |
| `null.net/forums` | Website page | PARTIAL | 15 | Existing forum system becomes condition-gated |
| `null.net/download` | Website page | MISSING | 15 | Installs app through effect |
| `WELCOME, NEW PLAYERS` | Forum thread | MISSING | 15 | Teaches through existing NPC posts |
| starter introduction | Dialogue | MISSING | 7/15 | First partner conversation |
| tutorial encounter | CombatEncounter | PARTIAL | 10/15 | Must support persistent Player Actions and rewards |

## Day One / Monday micro-update

| Content | Minimum quantity | State | Blocking phase | Purpose |
|---|---:|---|---:|---|
| Boot update alert | 1 | MISSING | 6/16 | Announces micro-update |
| Changelog | 1 | MISSING | 16 | Technical note with cryptic clue |
| New forum threads | 3–5 | MISSING | 16 | Data miners and community response |
| Initial Lead | 1 | MISSING | 11/16 | Connects forum to exploration |
| Area/spawn change | 1 | MISSING | 11/16 | Proves world reaction |
| Calendar entry | 1 | MISSING | 13/16 | Exposes known weekly event |

## Tuesday through Friday

| Day | Required content | State | Dependencies |
|---|---|---|---|
| Tuesday | Aquarium Rumour thread; DM; available NPC; simple investigation; tendency choice | MISSING | 4, 6, 7, 11, 12 |
| Wednesday | Help thread; second EXE; SCAN opportunity; Encyclopedia data; partner reaction | MISSING | 7, 9, 10, 13 |
| Thursday | Guide thread; Lead advance; preparation/reward choice; party opportunity | MISSING | 4, 11, 12 |
| Friday | Counter change; light glitches; replies in old threads; spawn change; suspicious moderation; short mandatory event | MISSING | 6, 11, 16 |

Canonical clue progression from the GDD:

1. Rumour: Aquarium district acting weird.
2. Deleted screenshot discussion.
3. Help request about a lost partner.
4. Guide explaining Stability.
5. Aquarium encounter recontextualizes all earlier posts.

## Aquarium Incident

| Content | Minimum quantity | State | Blocking phase | Notes |
|---|---:|---|---:|---|
| Aquarium district unlock | 1 | MISSING | 11/16 | Driven by conditions/effects |
| Local Area | 1 | MISSING | 11/16 | Abandoned aquarium |
| Subareas | 2–3 | MISSING | 11/16 | Data-driven transitions |
| Common EXEs | 2 | MISSING | 9/11/16 | Spawn table content |
| Anomalous encounter | 1 | MISSING | 10/11/16 | Distinct combat state |
| Involved NPC | 1 | MISSING | 12/16 | Social and/or party link |
| Dialogue sequence | 1 | MISSING | 7/16 | Supports choices and persistence |
| Boss | 1 | MISSING | 10/16 | Uses final combat pipeline |
| Hardware/UI mechanic | 1 | MISSING | 16 | Authored only after systemic dependencies |
| Resolution branches | At least 2 observable outcomes | MISSING | 4/11/16 | Effects alter campaign/world state |
| Evolution opportunity | 1 | MISSING | 9/10/16 | Uses projected tendencies |
| Forum aftermath | 1 response set | MISSING | 6/16 | Old and new threads react |
| Slice completion event | 1 | MISSING | 6/16 | Marks vertical slice complete |

## Manifest maintenance

- Add content only when its owning system phase has passed.
- Every authored Resource must use a stable ID and appear in the relevant catalog.
- `PARTIAL` means an existing asset requires campaign integration; it does not mean the system gate passes.
- Greybox visual assets are acceptable; placeholder architecture and hardcoded Aquarium-only logic are not.
