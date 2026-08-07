# NULL NETWORK — ROADMAP PHASE 14.5 — DEMO EXPERIENCE LOCK

> This document is a canonical amendment to `ROADMAP.md` and inserts **Phase 14.5 — Demo Experience Lock** between Phase 14 and Phase 15.

## Why this phase exists

Phases 0–14 established the systemic foundation of the vertical slice. Before authored Prologue content is assembled on top of those systems, the player-facing experience of the demo's critical path must be reviewed and locked closely enough that Prologue content will not have to be rewritten around temporary UX or flow decisions.

This is **not** a final-art or general-polish phase.

The rule is:

```text
If changing it later would force Prologue content, StoryEvents, dialogues, routes,
activities, tutorials or progression beats to be rewritten, decide/fix it now.

If changing it later only makes the same behavior prettier, juicier or more polished,
it may remain placeholder until Phase 17 or the relevant art/content pass.
```

## Objective

Turn the existing systemic greyboxes into a stable **demo experience contract** for the complete critical path:

```text
Launch game
→ New Game / Load
→ SAFE MODE or COMMIT MODE
→ KubuOS boot
→ Desktop / Dock / Window System
→ Browser
→ denpa-channel
→ discover NULL NETWORK
→ Operator registration
→ starter selection
→ forum/download/install progression
→ Navigator
→ World Map / Local Area
→ interaction / Activity
→ Dialogue
→ first Combat
→ Combat resolution
→ Prologue completion
→ MAIN_CAMPAIGN Day 1
```

The phase does not author the final Prologue sequence itself. It defines and implements the interfaces and behaviors that Phase 15 will use.

## Review method

For each critical-path surface:

```text
1. Project owner specifies the intended player experience.
2. Audit the current implementation against that target.
3. Identify whether differences are structural, behavioral or cosmetic.
4. Implement structural/behavioral changes now.
5. Preserve existing data-driven architecture and save contracts where valid.
6. Add/update regression coverage for changed contracts.
7. Runtime-smoke-test the resulting flow.
8. Mark the surface EXPERIENCE LOCKED when remaining gaps are cosmetic/content-only.
```

Do not preserve a placeholder interaction merely because it already works if it would distort authored Prologue content.

Do not rewrite a stable system merely to replace temporary visuals.

## Critical-path surfaces to review

### 14.5.1 Campaign entry and boot

Review and lock:

```text
New Game / Load entry;
SAFE MODE / COMMIT MODE presentation;
campaign creation boundary;
KubuOS boot sequence;
what the player can access before the Prologue grants it;
initial app/window state;
resume behavior after save/load.
```

### 14.5.2 Desktop, Dock and Window System

Review and lock:

```text
window opening/closing/focus behavior;
Dock visibility and installed-app projection;
fullscreen and adaptive-display behavior;
app launch rules;
notifications that affect Prologue flow;
which behavior is diegetic versus conventional UI.
```

### 14.5.3 Browser and websites

Review and lock:

```text
navigation model;
address/history/back-forward behavior;
tabs if used by the demo flow;
loading/transitions;
link behavior;
denpa-channel presentation contract;
NULL NETWORK site structure;
registration route;
forum/download/install handoffs.
```

### 14.5.4 Operator registration

Review and lock:

```text
fields shown to the player;
identity/appearance/occupation presentation;
initial tendency allocation UX;
validation and confirmation;
post-registration navigation;
first-account and post-Operator-Loss presentation boundaries.
```

The visible flow must not reveal archived Operators or succession information to a player who has no in-world knowledge of it.

### 14.5.5 Starter selection

Review and lock:

```text
starter list and detail layout;
information exposed before selection;
nickname;
personality;
address term;
confirmation;
first-Prologue behavior;
post-Operator-Loss behavior;
which app/progression changes happen after selection.
```

Starter eligibility remains data-driven through `APKData`.

### 14.5.6 App installation and unlock presentation

Review and lock:

```text
NULL NETWORK installation;
Navigator installation;
progress/download presentation if present;
notifications;
Dock appearance;
StoryEvent/effect ownership of unlocks;
no premature app exposure.
```

### 14.5.7 Navigator — World Map and Local Area

Review and lock:

```text
World Map navigation;
location selection;
travel confirmation/cost presentation;
Local Area camera and movement;
interaction prompts;
EXE encounters;
NPC/Lead/Incident interaction boundaries;
transition into Dialogue and Combat;
return from Dialogue and Combat.
```

This contract is especially important because Phase 15 and Phase 16 will reuse it extensively.

### 14.5.8 Dialogue presentation

Review and lock:

```text
portrait layout;
speaker/text presentation;
advance behavior;
choices;
conditional choices;
activity-cost confirmation;
tendency feedback;
Navigator integration;
resume-from-save behavior.
```

Dialogue content may remain placeholder. The playback contract may not.

### 14.5.9 Activity and time feedback

Review and lock:

```text
how action cost is shown;
confirmation language;
final DAY/NIGHT/block preview;
insufficient-time feedback;
occupation conflicts;
when time visibly advances;
feedback after committed activities.
```

The existing transactional authority remains `ActivityManager`.

### 14.5.10 Combat UX contract

Review and lock the player-facing loop without requiring final combat art:

```text
encounter entry;
Timeline readability;
Module selection;
Player Actions;
targeting;
position/action changes;
damage/status/Stability feedback;
cycle execution;
run-away interaction;
victory/defeat presentation;
reward/resolution presentation;
return to Navigator.
```

Combat mechanics already validated in earlier phases should not be redesigned casually; the goal here is to ensure the demo communicates and operates them in the intended final form.

### 14.5.11 Prologue handoff

Review the complete boundary that Phase 15 will consume:

```text
first Operator exists;
starter exists;
correct apps are installed at the correct moment;
first exploration can begin;
first Dialogue and Combat can execute without debug;
Prologue completion can transition to MAIN_CAMPAIGN Day 1 cleanly.
```

## Explicitly deferred from Phase 14.5

Unless a specific item blocks the critical-path experience contract, do not stop this phase for:

```text
final sprites or portraits;
final animation sets;
final sound effects or music;
final combat VFX;
final typography/art pass across every app;
complete Profile polish;
complete Encyclopedia redesign;
complete Calendar polish;
full Social content;
all APK lines/evolutions;
all areas;
first-week content;
Aquarium content;
Legacy Recovery;
full economy/shops;
non-critical late-game systems.
```

## Gate

Phase 14.5 is complete when:

```text
[ ] Every critical-path surface above has been reviewed by the project owner.
[ ] The intended player-facing behavior is documented or directly represented by the implementation.
[ ] No known placeholder flow remains that would force Phase 15 content to be structurally rewritten later.
[ ] Remaining placeholders are cosmetic, asset-related or content-volume-related.
[ ] Cross-system handoffs are coherent from New Game through the first combat boundary.
[ ] Changed contracts have regression coverage where practical.
[ ] A manual smoke pass can traverse the locked critical-path shell without relying on debug-only UI for the reviewed portions.
```

After this gate passes, continue with **Phase 15 — Construction of the Prologue** from the main roadmap.

## Definition of EXPERIENCE LOCKED

A surface marked `EXPERIENCE LOCKED` does **not** mean final quality.

It means:

```text
its role in the player journey is decided;
its inputs/outputs are decided;
its major interactions are decided;
its information hierarchy is decided enough for authored content;
its cross-system handoffs are stable;
remaining work should not invalidate authored Prologue content.
```

If later playtesting proves a locked decision is wrong, it may still be changed. The lock exists to prevent knowingly building Phase 15 on top of temporary decisions, not to prohibit iteration.
