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
