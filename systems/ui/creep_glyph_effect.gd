extends RichTextEffect
class_name CreepGlyphEffect

## Sustained low-amplitude glyph tremor for threatening / gutural text.
## The effect only moves glyphs on whole logical pixels and never changes
## alpha, scale, rotation or layout, keeping pixel fonts readable.
var bbcode: String = "creep"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var rate: float = maxf(1.0, float(char_fx.env.get("rate", 14.0)))
	var amplitude: int = maxi(1, int(char_fx.env.get("amplitude", 1)))
	var phase_offset := float(char_fx.relative_index) * 0.37
	var tick := floori(char_fx.elapsed_time * rate + phase_offset)
	var glyph_seed := tick * 73428767 + char_fx.relative_index * 9122713
	var x_noise := _stable_noise(glyph_seed + 17)
	var y_noise := _stable_noise(glyph_seed + 53)

	var x := posmod(x_noise, 3) - 1
	var y_bucket := posmod(y_noise, 5)
	var y := 0
	if y_bucket == 0:
		y = -1
	elif y_bucket == 4:
		y = 1

	char_fx.offset += Vector2(
		float(x * amplitude),
		float(y * amplitude)
	)
	return true


func _stable_noise(seed: int) -> int:
	var value := seed * 1103515245 + 12345
	value = value ^ (value >> 16)
	value *= 2246822519
	value = value ^ (value >> 13)
	return absi(value)
