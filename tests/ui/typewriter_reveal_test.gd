extends Node

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var reveal := TypewriterReveal.new()
	reveal.characters_per_second = 40.0
	reveal.short_pause_seconds = 0.11
	reveal.long_pause_seconds = 0.30
	add_child(reveal)

	var label := RichTextLabel.new()
	label.size = Vector2(640, 160)
	label.fit_content = true
	add_child(label)

	reveal.present(label, "A{creep}BC{/creep}{n}{glitch}DE{/glitch}")
	_check(
		reveal.get_display_text() == "ABCDE",
		"Authoring markup leaked into rendered text."
	)
	_check(
		label.get_total_character_count() == 5,
		"RichText effects changed the authored character count."
	)

	reveal.present(label, "AB")
	var baseline_duration := reveal.get_timeline_duration()
	reveal.present(label, "A{n}B")
	var short_duration := reveal.get_timeline_duration()
	reveal.present(label, "A{nn}B")
	var long_duration := reveal.get_timeline_duration()
	_check(
		short_duration >= baseline_duration + reveal.short_pause_seconds - 0.001,
		"{n} did not add the configured short pause to the reveal timeline."
	)
	_check(
		long_duration >= baseline_duration + reveal.long_pause_seconds - 0.001,
		"{nn} did not add the configured long pause to the reveal timeline."
	)
	_check(
		long_duration > short_duration,
		"{nn} must be longer than {n}."
	)

	var completion_state := {"count": 0}
	reveal.reveal_completed.connect(
		func() -> void: completion_state["count"] = int(completion_state["count"]) + 1
	)
	reveal.play(label, "LOCK{n}IN")
	_check(reveal.is_running(), "play() did not start the reveal timeline.")
	reveal.complete()
	_check(not reveal.is_running(), "complete() left the reveal timeline running.")
	_check(
		int(completion_state["count"]) == 1,
		"complete() did not emit reveal_completed exactly once."
	)
	_check(
		reveal.get_display_text() == "LOCKIN" and label.get_total_character_count() == 6,
		"complete() did not settle the markup-stripped authored text."
	)

	reveal.present(label, "RESTORED{creep}!{/creep}")
	_check(
		int(completion_state["count"]) == 1,
		"present() incorrectly emitted reveal_completed during state restoration."
	)
	_check(
		not reveal.is_running(),
		"present() must leave restored UI in a settled, non-running state."
	)

	label.queue_free()
	reveal.queue_free()
	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("TYPEWRITER_REVEAL_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("TYPEWRITER_REVEAL_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
