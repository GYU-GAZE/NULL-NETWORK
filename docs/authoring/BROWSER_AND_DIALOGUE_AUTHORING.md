# NULL NETWORK Content Authoring — Browser + Dialogue

This document describes the intended content-authoring path. Content creation should not require edits to BrowserApp, SimulatedDNS internals, DialogueManager, WindowManager, or motion systems.

## Browser page workflow

A normal simulated website is three things:

1. A `.tscn` scene containing the page UI.
2. A `WebsitePage` `.tres` describing its route and overflow behavior.
3. One entry in `data/content/sites/website_catalog.tres`.

### 1. Create the page scene

Put site-specific scenes under a clear site folder, for example:

```text
apps/browser/sites/example_site/example_page.tscn
```

The page scene owns only that page's UI. Do not add Browser tabs, address bars, window borders, or Browser-level scrolling to it.

### 2. Create the WebsitePage Resource

Create a `.tres` using `WebsitePage` and configure:

- `url`
- `page_title`
- `site_scene`
- `favicon` when available
- `overflow_policy`

Overflow rules:

- `FIXED_VIEWPORT`: the page is a viewport-like application and Browser clipping is intentional.
- `PAGE_SCROLL`: Browser owns the vertical page scroll. Use this for ordinary long websites.
- `SELF_MANAGED_SCROLL`: the page already owns its scrolling, such as Kubuchan.

Do not solve overflow by adding arbitrary offsets or resize callbacks inside each website.

### 3. Register the page once

Open:

```text
data/content/sites/website_catalog.tres
```

Add the `WebsitePage` Resource to `pages`.

Do not edit `core/autoloads/simulated_dns.tscn` for each new website. `SimulatedDNS` now consumes the catalog Resource.

## Site buttons and interactions

New gameplay-aware site buttons should use:

```text
SiteActionButton
└── action_data: SiteActionData
```

`SiteActionData` owns:

- availability conditions (`ConditionRuleData` / `ConditionSetData`)
- gameplay effects (`GameEffectData`)
- Browser target URL
- failed-condition alert
- optional success alert / notification

This means a website uses the same condition/effect language as dialogues and story systems instead of inventing flag logic inside Button scripts.

Example conceptual setup:

```text
SiteActionData
├── conditions
│   └── FlagConditionData
│       └── flag_name = "operator.registered"
├── effects = []
├── target_url = "null.net/forums"
└── show_failed_alert = true
```

The Null Network homepage is the reference implementation.

### Legacy fields

`SiteActionButton` still exposes legacy flag/number/visibility fields so old scenes continue to load. Do not use those fields for new gameplay content. New game-state behavior goes through `SiteActionData` + shared Conditions/Effects.

Local UI-only visibility manipulation may remain local to a site when it genuinely represents presentation rather than persistent game state.

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
