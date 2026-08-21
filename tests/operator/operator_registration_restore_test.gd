extends Node

const REGISTRATION_URL := "null.net/register"

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var registry_errors := ContentRegistry.reset_to_default_catalog()
	_check(
		registry_errors.is_empty(),
		"Default content catalog failed before registration restore test."
	)

	var first := await _instantiate_registration()
	if first == null:
		_finish_test()
		return

	await first._show_page(OperatorCreationPage.FlowPage.ASSESSMENT, false, false)
	first._question_index = 4
	first._render_assessment_question(true)
	await get_tree().process_frame
	_check(
		first._assessment_typewriter.is_running(),
		"Fresh Assessment question did not start its presentation."
	)
	_check(
		first.question_prompt.visible and first.question_prompt.is_visible_in_tree(),
		"Fresh Assessment question started with its prompt hidden."
	)
	_check(
		is_equal_approx(first.question_prompt.modulate.a, 1.0),
		"Fresh Assessment question started with a transparent prompt."
	)

	# Freeze automatic processing and advance the controller directly so the test
	# verifies the exact in-flight state that used to be logically progressing
	# while remaining visually blank.
	first._assessment_typewriter.set_process(false)
	first._assessment_typewriter._process(0.08)
	var partial_visible := first.question_prompt.visible_characters
	_check(
		partial_visible > 0 \
		and partial_visible < first.question_prompt.get_total_character_count(),
		"Fresh Assessment prompt did not expose a partial native character range."
	)
	_check(
		first.question_prompt.visible and is_equal_approx(first.question_prompt.modulate.a, 1.0),
		"Fresh Assessment prompt became hidden while its typewriter was in flight."
	)

	# Reproduce the actual navigation boundary that caused the runtime failure.
	# The first Back used to send QuestionPrompt through UiMotionPlayer.exit_control,
	# after which every later typewriter timeline progressed while the prompt was
	# visually blank. The prompt is now typewriter-owned and must survive both
	# backward and forward transitions without entering a generic motion lifecycle.
	await first._hide_assessment_question(false)
	first._question_index = 3
	first._render_assessment_question(true)
	await get_tree().process_frame
	_check(
		first._assessment_typewriter.is_running(),
		"Assessment prompt did not restart after a real Back transition."
	)
	_check(
		first.question_prompt.visible and first.question_prompt.is_visible_in_tree(),
		"Assessment prompt remained hidden after a real Back transition."
	)
	_check(
		is_equal_approx(first.question_prompt.modulate.a, 1.0),
		"Assessment prompt remained transparent after a real Back transition."
	)
	first._assessment_typewriter.set_process(false)
	first._assessment_typewriter._process(0.08)
	var back_partial := first.question_prompt.visible_characters
	_check(
		back_partial > 0 \
		and back_partial < first.question_prompt.get_total_character_count(),
		"Assessment prompt did not type progressively after a real Back transition."
	)

	await first._hide_assessment_question(true)
	first._question_index = 4
	first._render_assessment_question(true)
	await get_tree().process_frame
	_check(
		first._assessment_typewriter.is_running(),
		"Assessment prompt did not restart after returning forward to a visited question."
	)
	_check(
		first.question_prompt.visible and first.question_prompt.is_visible_in_tree(),
		"Assessment prompt remained hidden after returning forward."
	)
	first._assessment_typewriter.set_process(false)
	first._assessment_typewriter._process(0.08)
	var forward_partial := first.question_prompt.visible_characters
	_check(
		forward_partial > 0 \
		and forward_partial < first.question_prompt.get_total_character_count(),
		"Assessment prompt did not type progressively after returning forward."
	)
	_check(
		is_equal_approx(first.question_prompt.modulate.a, 1.0),
		"Assessment prompt became transparent after returning forward."
	)

	# Save while the prompt is deliberately still animating. Reopening the
	# Browser must restore the established question, not replay that animation.
	var stored_state := first.get_browser_state().duplicate(true)
	first.queue_free()
	await get_tree().process_frame

	var restored := await _instantiate_registration()
	if restored == null:
		_finish_test()
		return
	await restored.restore_browser_state(stored_state)
	await get_tree().process_frame

	_check(
		restored.get_current_flow_page() == OperatorCreationPage.FlowPage.ASSESSMENT,
		"Registration restore did not return to the saved Assessment page."
	)
	_check(
		restored._question_index == 4,
		"Registration restore lost the saved Assessment question index."
	)
	_check(
		not restored._assessment_typewriter.is_running(),
		"Restored Assessment replayed the typewriter presentation."
	)
	_check(
		restored.are_assessment_answers_ready(),
		"Restored Assessment did not settle answers into the ready state."
	)
	_check(
		restored.question_prompt.visible_characters == -1,
		"Restored Assessment prompt was not fully visible."
	)
	_check(
		restored.question_prompt.visible and restored.question_prompt.is_visible_in_tree(),
		"Restored Assessment prompt remained hidden after settled presentation."
	)
	_check(
		is_equal_approx(restored.question_prompt.modulate.a, 1.0),
		"Restored Assessment prompt remained transparent after settled presentation."
	)
	for child: Node in restored.answer_container.get_children():
		var button := child as AssessmentAnswerButton
		if button == null:
			continue
		_check(not button.disabled, "Restored Assessment left an answer disabled.")
		_check(
			is_equal_approx(button.modulate.a, 1.0),
			"Restored Assessment left an answer partially faded."
		)
		_check(
			button.scale.is_equal_approx(Vector2.ONE),
			"Restored Assessment left residual answer presentation scale."
		)

	# Normal navigation deliberately uses the same canonical presentation path.
	# Re-entering an established question after restore must still start cleanly.
	restored._render_assessment_question(true)
	await get_tree().process_frame
	_check(
		restored._assessment_typewriter.is_running(),
		"Revisited Assessment question did not use the canonical typewriter path."
	)
	_check(
		restored.question_prompt.visible and restored.question_prompt.is_visible_in_tree(),
		"Revisited Assessment question started with its prompt hidden."
	)
	restored._assessment_typewriter.set_process(false)
	restored._assessment_typewriter._process(0.08)
	var revisited_partial := restored.question_prompt.visible_characters
	_check(
		revisited_partial > 0 \
		and revisited_partial < restored.question_prompt.get_total_character_count(),
		"Revisited Assessment prompt did not expose characters progressively."
	)
	_check(
		is_equal_approx(restored.question_prompt.modulate.a, 1.0),
		"Revisited Assessment prompt became transparent during replay."
	)

	restored.queue_free()
	await get_tree().process_frame
	_finish_test()


func _instantiate_registration() -> OperatorSuccessionRegistrationPage:
	var page := SimulatedDNS.fetch_page(REGISTRATION_URL)
	_check(page != null, "Registration WebsitePage is missing.")
	if page == null or page.site_scene == null:
		return null
	var instance := page.site_scene.instantiate() as OperatorSuccessionRegistrationPage
	_check(
		instance != null,
		"Registration route no longer instantiates OperatorSuccessionRegistrationPage."
	)
	if instance == null:
		return null
	instance.set_anchors_preset(Control.PRESET_TOP_LEFT)
	instance.size = Vector2(832, 393)
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	return instance


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("OPERATOR_REGISTRATION_RESTORE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("OPERATOR_REGISTRATION_RESTORE_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
