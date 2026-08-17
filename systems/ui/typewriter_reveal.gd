extends Node
class_name TypewriterReveal

signal reveal_started
signal character_revealed(character_index: int)
signal reveal_completed

@export_range(1.0, 240.0, 1.0) var characters_per_second: float = 42.0
@export_range(0.0, 0.2, 0.005) var glyph_pulse_seconds: float = 0.045
@export_range(0.0, 0.08, 0.005) var glyph_pulse_strength: float = 0.018

var _target: Control
var _full_text: String = ""
var _generation: int = 0
var _running: bool = false
var _pulse_tween: Tween


func is_running() -> bool:
	return _running


func play(target: Control, text: String) -> void:
	_generation += 1
	var generation := _generation
	_stop_pulse()
	_target = target
	_full_text = text
	_running = true
	_set_text(_full_text)
	_set_visible_characters(0)
	_target.pivot_offset = _target.size * 0.5
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
		_set_visible_characters(character_index)
		_play_glyph_pulse()
		character_revealed.emit(character_index - 1)
		await get_tree().create_timer(
			_get_character_delay(character_index - 1),
			true,
			false,
			true
		).timeout

	if generation == _generation and _running:
		complete()


func complete() -> void:
	if _target == null:
		_running = false
		return

	var was_running := _running
	_generation += 1
	_running = false
	_stop_pulse()
	_set_visible_characters(-1)
	_target.scale = Vector2.ONE
	_target.modulate.a = 1.0
	if was_running:
		reveal_completed.emit()


func cancel(clear_text: bool = false) -> void:
	_generation += 1
	_running = false
	_stop_pulse()
	if _target != null:
		_target.scale = Vector2.ONE
		_target.modulate.a = 1.0
		if clear_text:
			_set_text("")
			_set_visible_characters(0)


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


func _play_glyph_pulse() -> void:
	if _target == null or glyph_pulse_seconds <= 0.0:
		return
	_stop_pulse()
	_target.scale = Vector2(1.0 + glyph_pulse_strength, 1.0)
	_pulse_tween = create_tween().set_parallel(true)
	_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_pulse_tween.set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(
		_target,
		"scale",
		Vector2.ONE,
		glyph_pulse_seconds
	)


func _stop_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
