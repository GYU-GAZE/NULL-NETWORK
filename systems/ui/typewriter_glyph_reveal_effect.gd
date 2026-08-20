extends RichTextEffect
class_name TypewriterGlyphRevealEffect

## Presentation-only lock-in for glyphs that TypewriterReveal has already
## unlocked through visible_characters. This effect must never decide whether a
## character exists: visibility belongs exclusively to TypewriterReveal.
## Keeping one authority prevents reused Assessment RichTextLabels from holding
## an entire sentence at alpha zero until the custom-effect timeline catches up.
var bbcode: String = "typewriter_lock"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var reveal_times: PackedFloat32Array = char_fx.env.get(
		"reveal_times",
		PackedFloat32Array()
	)
	var reveal_seconds: float = maxf(
		0.01,
		float(char_fx.env.get("reveal_seconds", 0.09))
	)
	var reveal_time: float = 0.0
	if char_fx.relative_index < reveal_times.size():
		reveal_time = reveal_times[char_fx.relative_index]

	var raw_progress: float = (
		(char_fx.elapsed_time - reveal_time) / reveal_seconds
	)
	var progress: float = clampf(raw_progress, 0.0, 1.0)

	# visible_characters already guarantees that unrevealed glyphs are not drawn.
	# The effect only adds a restrained one-pixel lock-in once a glyph is visible;
	# it never multiplies alpha or hides content independently.
	if progress < 0.28:
		char_fx.offset += Vector2(-1, 0)
	elif progress < 0.58:
		char_fx.offset += Vector2(1, 0)

	if progress < 0.64:
		var flash_strength: float = 1.0 - (progress / 0.64)
		char_fx.color.r *= lerpf(1.0, 0.82, flash_strength)
		char_fx.color.g *= lerpf(1.0, 1.08, flash_strength)
		char_fx.color.b *= lerpf(1.0, 1.24, flash_strength)
	return true
