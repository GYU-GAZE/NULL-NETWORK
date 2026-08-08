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

A second rule prevents the phase from becoming an endless polish pass:

```text
Lock behavior before beauty.
Lock sequencing before spectacle.
Lock information hierarchy before final styling.
Lock system handoffs before final animation, VFX, music or sound design.
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

The desired end state is not "the demo looks finished". It is:

```text
Phase 15 can author the real Prologue without knowingly building on temporary
player-flow decisions that will later invalidate its content.
```

## Scope classification

Every gap found during Phase 14.5 must be classified before implementation.

### Structural

A structural gap changes ownership, sequencing, data flow, save boundaries or how systems connect.

Examples:

```text
an app unlock happens from the wrong owner;
a StoryEvent must wait for a transition but has no stable completion boundary;
a combat return path bypasses Navigator state;
a Prologue route depends on debug-only navigation;
a temporary page structure would force authored website content to be rebuilt;
a system exposes an app earlier than intended;
a save can resume into an invalid presentation state.
```

Structural gaps are fixed in Phase 14.5.

### Behavioral

A behavioral gap leaves the architecture intact but makes the player interaction operate differently from the intended final contract.

Examples:

```text
wrong confirmation order;
wrong input availability during a transition;
incorrect back/close behavior;
activity feedback appearing after rather than before commitment;
wrong dialogue advance behavior;
combat controls exposing actions in the wrong step;
window focus behaving differently from the intended KubuOS experience.
```

Behavioral gaps are fixed in Phase 14.5 when they affect the critical path.

### Cosmetic

A cosmetic gap changes presentation quality without changing the same interaction's meaning, ownership or sequence.

Examples:

```text
placeholder sprite;
placeholder portrait;
final easing curve;
particle density;
final sound sample;
final typography treatment;
final color grading;
extra decorative motion.
```

Cosmetic gaps are documented and deferred unless they prevent the player from understanding or validating the experience contract.

## Structural juice versus cosmetic polish

NULL NETWORK depends heavily on UI feel, so Phase 14.5 must not interpret all "juice" as optional polish.

**Structural presentation feedback** belongs here when it communicates state or establishes sequencing that authored content depends on.

Examples:

```text
whether input is blocked while an app transition is active;
when a StoryEvent may continue after opening or navigating an app;
minimum feedback that an Activity was committed and time advanced;
minimum feedback that an app was installed;
minimum feedback that a Timeline slot or combat target changed;
minimum feedback that Dialogue or Combat has entered/exited its mode;
notification sequencing when it gates the next player action;
DAY→NIGHT transition boundary if content must wait for it.
```

**Cosmetic polish** remains deferred:

```text
final particles;
final screenshake tuning;
final button squash/stretch;
final transition easing;
final combat VFX;
final sound effects;
final music cues;
final portrait animation;
final decorative glow treatment.
```

The minimum presentation implemented here should make the state change readable and the handoff deterministic. It does not need final assets.

## Review method

For each critical-path surface:

```text
1. Project owner specifies the intended player experience.
2. Audit the current implementation against that target.
3. Classify every gap as structural, behavioral or cosmetic.
4. Implement structural/behavioral changes now.
5. Preserve existing data-driven architecture and save contracts where valid.
6. Reuse existing signals/completion boundaries before adding new ones.
7. Add a new signal/contract only when no existing boundary can represent the required handoff cleanly.
8. Add/update regression coverage for changed contracts.
9. Runtime-smoke-test the resulting flow.
10. Mark the surface EXPERIENCE LOCKED when remaining gaps are cosmetic/content-only.
```

Do not preserve a placeholder interaction merely because it already works if it would distort authored Prologue content.

Do not rewrite a stable system merely to replace temporary visuals.

Do not introduce Prologue-specific waits, fixed delays or direct app-to-app calls to compensate for missing lifecycle boundaries.

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

### 14.5.11 Presentation, transition and feedback contract

Review the cross-system presentation grammar used by the critical path.

The goal is not to create final animation or sound assets. The goal is to define **when a transition begins, what may happen while it is active, when it is logically complete, and what system may continue afterward**.

Review and lock the required lifecycle behavior for:

```text
app open;
app close;
window focus change;
website navigation/loading;
Local Area entry/exit;
Dialogue entry/exit;
Combat entry/exit;
Activity commitment and visible time advancement;
DAY→NIGHT transition;
app installation;
Lead discovery/activation;
evolution entry/exit when it can interrupt Combat.
```

For each transition family, define:

```text
trigger/owner;
minimum player-facing feedback;
input policy while active;
logical completion boundary;
resume behavior after save/load if relevant;
which waiting system is allowed to continue afterward.
```

Implementation rule:

```text
Prefer existing signals and lifecycle callbacks when they already express the boundary.
Add a reusable signal/contract only when the audit proves that the required boundary
cannot be represented cleanly by the current architecture.

Never solve sequencing with arbitrary fixed delays inside StoryEvents, Dialogues or
app-specific Prologue code.
```

This surface is cross-cutting. It should be reviewed alongside the owning systems rather than implemented as a parallel "transition manager" by default.

### 14.5.12 Prologue handoff

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
final decorative hover/pressed animation treatment;
final particles/screenshake/glow tuning;
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

## Anti-scope-creep test

Before adding work to Phase 14.5, answer these questions in order:

```text
1. Will leaving this unchanged force Phase 15 authored content to be rewritten later?
   YES → Phase 14.5.
   NO  → continue.

2. Does the critical path currently communicate the state change badly enough that
   the intended interaction cannot be evaluated or authored reliably?
   YES → implement minimum structural feedback in Phase 14.5.
   NO  → continue.

3. Does the change only improve visual/audio polish while preserving the exact same
   interaction, ownership, timing and handoff?
   YES → defer to Phase 17 or the relevant art/content pass.
```

## Gate

Phase 14.5 is complete when:

```text
[ ] Every critical-path surface above has been reviewed by the project owner.
[ ] The intended player-facing behavior is documented or directly represented by the implementation.
[ ] No known placeholder flow remains that would force Phase 15 content to be structurally rewritten later.
[ ] Remaining placeholders are cosmetic, asset-related or content-volume-related.
[ ] Cross-system handoffs are coherent from New Game through the first combat boundary.
[ ] Presentation/transition lifecycle boundaries are deterministic where Prologue sequencing depends on them.
[ ] No Prologue-critical sequencing relies on arbitrary fixed delays or direct cross-app hacks.
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
its transition/completion boundary is defined when another system depends on it;
remaining work should not invalidate authored Prologue content.
```

If later playtesting proves a locked decision is wrong, it may still be changed. The lock exists to prevent knowingly building Phase 15 on top of temporary decisions, not to prohibit iteration.