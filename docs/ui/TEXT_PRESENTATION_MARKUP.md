# Text Presentation Markup

`TypewriterReveal` is the shared authoring surface for paced text presentation. The markup below is removed before display and never counts as visible characters.

## Timing

- `{n}` inserts a short authored pause. Default: `0.11s`.
- `{nn}` inserts a longer authored pause. Default: `0.30s`.

Example:

```text
There is nothing wrong with your account.{nn}Continue.
```

Punctuation still receives a small automatic cadence adjustment, but important dramatic timing should be authored explicitly with `{n}` / `{nn}`.

## CREEP

```text
{creep}I KNOW WHERE YOU LIVE.{/creep}
```

CREEP is a sustained threatening tremor. Each glyph constantly jitters by a tiny whole-pixel amount at a slightly different phase. It does **not** change alpha, color, scale, rotation, or glyph identity. The intent is gutural/emotional instability, not digital corruption.

Use it for text that should feel physically tense, angry, threatening, or wrong in a bodily way. Do not use it as generic decoration.

## GLITCH

```text
Connection established with {glitch}TENYA{/glitch}.
```

GLITCH is normally stable. At deterministic but irregular intervals the span receives a short corruption burst: small whole-pixel displacement plus restrained alpha/color flicker, then it returns to normal immediately.

Use it for digital corruption, unreliable rendering, transmission failure, or system interference. It is intentionally semantically different from CREEP.

## Nesting

Effects can be nested when the content genuinely calls for it:

```text
{creep}DO NOT {glitch}OPEN{/glitch} THE DOOR.{/creep}
```

Nested markup is parsed into effect spans; the authoring tags themselves are never shown.

## Restored UI

Use `TypewriterReveal.play(target, text)` for a presentation event that should animate.

Use `TypewriterReveal.present(target, text)` when restoring an already-established UI state. `present()` renders the final authored text immediately and does not emit `reveal_completed`, preventing saved windows/pages from replaying their entrance presentation.

## Pixel-art contract

All movement in CREEP, GLITCH, and the typewriter lock-in is performed in whole logical pixels. The typewriter reveal never scales glyph geometry. This is deliberate: Silver and other pixel fonts must not be deformed or left on subpixel coordinates.
