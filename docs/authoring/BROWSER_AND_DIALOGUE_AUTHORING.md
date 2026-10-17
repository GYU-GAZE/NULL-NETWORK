# NULL NETWORK Content Authoring — Browser + Dialogue

This document describes the intended content-authoring path. Content creation should not require edits to BrowserApp, SimulatedDNS internals, DialogueManager, WindowManager, or motion systems.

## Browser page workflow

The supported creation path is Project → Tools → Create Website in the Godot Editor. Enter the internal name, normalized domain/page URL, title, destination folder and optional favicon. Choose Document for an ordinary website. The enabled Website Authoring plugin creates the scene and WebsitePage Resource, registers it in the selected WebsiteCatalog and opens the scene for editing.

Edit the generated Content container and save. Use natural-height Containers and wrapping text. Documents use Browser-owned vertical scroll by default. Application pages fill the viewport and provide their own scroll. Viewport pages deliberately clip. There is no canvas_size field or required per-page resize script.

Use ResponsiveColumns for columns that must stack when their child minima no longer fit. Use SiteActionButton or a SiteActionBinding child on another Control with a shared SiteActionData Resource for conditions, effects, feedback and navigation. SiteRichTextLabel supports an Inspector actions dictionary with `[url=action:key]` links. BrowserFormState stores Inspector-selected form/disclosure fields per history entry without a custom page script. Dynamic descendants obtain scoped navigation from their BrowserPageContext automatically.

Full instructions, route inventory, lifecycle/session contracts, Inspector configuration, compatibility details and reproducible Editor/runtime checks are in [Browser architecture and website authoring](../browser-architecture.md). That document also records validation limits and the dependency-base failures.

## Dialogue workflow

Dialogue content is data-driven. A normal conversation should not require editing `DialogueManager` or `DialoguePlayer`.

Create a `DialogueData` Resource containing:

```text
DialogueData
├── dialogue_id
├── initial_node_id
├── speakers[]
└── nodes[]
    ├── node_id
    ├── speaker_id
    ├── text
    ├── portrait_states[]
    ├── conditions
    ├── effects_on_enter[]
    ├── choices[]
    └── next_node_id
```

`DialogueNodeData` already supports shared `ConditionSetData` and `GameEffectData` Resources. Choices can branch and apply their own effects.

After creating the dialogue, register it in:

```text
data/content/game_content_catalog.tres
```

under `dialogues`.

Reference content:

```text
data/content/dialogues/prologue_null_network_welcome.tres
```

## Text presentation markup

Text using `TypewriterReveal` can use the project-wide authoring markup documented in:

```text
docs/ui/TEXT_PRESENTATION_MARKUP.md
```

This includes authored pauses and the CREEP / GLITCH effects. Keep presentation markup in authored text; do not create special-case animation scripts per dialogue.

## Rules for content authors

Do not edit these systems just to add ordinary content:

```text
apps/browser/browser.gd
core/autoloads/simulated_dns.gd
core/autoloads/dialogue_manager.gd
systems/window_manager/*
systems/ui/motion/*
```

If adding one site or one conversation requires changing one of those files, treat that as an authoring-pipeline problem rather than normal content work.

Prefer Resources for reusable conditions, effects, actions, dialogue nodes, and page metadata. Scenes should describe presentation; managers should own runtime rules; Resources should carry authored data.
