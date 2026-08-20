extends Node

const REGISTRATION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/operator_succession_registration.tscn"
)
const ASSESSMENT_DATA: CompatibilityAssessmentData = preload(
	"res://data/content/onboarding/compatibility_assessment_v1_1.tres"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var registry_errors := ContentRegistry.reset_to_default_catalog()
	_check(registry_errors.is_empty(), "Default content catalog failed: %s" % registry_errors)
	CampaignState.reset_campaign()

	var page := REGISTRATION_SCENE.instantiate() as OperatorCreationRevampedPage
	_check(page != null, "Registration scene is not using OperatorCreationRevampedPage.")
	if page == null:
		_finish_test()
		return

	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.size = Vector2(832, 393)
	add_child(page)
	await _wait_frames(3)

	_check(
		page.find_child("ResultTendencyRows", true, false) != null,
		"Assessment result lost its staged Tendency rows."
	)
	_check(
		page.find_child("ResultTendencyContext", true, false) != null,
		"Assessment result lost its Tendency hover context."
	)
	_check(
		page.find_child("ResultAssignmentIntro", true, false) != null,
		"Assessment result lost its assignment declaration."
	)
	_check(
		page.find_child("PartnerArrivalStage", true, false) != null,
		"Registration completion lost its partner materialization stage."
	)

	page._assessment_result = {
		"candidate_id": "REVQUIRE",
		"tendencies": {
			"valour": 6,
			"logic": 4,
			"sync": 3,
			"self": 2,
		},
		"variant_placeholder": {
			"selected_variant_id": "",
		},
	}
	await page._show_page(OperatorCreationPage.FlowPage.RESULT, false, false)
	page._show_result_content(true)
	await _wait_frames(2)

	var tendency_rows := page.find_child("ResultTendencyRows", true, false) as VBoxContainer
	_check(
		tendency_rows != null and tendency_rows.get_child_count() == 4,
		"Assessment result must render exactly VALOUR, LOGIC, SYNC and SELF."
	)
	if tendency_rows != null:
		for child: Node in tendency_rows.get_children():
			var row := child as Button
			_check(row != null, "Tendency result entry is not an interactive row.")
			if row == null:
				continue
			_check(not row.tooltip_text.is_empty(), "%s has no hover context." % row.name)
			_check(row.visible, "%s was not settled on restored result presentation." % row.name)

		if tendency_rows.get_child_count() > 0:
			var first_row := tendency_rows.get_child(0) as Control
			if first_row != null:
				var rest_position := first_row.position
				first_row.hide()
				await page._enter_presentation_control(first_row, 0.02)
				_check(
					first_row.position == rest_position,
					"Container-owned Tendency row position was mutated by presentation motion."
				)
				_check(
					first_row.scale == Vector2.ONE,
					"Tendency row did not settle back to native pixel scale."
				)

	var species := page.find_child("ResultAssignedSpecies", true, false) as Label
	_check(
		species != null and species.text == "REVQUIRE",
		"Assessment result did not declare the assigned species."
	)
	_check(
		page._result_preview != null and page._result_preview.get_reveal_steps().size() == 6,
		"Partner compatibility card does not expose its six staged information blocks."
	)
	if page._result_preview != null:
		_check(
			page._result_preview.get_overworld_sprite() != null,
			"Resolved starter does not expose an overworld/profile sprite for materialization."
		)
		var panel_style := page._result_preview.get_theme_stylebox("panel") as StyleBoxFlat
		_check(
			panel_style != null and panel_style.bg_color.get_luminance() < 0.2,
			"Partner compatibility card regressed to the old bright visual language."
		)

	var comment := OperatorCreationRevampedPage.PARTNER_COMMENT_CATALOG.get_line(
		"novire_init",
		"valour"
	)
	_check(
		"VALOUR" in comment,
		"First-sync partner comment no longer reacts to the Operator's dominant Tendency."
	)
	_check(page.accept_result_button.text == "ACCEPT PARTNER", "Primary result action lost its final label.")
	_check(page.result_manual_button.text == "CHOOSE MANUALLY", "Manual result fallback lost its final label.")

	page.queue_free()
	await _wait_frames(2)
	_finish_test()


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("OPERATOR_RESULT_PRESENTATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	print("OPERATOR_RESULT_PRESENTATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
