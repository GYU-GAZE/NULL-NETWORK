# Browser architecture and website authoring

This implementation is based on `e40649b615775c4138cdab67fbab7e439810fbff`, the consolidated KubuOS/WindowManager branch in PR #41, including PR #40. The OS remains at fixed 2x scale. No merge into main is part of this change.

## Create a website in the Editor

1. Open the project in Godot 4.6. Under Project Settings → Plugins, enable **Website Authoring** if it is disabled. The repository enables it by default.
2. Choose Project → Tools → Create Website.
3. Enter an internal identifier, URL, page title and destination folder under `res://`. Supply an optional favicon texture. The default catalog is `res://data/content/sites/website_catalog.tres`.
4. Select Document, Application or Viewport. Confirm Create and Register.
5. The plugin creates `<name>.tscn`, `<name>.tres`, updates the selected catalog and opens the scene. Edit its Content container and save. No Browser, DNS or autoload scene edit is needed.

Example: name `station_archive`, URL `archive.local`, title `Station Archive`, folder `res://data/content/sites/archive`, template Document. Open `archive.local` in the running Browser after saving.

The dialog and acceptance fixture call the same `WebsiteAuthoring.create_page(options)` implementation. It rejects invalid identifiers, unsupported/empty URLs, missing textures/templates/catalogs, duplicate normalized URLs and existing destination files. Validation and cancellation leave the catalog unchanged. The service saves both content files, writes a complete temporary catalog, and replaces the catalog last. A save failure removes its new files and temporary catalog. An existing `.pending.tres` blocks creation for explicit recovery. This is a single-editor workflow; it does not coordinate simultaneous writers or provide power-loss recovery across three files.

## Presentation contracts

| Policy | Root and sizing | Scroll owner |
| --- | --- | --- |
| `PAGE_SCROLL` (default) | Natural-height Container, normally VBoxContainer/MarginContainer; width follows available Browser content width | BrowserPageScrollHost and Browser ScrollContainer |
| `SELF_MANAGED_SCROLL` | Control/Container application fills the available content rectangle; scene provides its own ScrollContainer | The application scene |
| `FIXED_VIEWPORT` | Intentional viewport interface fills the available content rectangle; clipping is deliberate | No Browser document scroll |

Documents must propagate content height through Containers. Labels should wrap and use fit-content where appropriate. Avoid fixed document heights, root ScrollContainers and arbitrary root minima. The template's 600-unit width is an Editor preview rectangle, not a runtime minimum. `canvas_size` and its runtime getter have been removed entirely.

`BrowserPageSurface` owns the page rectangle without overwriting its authored `custom_minimum_size`. Browser motion changes only the wrapper's X offset and alpha. `BrowserPageScrollHost`, retained from PR #40, measures the explicit active surface. Outgoing surfaces never contribute to document height. Layout and motion no longer overwrite each other's geometry.

`ResponsiveColumns` is an Inspector-configurable Container: `separation` controls gaps; `horizontal_minimum_width` optionally imposes a wider stacking threshold. Normally it compares the sum of visible children's actual minima with available width. It lays out horizontally when they fit and stacks them otherwise. Its X minimum is the largest individual child minimum. Set child Expand/Fill flags for extra horizontal space. Child minimum/visibility changes and container resizing trigger native layout notifications; no per-frame polling or child scale resets are used.

`PreferredWidthContainer` separates a content card's preferred width from its real minimum. Use it to keep compact cards on wide pages while allowing later shrinking. Kubuchan replies use it to retain their measured content width and indentation without feeding the old width back into the document minimum. The page's own scroll panel uses an explicit empty style so its authored light background is not covered by the global dark application theme.

Keep a child's real minimum small enough to fit the smallest supported content width. Unbreakable text and arbitrary child minima cannot be repaired by a parent container. Use HFlowContainer for wrapping small metadata/actions. The Forum and Rankings retain aligned desktop rows and switch to compact metadata below their measured column budget; thread titles and navigation remain available.

## Existing route inventory

| Route | Contract | Migration |
| --- | --- | --- |
| `null.net` | Document | Responsive hero/portal links and header |
| `null.net/getstarted` | Document | Removed redundant article scroll; natural article height and responsive columns |
| `null.net/forums` | Self-managed | Existing application scroll; responsive shared header and compact table rows |
| `null.net/forums/thread/…` | Self-managed prefix | Existing thread scroll and page state retained |
| `null.net/playerrankings` | Self-managed | Existing scroll; compact ranking metadata |
| `null.net/register` | Self-managed | Account, appearance and name/expression columns stack; registration logic retained |
| `null.net/select-starter` | Self-managed | Responsive selection/detail columns, wrapping actions/title; selection logic retained |
| `null.net/updates` | Self-managed | Existing application scroll retained |
| `null.net/profile/…` | Self-managed prefix | Policy made explicit to match existing internal scroll |
| `kubuchan.net` | Self-managed | Existing thread scroll/state retained; metadata/footer wrap and reply width can shrink after expansion |
| `kubus://home` | Self-managed | Existing home application; subtitle wraps |

No production route requires intentional fixed clipping after this audit. The viewport template and acceptance fixture exercise that contract. Existing visual themes, assets, authored posts and gameplay Resources are retained. The former adaptive helper only applied a theme; scenes now reference that theme directly and use actual responsive Containers where needed.

Routes share `BrowserRoute.normalize`: trim, lowercase, remove HTTP(S)/www prefix and trailing slash. Exact routes override prefixes. Prefixes match a complete path segment, with the longest matching prefix winning. Duplicate exact routes and duplicate prefixes are validation errors; an exact override and nested prefixes are intentional. The creation dialog rejects any canonical URL already present, so these advanced route combinations require an explicit Resource edit. `WebsiteCatalog.validate_data()` also checks null entries, missing scenes and policy/root compatibility; DNS reports those diagnostics when rebuilding routes.

## Actions, links and reactive conditions

`SiteActionData` is the shared definition: conditions, GameEffectData effects, destination URL, failed-condition alert, success alert and optional `KubuNotificationData` Resource. It uses the existing condition/effect systems. Nothing in this pipeline creates a second gameplay-state store.

For an ordinary button, instantiate `res://apps/browser/components/navigation_button.tscn` or attach SiteActionButton and assign its action Resource. Configure its failed-condition behavior in the Inspector: keep clickable with authored failure feedback, disable, or hide. For a card or other Control, add a SiteActionBinding child, assign the same Resource and choose the behavior. It connects Button.pressed or generic Control mouse/keyboard input. Custom list controls may set `connect_input = false` and call `trigger()` from their existing selection signal. `availability_changed` exposes presentation updates.

For rich text, add entries to `SiteRichTextLabel.actions`, such as `enroll` → SiteActionData, then write `[url=action:enroll]Enroll[/url]`. A direct `[url=nav:null.net/forums]Forum[/url]` remains a plain navigation link. Legacy local `ref:`/`scroll_y:` links and existing `dialogue:` content remain supported. Unused direct flag/number/alert/notification string commands were removed; new gameplay interactions use Resources and SiteActionRunner.

SiteActionRunner verifies that the page is active, checks conditions with the shared GameEffectContext, applies effects, and only then publishes success feedback and navigation. A blocked action cannot apply effects. A failed effect suppresses success notifications/alerts/navigation. The existing effect pipeline is not transactional: earlier effects may already have applied before a later effect fails. Use effect definitions with appropriate existing failure semantics.

Structured notification publishing duplicates the definition, generates a fresh runtime identity, clears read state and preserves type, priority, icon, routing and metadata. Browser context supplies missing source/target defaults. Existing simple title/message fields remain readable for migrated content and are used only when no structured Resource is supplied.

Condition Resources declare dependencies through `get_change_dependencies()`: exact flag keys, number keys, CampaignState sections, and time. ConditionSetData combines its children's declarations. SiteActionBinding subscribes to the existing signals and refreshes only relevant keys/sections; full campaign reset refreshes all bindings. Custom conditions should implement that method. The base fallback observes the campaign domain. There is no `_process()` condition polling. `NumberConditionData` adds a reusable inclusive numeric range condition.

## Lifecycle, navigation and state

BrowserApp keeps explicit active page, incoming/outgoing surfaces, active context, entry and presentation revision. `_get_current_site()` returns the active reference, never the first child remaining in a host. New navigation invalidates the previous presentation, disables the outgoing context, cancels motion without restoring stale geometry and disposes abandoned surfaces. The latest navigation wins, including cross-policy transitions and rapid tab changes.

BrowserPageContext is installed on the page root before the page enters the tree. Any descendant can navigate through the ancestor context, including dynamically created buttons and rich links. Existing root/descendant `browser_navigation_requested` signals have a scoped compatibility bridge; a root signal does not prevent descendant registration. The bridge tracks later-added legacy nodes and disconnects on disposal. An outgoing context rejects actions/navigation.

Each BrowserTabData history item is a BrowserHistoryEntry with URL, primitive page-state dictionary and Browser-owned scroll offset. Back/Forward capture the current entry before changing the index. A new navigation truncates the forward branch. Repeated visits to the same URL keep independent state. Tabs and session export use that same entry structure.

Session schema v2 writes `entries`, history index and tab metadata. Existing v1 URL-string history is accepted; its single `site_state` migrates only into the current entry because earlier states were not recorded. Nodes, Resources and Callables are never serialized, including nested references. New forms can use BrowserFormState: add field NodePaths relative to that component in the Inspector. It saves LineEdit/TextEdit text, OptionButton selection, BaseButton toggle, Range value and other Controls' local visibility. This covers disclosure panels without a page-specific state script. Advanced scenes retain `get_browser_state() -> Dictionary` and `restore_browser_state(Dictionary)`; `_browser_forms` is reserved for infrastructure.

Document scroll is restored after state/layout changes establish the range, with clamping by ScrollContainer. Self-managed applications retain their page-specific state/scroll APIs. Do not change field paths between save versions without migrating the corresponding authored state.

## Reproducible checks and limits

Run with Godot 4.6 after importing the project:

```sh
godot --headless --path . tests/browser/browser_contract_unit_test.tscn
godot --headless --path . tests/browser/browser_authoring_pipeline_test.tscn
python3 tests/browser/run_editor_smoke.py --godot /absolute/path/to/godot --workspace /temporary/project-copy --output /temporary/editor.log --headless
```

Omit `--headless` on the Editor launcher for a native run; optionally add `--capture /absolute/path/editor.png`. The launcher uses an isolated copy and enables the test-only EditorPlugin there. Do not enable that smoke plugin in the production project. It invokes the actual production dialog, verifies generated scene/catalog/route, verifies that the Editor opened the scene, and rejects a duplicate without changing catalog bytes. Ordinary imports alone are not evidence of this workflow.

The acceptance fixture creates four pages using the production creation service and then authors content scenes/components/Resources. It never modifies the production catalog on disk. A deliberate temporary-path write failure verifies rollback after the scene and page files have been saved; the expected ResourceSaver error is bounded by AUTHORING_EXPECTED_WRITE_FAILURE markers in the log. It exercises long documents and reachable footer, revealed content, 600×400/320×250/430×320/700×480 layouts, rich/button/card actions, reactive keys, failure feedback, notification copies, dynamic links, repeated URLs, separate tabs, v1 migration/v2 restore, cancelled cross-policy transitions and repeated maximize/restore/resize of the authored page inside WindowManager. Production routes are checked at 390×300 logical Browser size. Native screenshots use the real GPU and fixed 2x project scaling; those routes are shown in the test's startup game state, not every narrative branch.

The Browser CI adds both runtime scenes and the actual isolated Editor workflow to the existing Browser gate. CI retains its existing missing-asset placeholders; local native visual evidence uses the repository assets. See `docs/validation/browser-authoring-results.json` for the measured full-suite baseline, unchanged failing scene set and focused final results. The suite is not all green: 16 scenes already failed on the dependency base. The Kubuchan test's invalid cast was repaired so its existing narrative assertion now executes and still fails; authored post text was not changed to satisfy it. Its reply-width assertion now checks the rendered rectangle instead of a removed implementation minimum. The onboarding compatibility test has a separate pre-existing Editor-only `Array(null)` parse error, verified in a fresh base Editor project. Editor smoke PASS establishes the website workflow, not an error-free whole-project Editor scan. Existing resource-leak warnings on shutdown are retained in the logs.
