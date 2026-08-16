extends Node

const DATA: CompatibilityAssessmentData = preload(
	"res://data/content/onboarding/compatibility_assessment_v1_1.tres"
)
const AXES := ["INI", "STR", "SOC", "EXP", "ATT", "CUR", "ASP"]
const EXPECTED_MANUAL := [
	"REVQUIRE", "VOCALYTE", "WIZIP", "PABUBU", "TROJAW"
]

var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_check(DATA != null, "Compatibility Assessment v1.1 failed to preload.")
	if DATA == null:
		_finish_test()
		return

	var validation_errors := DATA.validate_data()
	_check(validation_errors.is_empty(), "Assessment data validation failed: %s" % validation_errors)
	_check(DATA.questions.size() == 18, "Assessment must contain exactly 18 questions.")
	_check(DATA.candidates.size() == 11, "Current Assessment must contain the eleven START-COMPATIBLE candidate profiles.")
	_check(Array(DATA.manual_candidate_ids) == EXPECTED_MANUAL, "Manual Allocation roster changed.")

	_check_axis_measurement_balance()
	_check_per_question_axis_distribution()
	_check_candidate_classes()
	_check_evaluation_contract()
	_finish_test()

func _check_axis_measurement_balance() -> void:
	var counts := {}
	for axis: String in AXES:
		counts[axis] = 0
	for question_value in DATA.questions:
		var question := question_value as CompatibilityQuestionData
		if question == null:
			continue
		for axis: String in question.measured_axes:
			counts[axis] = int(counts.get(axis, 0)) + 1
	for axis: String in AXES:
		_check(int(counts.get(axis, 0)) == 9, "Axis %s must be measured exactly nine times." % axis)

func _check_per_question_axis_distribution() -> void:
	for question_value in DATA.questions:
		var question := question_value as CompatibilityQuestionData
		if question == null:
			continue
		for axis: String in question.measured_axes:
			var weights: Array[int] = []
			for answer_value in question.answers:
				var answer := answer_value as CompatibilityAnswerData
				if answer != null:
					weights.append(int(answer.axis_weights.get(axis, 0)))
			weights.sort()
			_check(
				weights == [-2, -1, 1, 2],
				"%s axis %s must use -2/-1/+1/+2 exactly once." % [question.question_id, axis]
			)

func _check_candidate_classes() -> void:
	var standard_count := 0
	var extended_count := 0
	for candidate_value in DATA.candidates:
		var candidate := candidate_value as CompatibilityCandidateData
		if candidate == null:
			continue
		if candidate.candidate_class == CompatibilityCandidateData.CandidateClass.STANDARD:
			standard_count += 1
		else:
			extended_count += 1
	_check(standard_count == 5, "Assessment must keep five Standard Compatibility APKs.")
	_check(extended_count == 6, "Assessment must keep six Extended Compatibility APKs.")

func _check_evaluation_contract() -> void:
	var session := CompatibilitySessionData.new()
	for question_value in DATA.questions:
		var question := question_value as CompatibilityQuestionData
		if question == null or question.answers.is_empty():
			continue
		var answer := question.answers[0] as CompatibilityAnswerData
		if answer == null:
			continue
		session.note_question_visit(question.question_id)
		session.set_visual_order(question.question_id, PackedStringArray(["A", "B", "C", "D"]))
		session.record_answer(question.question_id, answer.answer_id, 0)

	var result := CompatibilityAssessmentService.evaluate(
		DATA,
		session,
		"normal",
		"never",
		""
	)
	var errors := PackedStringArray()
	var errors_value: Variant = result.get("errors", PackedStringArray())
	if errors_value is PackedStringArray:
		errors = errors_value
	else:
		errors.append("Evaluator returned an invalid errors payload.")
	_check(errors.is_empty(), "Assessment evaluator returned errors: %s" % errors)

	var tendencies := {}
	var tendencies_value: Variant = result.get("tendencies", {})
	if tendencies_value is Dictionary:
		tendencies = tendencies_value
	var total := (
		int(tendencies.get("valour", 0))
		+ int(tendencies.get("logic", 0))
		+ int(tendencies.get("sync", 0))
		+ int(tendencies.get("self", 0))
	)
	_check(total == 15, "Assessment Tendencies must normalize to exactly 15 points.")
	_check(not str(result.get("candidate_id", "")).is_empty(), "Assessment must resolve one compatibility candidate.")
	_check(bool(result.get("rush_detected", false)), "The deliberate same-position test corpus should trigger Rush Detection.")

	var variant := {}
	var variant_value: Variant = result.get("variant_placeholder", {})
	if variant_value is Dictionary:
		variant = variant_value
	_check(bool(variant.get("rush_blocked", false)), "Rush Detection must block Variant Node eligibility.")
	_check(not bool(variant.get("integration_ready", true)), "Variant Node application must remain on hold until runtime Variant content exists.")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish_test() -> void:
	if _failures.is_empty():
		print("COMPATIBILITY_ASSESSMENT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("COMPATIBILITY_ASSESSMENT_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
