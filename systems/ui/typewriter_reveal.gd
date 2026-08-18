extends Node
class_name TypewriterReveal

signal reveal_started
signal character_revealed(character_index: int)
signal reveal_completed

const PAUSE_SHORT_TAG := "{n}"
const PAUSE_LONG_TAG := "{nn}"
const CREEP_OPEN_TAG := "{creep}"
const CREEP_CLOSE_TAG := "{/creep}"
const GLITCH_OPEN_TAG := "{glitch}"
const GLITCH_CLOSE_TAG := "{/glitch}"

@export_range(1.0, 240.0, 1.0) var characters_per_second: float = 42.0
@export_range(0.03, 0.25, 0.005) var glyph_reveal_seconds: float = 0.09
@export_range(0.0, 0.5, 0.01) var short_pause_seconds: float = 0.11
@export_range(0.0, 1.0, 0.01) var long_pause_seconds: float = 0.30
@export_range(4.0, 30.0, 1.0) var creep_updates_per_second: float = 14.0
@export_range(4.0, 20.0, 1.0) var glitch_burst_checks_per_second: float = 9.0
@export_range(4, 40, 1) var glitch_burst_chance: int = 15

var _target: Control
var _full_text: String = ""
var _display_text: String = ""
var _running: bool = false
var _started_at_usec: int = 0
var _last_revealed_index: int = -1
var _timeline_duration: float = 0.0
var _reveal_times := PackedFloat32Array()
var _segments: Array[Dictionary] = []
var _glyph_effect := TypewriterGlyphRevealEffect.new()
var _creep_effect := CreepGlyphEffect.new()
var _glitch_effect := GlitchGlyphEffect.new()


func _ready() -> void:
	set_process(false)


func is_running() -> bool:
	return _running


func get_display_text() -> String:
	return _display_text


func get_timeline_duration() -> float:
	return _timeline_duration


func play(target: Control, text: String) -> void:
	if not _is_supported_target(target):
		push_error("TypewriterReveal target must be Label or RichTextLabel.")
		return
	if _running:
		cancel(false)
	_target = target
	_full_text = text
	_parse_source_text()
	_running = true
	_last_revealed_index = -1
	_started_at_usec = Time.get_ticks_usec()
	_prepare_target_for_reveal()
	_normalize_target()
	reveal_started.emit()

	if _display_text.is_empty() and _timeline_duration <= 0.0:
		_finish_natural_reveal()
		return
	set_process(true)


## Presents authored text directly in its settled state. This is intentionally
## separate from play(): restoring a saved UI state must not replay presentation.
func present(target: Control, text: String) -> void:
	if not _is_supported_target(target):
		push_error("TypewriterReveal target must be Label or RichTextLabel.")
		return
	if _running:
		cancel(false)
	_target = target
	_full_text = text
	_parse_source_text()
	_running = false
	set_process(false)
	_render_settled_text()
	_normalize_target()


func _process(_delta: float) -> void:
	if not _running:
		set_process(false)
		return
	if not is_instance_valid(_target):
		_running = false
		set_process(false)
		return

	var elapsed := float(Time.get_ticks_usec() - _started_at_usec) / 1000000.0
	var revealed_count := _get_revealed_character_count(elapsed)
	if _target is not RichTextLabel:
		_set_visible_characters(revealed_count)
	_emit_new_character_signals(revealed_count)

	if elapsed >= _timeline_duration:
		_finish_natural_reveal()


func complete() -> void:
	if not is_instance_valid(_target):
		_running = false
		set_process(false)
		return

	var was_running := _running
	_running = false
	set_process(false)
	_render_settled_text()
	_set_visible_characters(-1)
	_normalize_target()
	_emit_remaining_character_signals()
	if was_running:
		reveal_completed.emit()


func cancel(clear_text: bool = false) -> void:
	var was_running := _running
	_running = false
	set_process(false)
	if not is_instance_valid(_target):
		return
	if clear_text:
		if _target is RichTextLabel:
			(_target as RichTextLabel).clear()
		else:
			(_target as Label).text = ""
		_set_visible_characters(0)
	elif was_running:
		# Cancellation is a presentation interruption, not a content rollback.
		# Settle the authored text so hidden/reused controls never keep an old
		# RichTextEffect timeline running in the background.
		_render_settled_text()
		_set_visible_characters(-1)
	_normalize_target()


func _finish_natural_reveal() -> void:
	if not _running:
		return
	_running = false
	set_process(false)
	_set_visible_characters(-1)
	_normalize_target()
	_emit_remaining_character_signals()
	# RichTextLabel keeps the custom effects that are already mounted. At this
	# point every typewriter glyph is fully locked, while creep/glitch spans can
	# keep animating without a clear/rebuild flicker.
	reveal_completed.emit()


func _prepare_target_for_reveal() -> void:
	if _target is RichTextLabel:
		_render_rich_text(true)
		return
	(_target as Label).text = _display_text
	_set_visible_characters(0)


func _render_settled_text() -> void:
	if _target is RichTextLabel:
		_render_rich_text(false)
	else:
		(_target as Label).text = _display_text


func _render_rich_text(with_typewriter: bool) -> void:
	var rich_label := _target as RichTextLabel
	if rich_label == null:
		return
	rich_label.clear()
	for segment: Dictionary in _segments:
		var start := int(segment.get("start", 0))
		var end := int(segment.get("end", start))
		if end <= start:
			continue
		var segment_text := _display_text.substr(start, end - start)
		var pushed_effects := 0
		if with_typewriter:
			var local_reveal_times := PackedFloat32Array()
			for character_index in range(start, end):
				local_reveal_times.append(_reveal_times[character_index])
			rich_label.push_customfx(
				_glyph_effect,
				{
					"reveal_times": local_reveal_times,
					"reveal_seconds": glyph_reveal_seconds,
				}
			)
			pushed_effects += 1
		if bool(segment.get("creep", false)):
			rich_label.push_customfx(
				_creep_effect,
				{
					"rate": creep_updates_per_second,
					"amplitude": 1,
				}
			)
			pushed_effects += 1
		if bool(segment.get("glitch", false)):
			rich_label.push_customfx(
				_glitch_effect,
				{
					"burst_rate": glitch_burst_checks_per_second,
					"burst_chance": glitch_burst_chance,
					"amplitude": 1,
					"seed": start,
				}
			)
			pushed_effects += 1
		rich_label.add_text(segment_text)
		for _effect_index in range(pushed_effects):
			rich_label.pop()
	rich_label.visible_characters = -1


func _parse_source_text() -> void:
	_display_text = ""
	_reveal_times = PackedFloat32Array()
	_segments.clear()
	_timeline_duration = 0.0

	var elapsed := 0.0
	var source_index := 0
	var segment_start := 0
	var creep_depth := 0
	var glitch_depth := 0

	while source_index < _full_text.length():
		var matched_tag := ""
		if _matches_tag(_full_text, source_index, PAUSE_LONG_TAG):
			matched_tag = PAUSE_LONG_TAG
		elif _matches_tag(_full_text, source_index, PAUSE_SHORT_TAG):
			matched_tag = PAUSE_SHORT_TAG
		elif _matches_tag(_full_text, source_index, CREEP_OPEN_TAG):
			matched_tag = CREEP_OPEN_TAG
		elif _matches_tag(_full_text, source_index, CREEP_CLOSE_TAG):
			matched_tag = CREEP_CLOSE_TAG
		elif _matches_tag(_full_text, source_index, GLITCH_OPEN_TAG):
			matched_tag = GLITCH_OPEN_TAG
		elif _matches_tag(_full_text, source_index, GLITCH_CLOSE_TAG):
			matched_tag = GLITCH_CLOSE_TAG

		if not matched_tag.is_empty():
			if matched_tag == PAUSE_SHORT_TAG:
				elapsed += short_pause_seconds
			elif matched_tag == PAUSE_LONG_TAG:
				elapsed += long_pause_seconds
			else:
				_append_segment(
					segment_start,
					_display_text.length(),
					creep_depth > 0,
					glitch_depth > 0
				)
				if matched_tag == CREEP_OPEN_TAG:
					creep_depth += 1
				elif matched_tag == CREEP_CLOSE_TAG:
					creep_depth = maxi(0, creep_depth - 1)
				elif matched_tag == GLITCH_OPEN_TAG:
					glitch_depth += 1
				elif matched_tag == GLITCH_CLOSE_TAG:
					glitch_depth = maxi(0, glitch_depth - 1)
				segment_start = _display_text.length()
			source_index += matched_tag.length()
			continue

		var character := _full_text[source_index]
		_reveal_times.append(elapsed)
		_display_text += character
		elapsed += _get_character_delay_for_character(character)
		source_index += 1

	_append_segment(
		segment_start,
		_display_text.length(),
		creep_depth > 0,
		glitch_depth > 0
	)
	_timeline_duration = elapsed
	if not _reveal_times.is_empty():
		_timeline_duration = maxf(
			_timeline_duration,
			_reveal_times[_reveal_times.size() - 1] + glyph_reveal_seconds
		)


func _append_segment(start: int, end: int, creep: bool, glitch: bool) -> void:
	if end <= start:
		return
	_segments.append({
		"start": start,
		"end": end,
		"creep": creep,
		"glitch": glitch,
	})


func _matches_tag(source: String, start: int, tag: String) -> bool:
	if start < 0 or start + tag.length() > source.length():
		return false
	return source.substr(start, tag.length()) == tag


func _get_revealed_character_count(elapsed: float) -> int:
	var next_index := _last_revealed_index + 1
	while next_index < _reveal_times.size() and _reveal_times[next_index] <= elapsed:
		next_index += 1
	return next_index


func _emit_new_character_signals(revealed_count: int) -> void:
	while _last_revealed_index + 1 < revealed_count:
		_last_revealed_index += 1
		character_revealed.emit(_last_revealed_index)


func _emit_remaining_character_signals() -> void:
	_emit_new_character_signals(_display_text.length())


func _set_visible_characters(value: int) -> void:
	if not is_instance_valid(_target):
		return
	if _target is RichTextLabel:
		(_target as RichTextLabel).visible_characters = value
	elif _target is Label:
		(_target as Label).visible_characters = value


func _get_character_delay_for_character(character: String) -> float:
	var base_delay := 1.0 / maxf(1.0, characters_per_second)
	match character:
		".", "!", "?":
			return base_delay * 2.5
		",", ";", ":":
			return base_delay * 1.6
		"\n":
			return base_delay * 1.9
		_:
			return base_delay


func _normalize_target() -> void:
	if not is_instance_valid(_target):
		return
	_target.scale = Vector2.ONE
	_target.rotation = 0.0
	_target.modulate = Color.WHITE


func _is_supported_target(target: Control) -> bool:
	return is_instance_valid(target) and (target is Label or target is RichTextLabel)
