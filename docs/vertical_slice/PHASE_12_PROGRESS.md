# Phase 12 — NPCs, Social and minimal party

## Current checkpoint

The Phase 12 foundation is implemented on `main`.

Completed:

- `NPCPersonalityData` for reusable interaction vocabulary.
- `NPCRoutineEntryData` for weekday/block schedules, presence and physical location.
- `NPCData` as the authoritative bridge between a person, `NetworkUserData`, routine, dialogue and party loadout.
- `NPCCatalog` with duplicate NPC and network-user validation.
- `SocialGameContentCatalog` extension and the default NPC catalog.
- `SocialStateData` for contacts, affinity, message history, unread state, known presence, completed interactions and objective-owned party membership.
- `SocialService` as the runtime mutation/query boundary over `CampaignState.social_state`.
- Affinity Effects routed through `SocialService` while preserving pre-contact affinity compatibility.
- Ganbarekun integration NPC reusing the existing forum identity.
- `NPC_SOCIAL_FOUNDATION_TEST` and a dedicated CI workflow.

## Architectural boundary

```text
NetworkUserData
→ public digital/forum identity

NPCData
→ immutable person, routine, world projection and party definition

SocialStateData
→ mutable campaign values and stable IDs only

SocialService
→ authoritative runtime API used by UI, Effects and future party resolution
```

`CampaignState.social_state` remains the serialized plain-Dictionary section. `SocialService` materializes it through `SocialStateData` and writes plain values back after each stable mutation.

## Next exact task

Implement the immutable chat-content layer in this order:

1. `ChatProfileData`
2. `ChatMessageData`
3. `ChatChoiceData`
4. `ChatConversationData`
5. `SocialInteractionData`
6. conversation evaluation and idempotent message projection in `SocialService`
7. the first Ganbarekun DM that creates a persistent Lead

Do not build the Social App UI before the conversation Resources and service projection are complete.
