extends Node
class_name TypewriterReveal

signal reveal_started
signal character_revealed(character_index: int)
signal reveal_completed

@export_range(1.0, 240.0, 1.0) var characters_per_second: float = 42.0
@export_range(0.04, 0.4, 0.005) var glyph_reveal_seconds: float = 0.14
@export_range(0.0, 0.2, 0.005) var glyph_height_overshoot: float = 0.08

var _target: Control
var _full_text: String = ""
var _generation: int = 0
var _running: bool = false
var _glyph_effect := TypewriterGlyphRevealEffect.new()


func is_running() -> bool:
	return _running


func play(target: Control, text: String) -> void:
	_generation += 1
	var generation := _generation
	_target = target
	_full_text = text
	_running = true
	_prepare_target_text()
	_target.scale = Vector2.ONE
	_target.modulate.a = 1.0
	reveal_started.emit()

	var character_count := _get_total_character_count()
	if character_count <= 0:
		complete()
		return

	for character_index in range(1, character_count + 1):
		if generation != _generation or not _running:
			return
		if not _target is RichTextLabel:
			_set_visible_characters(character_index)
		character_revealed.emit(character_index - 1)
		await get_tree().create_timer(
			_get_character_delay(character_index - 1),
			true,
			false,
			true
		).timeout

	if _target is RichTextLabel and generation == _generation and _running:
		await get_tree().create_timer(glyph_reveal_seconds, true, false, true).timeout

	if generation == _generation and _running:
		complete()


func complete() -> void:
	if _target == null:
		_running = false
		return

	var was_running := _running
	_generation += 1
	_running = false
	_set_text(_full_text)
	_set_visible_characters(-1)
	_target.scale = Vector2.ONE
	_target.modulate.a = 1.0
	if was_running:
		reveal_completed.emit()


func cancel(clear_text: bool = false) -> void:
	_generation += 1
	_running = false
	if _target != null:
		_target.scale = Vector2.ONE
		_target.modulate.a = 1.0
		if clear_text:
			_set_text("")
			_set_visible_characters(0)


func _prepare_target_text() -> void:
	if not _target is RichTextLabel:
		_set_text(_full_text)
		_set_visible_characters(0)
		return

	var rich_label := _target as RichTextLabel
	var reveal_times := PackedFloat32Array()
	var elapsed := 0.0
	for character_index in range(_full_text.length()):
		reveal_times.append(elapsed)
		elapsed += _get_character_delay(character_index)

	rich_label.clear()
	rich_label.push_customfx(
		_glyph_effect,
		{
			"reveal_times": reveal_times,
			"reveal_seconds": glyph_reveal_seconds,
			"overshoot": glyph_height_overshoot,
		}
	)
	rich_label.add_text(_full_text)
	rich_label.pop()
	rich_label.visible_characters = -1


func _set_text(value: String) -> void:
	if _target is RichTextLabel:
		(_target as RichTextLabel).text = value
	elif _target is Label:
		(_target as Label).text = value
	else:
		push_error("TypewriterReveal target must be Label or RichTextLabel.")


func _set_visible_characters(value: int) -> void:
	if _target is RichTextLabel:
		(_target as RichTextLabel).visible_characters = value
	elif _target is Label:
		(_target as Label).visible_characters = value


func _get_total_character_count() -> int:
	if _target is RichTextLabel:
		return (_target as RichTextLabel).get_total_character_count()
	return _full_text.length()


func _get_character_delay(character_index: int) -> float:
	var base_delay := 1.0 / maxf(1.0, characters_per_second)
	if character_index < 0 or character_index >= _full_text.length():
		return base_delay
	match _full_text[character_index]:
		".", "!", "?":
			return base_delay * 4.0
		",", ";", ":":
			return base_delay * 2.2
		"\n":
			return base_delay * 2.8
		_:
			return base_delay
