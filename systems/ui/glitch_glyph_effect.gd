extends RichTextEffect
class_name GlitchGlyphEffect

## Intermittent corruption burst. Unlike CreepGlyphEffect, the span remains
## perfectly stable most of the time and only breaks for short deterministic
## bursts. Offsets stay on whole logical pixels.
var bbcode: String = "glitch"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var burst_rate: float = maxf(1.0, float(char_fx.env.get("burst_rate", 9.0)))
	var burst_chance: int = maxi(4, int(char_fx.env.get("burst_chance", 15)))
	var amplitude: int = maxi(1, int(char_fx.env.get("amplitude", 1)))
	var seed: int = int(char_fx.env.get("seed", 0))
	var bucket := floori(char_fx.elapsed_time * burst_rate)
	var burst_noise := _stable_noise(bucket * 15485863 + seed * 32452843)
	if posmod(burst_noise, burst_chance) != 0:
		return true

	var glyph_noise := _stable_noise(
		burst_noise + char_fx.relative_index * 49979687
	)
	var x := posmod(glyph_noise, 5) - 2
	var y := posmod(glyph_noise >> 4, 3) - 1
	char_fx.offset += Vector2(
		float(x * amplitude),
		float(y * amplitude)
	)

	var flicker := posmod(glyph_noise >> 8, 4)
	if flicker == 0:
		char_fx.color.a *= 0.58
	elif flicker == 1:
		char_fx.color.r *= 1.14
		char_fx.color.b *= 1.22
	elif flicker == 2:
		char_fx.color.g *= 1.15
		char_fx.color.b *= 1.18
	return true


func _stable_noise(seed: int) -> int:
	var value := seed * 1103515245 + 12345
	value = value ^ (value >> 16)
	value *= 2246822519
	value = value ^ (value >> 13)
	return absi(value)
