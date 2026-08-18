extends RichTextEffect
class_name TypewriterGlyphRevealEffect

## Per-glyph reveal used by TypewriterReveal. Characters keep their authored
## size at all times; the presentation is a short digital lock-in made from
## whole-pixel offsets, alpha and a restrained cool flash. This avoids glyph
## geometry overshoot/clipping on pixel fonts.
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
	var reveal_time := 0.0
	if char_fx.relative_index < reveal_times.size():
		reveal_time = reveal_times[char_fx.relative_index]

	var raw_progress := (char_fx.elapsed_time - reveal_time) / reveal_seconds
	if raw_progress <= 0.0:
		char_fx.color.a = 0.0
		return true

	var progress := clampf(raw_progress, 0.0, 1.0)
	if progress < 0.26:
		char_fx.offset += Vector2(-1, 0)
	elif progress < 0.54:
		char_fx.offset += Vector2(1, 0)
	elif progress < 0.76:
		char_fx.offset += Vector2(0, -1)

	var alpha_progress := _ease_out_cubic(minf(progress / 0.78, 1.0))
	char_fx.color.a *= alpha_progress
	if progress < 0.64:
		var flash_strength := 1.0 - (progress / 0.64)
		char_fx.color.r *= lerpf(1.0, 0.82, flash_strength)
		char_fx.color.g *= lerpf(1.0, 1.08, flash_strength)
		char_fx.color.b *= lerpf(1.0, 1.24, flash_strength)
	return true


func _ease_out_cubic(value: float) -> float:
	var inverse := 1.0 - clampf(value, 0.0, 1.0)
	return 1.0 - inverse * inverse * inverse
