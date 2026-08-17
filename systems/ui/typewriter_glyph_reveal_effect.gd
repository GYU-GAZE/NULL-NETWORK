extends RichTextEffect
class_name TypewriterGlyphRevealEffect


var bbcode: String = "typewriter_grow"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var reveal_times: PackedFloat32Array = char_fx.env.get(
		"reveal_times",
		PackedFloat32Array()
	)
	var reveal_seconds: float = maxf(
		0.01,
		float(char_fx.env.get("reveal_seconds", 0.14))
	)
	var overshoot: float = maxf(
		0.0,
		float(char_fx.env.get("overshoot", 0.08))
	)
	var reveal_time := 0.0
	if char_fx.relative_index < reveal_times.size():
		reveal_time = reveal_times[char_fx.relative_index]

	var progress := clampf(
		(char_fx.elapsed_time - reveal_time) / reveal_seconds,
		0.0,
		1.0
	)
	var height_scale := _resolve_height_scale(progress, overshoot)
	var glyph_transform := char_fx.transform
	# Glyph transforms use the font baseline as their origin. Scaling only the Y
	# basis therefore grows the glyph upward without moving its feet.
	glyph_transform.y *= height_scale
	char_fx.transform = glyph_transform
	char_fx.color.a *= _ease_out_cubic(minf(progress / 0.72, 1.0))
	return true


func _resolve_height_scale(progress: float, overshoot: float) -> float:
	if progress < 0.72:
		return _ease_out_cubic(progress / 0.72)
	if progress < 0.86:
		return lerpf(1.0, 1.0 + overshoot, (progress - 0.72) / 0.14)
	return lerpf(1.0 + overshoot, 1.0, (progress - 0.86) / 0.14)


func _ease_out_cubic(value: float) -> float:
	var inverse := 1.0 - clampf(value, 0.0, 1.0)
	return 1.0 - inverse * inverse * inverse
