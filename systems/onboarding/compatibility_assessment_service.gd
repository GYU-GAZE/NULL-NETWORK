extends RefCounted
class_name CompatibilityAssessmentService

const AXES := PackedStringArray(["INI", "STR", "SOC", "EXP", "ATT", "CUR", "ASP"])
const TENDENCIES := PackedStringArray(["valour", "logic", "sync", "self"])
const VARIANTS := PackedStringArray([
	"COMBUSTIVE", "CRYOSIVE", "CONDUCTIVE", "CORROSIVE",
	"DEFENSIVE", "DESTRUCTIVE", "DEPLETIVE", "DECEPTIVE"
])

static func get_or_create_visual_order(
	question: CompatibilityQuestionData,
	session: CompatibilitySessionData
) -> PackedStringArray:
	if question == null or session == null:
		return PackedStringArray()
	var existing := session.get_visual_order(question.question_id)
	if existing.size() == question.answers.size():
		return existing
	var ids := PackedStringArray()
	for answer: CompatibilityAnswerData in question.answers:
		if answer != null:
			ids.append(answer.answer_id)
	if question.shuffle_answers:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in range(ids.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var value := ids[i]
			ids[i] = ids[j]
			ids[j] = value
	session.set_visual_order(question.question_id, ids)
	return ids

static func evaluate(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData,
	writing_style_id: String,
	kaomoji_preference_id: String,
	avatar_variant_hint: String = ""
) -> Dictionary:
	if assessment == null or session == null:
		return {"errors": PackedStringArray(["Assessment data or session is missing."])}
	var errors := assessment.validate_data()
	if not errors.is_empty():
		return {"errors": errors}
	if not session.is_complete(assessment.questions.size()):
		return {"errors": PackedStringArray(["Complete every assessment question before calculating compatibility."])}

	var raw_axes := _calculate_raw_axes(assessment, session)
	var axis_values := _normalize_axes(raw_axes)
	var rush := _calculate_rush_state(assessment, session)
	var confidence := _calculate_confidence(assessment, session, rush)
	var candidate_scores := _calculate_candidate_scores(assessment, axis_values, confidence)
	var selected_candidate := _highest_candidate(assessment, candidate_scores)
	var tendencies := _calculate_tendencies(assessment, session)
	var variant_result := _calculate_variant_placeholder(
		assessment,
		session,
		writing_style_id,
		kaomoji_preference_id,
		avatar_variant_hint,
		bool(rush.get("rush_detected", false))
	)

	return {
		"errors": PackedStringArray(),
		"raw_axes": raw_axes,
		"axis_values": axis_values,
		"axis_confidence": confidence,
		"rush_detected": bool(rush.get("rush_detected", false)),
		"candidate_scores": candidate_scores,
		"candidate_id": selected_candidate.candidate_id if selected_candidate != null else "",
		"apk_id": selected_candidate.apk_id if selected_candidate != null else "",
		"tendencies": tendencies,
		"variant_placeholder": variant_result
	}

static func _calculate_raw_axes(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData
) -> Dictionary:
	var result := {}
	for axis: String in AXES:
		result[axis] = 0
	for question: CompatibilityQuestionData in assessment.questions:
		if question == null:
			continue
		var answer := question.get_answer(str(session.final_answer_by_question.get(question.question_id, "")))
		if answer == null:
			continue
		for axis: String in AXES:
			result[axis] = int(result.get(axis, 0)) + int(answer.axis_weights.get(axis, 0))
	return result

static func _normalize_axes(raw_axes: Dictionary) -> Dictionary:
	var result := {}
	for axis: String in AXES:
		result[axis] = roundi(float(raw_axes.get(axis, 0)) / 18.0 * 100.0)
	return result

static func _calculate_confidence(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData,
	rush_state: Dictionary
) -> Dictionary:
	var result := {}
	var dominant_position := int(rush_state.get("dominant_position", -1))
	var rush_detected := bool(rush_state.get("rush_detected", false))
	for axis: String in AXES:
		var confidence := 1.0
		var dominant_hits_on_axis := 0
		for question: CompatibilityQuestionData in assessment.questions:
			if question == null or not question.measured_axes.has(axis):
				continue
			var qid := question.question_id
			var changes := int(session.answer_change_count_by_question.get(qid, 0))
			if changes > 0:
				confidence -= 0.03
				var first := question.get_answer(str(session.first_answer_by_question.get(qid, "")))
				var final := question.get_answer(str(session.final_answer_by_question.get(qid, "")))
				if first != null and final != null:
					var first_weight := int(first.axis_weights.get(axis, 0))
					var final_weight := int(final.axis_weights.get(axis, 0))
					if first_weight * final_weight < 0 and abs(first_weight - final_weight) >= 3:
						confidence -= 0.07
			if dominant_position >= 0 and int(session.selected_visual_position_by_question.get(qid, -1)) == dominant_position:
				dominant_hits_on_axis += 1
		if rush_detected:
			confidence -= 0.15 * (float(dominant_hits_on_axis) / 9.0)
		result[axis] = clampf(confidence, 0.65, 1.0)
	return result

static func _calculate_rush_state(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData
) -> Dictionary:
	var position_counts := [0, 0, 0, 0]
	for question: CompatibilityQuestionData in assessment.questions:
		if question == null:
			continue
		var position := int(session.selected_visual_position_by_question.get(question.question_id, -1))
		if position >= 0 and position < 4:
			position_counts[position] += 1
	var dominant_position := 0
	for index in range(1, position_counts.size()):
		if position_counts[index] > position_counts[dominant_position]:
			dominant_position = index
	var total_changes := 0
	for value: Variant in session.answer_change_count_by_question.values():
		total_changes += int(value)
	var revisits := session.revisited_questions.size()
	var dominant_count := int(position_counts[dominant_position])
	return {
		"dominant_position": dominant_position,
		"dominant_count": dominant_count,
		"rush_detected": dominant_count >= 13 and total_changes <= 1 and revisits == 0
	}

static func _calculate_candidate_scores(
	assessment: CompatibilityAssessmentData,
	axis_values: Dictionary,
	confidence: Dictionary
) -> Dictionary:
	var scores := {}
	for candidate: CompatibilityCandidateData in assessment.candidates:
		if candidate == null:
			continue
		var numerator := 0.0
		var denominator := 0.0
		for axis: String in AXES:
			var importance := float(candidate.axis_importance.get(axis, 0))
			var axis_confidence := float(confidence.get(axis, 1.0))
			if importance <= 0.0:
				continue
			numerator += absf(float(axis_values.get(axis, 0)) - float(candidate.axis_targets.get(axis, 0))) * importance * axis_confidence
			denominator += importance * axis_confidence
		var weighted_difference := numerator / denominator if denominator > 0.0 else 200.0
		scores[candidate.candidate_id] = 100.0 - (weighted_difference / 2.0)
	return scores

static func _highest_candidate(
	assessment: CompatibilityAssessmentData,
	scores: Dictionary
) -> CompatibilityCandidateData:
	var selected: CompatibilityCandidateData = null
	var selected_score := -INF
	for candidate: CompatibilityCandidateData in assessment.candidates:
		if candidate == null:
			continue
		var score := float(scores.get(candidate.candidate_id, -INF))
		if score > selected_score:
			selected = candidate
			selected_score = score
	return selected

static func _calculate_tendencies(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData
) -> Dictionary:
	var raw := {"valour": 0.0, "logic": 0.0, "sync": 0.0, "self": 0.0}
	var plus_two_events := {"valour": 0, "logic": 0, "sync": 0, "self": 0}
	var contributing_questions := {
		"valour": {}, "logic": {}, "sync": {}, "self": {}
	}
	for question: CompatibilityQuestionData in assessment.questions:
		if question == null:
			continue
		var answer := question.get_answer(str(session.final_answer_by_question.get(question.question_id, "")))
		if answer == null:
			continue
		for tendency: String in TENDENCIES:
			var amount := float(answer.tendency_weights.get(tendency, 0.0))
			raw[tendency] = float(raw[tendency]) + amount
			if amount > 0.0:
				(contributing_questions[tendency] as Dictionary)[question.question_id] = true
			if is_equal_approx(amount, 2.0):
				plus_two_events[tendency] = int(plus_two_events[tendency]) + 1

	var corrected := {}
	var corrected_total := 0.0
	for tendency: String in TENDENCIES:
		var exposure := maxf(0.0001, float(assessment.exposure_correction.get(tendency, 1.0)))
		var value := float(raw[tendency]) / exposure
		corrected[tendency] = value
		corrected_total += value
	if corrected_total <= 0.0:
		return {"valour": 4, "logic": 4, "sync": 4, "self": 3}

	var floors := {}
	var remainders := {}
	var allocated := 0
	for tendency: String in TENDENCIES:
		var exact := float(corrected[tendency]) / corrected_total * 15.0
		var floor_value := int(floor(exact))
		floors[tendency] = floor_value
		remainders[tendency] = exact - float(floor_value)
		allocated += floor_value

	var remaining := 15 - allocated
	var order: Array[String] = Array(TENDENCIES)
	order.sort_custom(func(left: String, right: String) -> bool:
		var left_rem := float(remainders[left])
		var right_rem := float(remainders[right])
		if not is_equal_approx(left_rem, right_rem):
			return left_rem > right_rem
		var left_twos := int(plus_two_events[left])
		var right_twos := int(plus_two_events[right])
		if left_twos != right_twos:
			return left_twos > right_twos
		var left_questions := (contributing_questions[left] as Dictionary).size()
		var right_questions := (contributing_questions[right] as Dictionary).size()
		if left_questions != right_questions:
			return left_questions > right_questions
		return TENDENCIES.find(left) < TENDENCIES.find(right)
	)
	for index in range(remaining):
		var tendency := order[index % order.size()]
		floors[tendency] = int(floors[tendency]) + 1
	return floors

static func _calculate_variant_placeholder(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData,
	writing_style_id: String,
	kaomoji_preference_id: String,
	avatar_variant_hint: String,
	rush_detected: bool
) -> Dictionary:
	var quiz_affinity := {}
	for variant: String in VARIANTS:
		quiz_affinity[variant] = 0
	for question: CompatibilityQuestionData in assessment.questions:
		if question == null:
			continue
		var answer := question.get_answer(str(session.final_answer_by_question.get(question.question_id, "")))
		if answer != null and VARIANTS.has(answer.variant_key):
			quiz_affinity[answer.variant_key] = int(quiz_affinity[answer.variant_key]) + 1

	var registration_bonus := {}
	for variant: String in VARIANTS:
		var bonus := 0
		var writing_variants: Variant = assessment.writing_style_variant_affinity.get(writing_style_id.strip_edges().to_lower(), PackedStringArray())
		if _variant_list_has(writing_variants, variant):
			bonus += 1
		var kaomoji_variants: Variant = assessment.kaomoji_variant_affinity.get(kaomoji_preference_id.strip_edges().to_lower(), PackedStringArray())
		if _variant_list_has(kaomoji_variants, variant):
			bonus += 1
		if avatar_variant_hint.strip_edges().to_upper() == variant:
			bonus += 1
		registration_bonus[variant] = mini(bonus, assessment.max_registration_variant_bonus)

	var eligible: Array[Dictionary] = []
	if not rush_detected:
		for variant: String in VARIANTS:
			var quiz := int(quiz_affinity[variant])
			var total := quiz + int(registration_bonus[variant])
			if total >= assessment.variant_threshold and _passes_variant_behavior(assessment, session, variant):
				eligible.append({"variant": variant, "quiz": quiz, "total": total})
	eligible.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left["quiz"]) != int(right["quiz"]):
			return int(left["quiz"]) > int(right["quiz"])
		return int(left["total"]) > int(right["total"])
	)
	var selected := ""
	if eligible.size() == 1:
		selected = str(eligible[0]["variant"])
	elif eligible.size() > 1:
		var first := eligible[0]
		var second := eligible[1]
		if int(first["quiz"]) != int(second["quiz"]) or int(first["total"]) != int(second["total"]):
			selected = str(first["variant"])
	return {
		"selected_variant_id": selected,
		"quiz_affinity": quiz_affinity,
		"registration_bonus": registration_bonus,
		"rush_blocked": rush_detected,
		"integration_ready": false
	}

static func _passes_variant_behavior(
	assessment: CompatibilityAssessmentData,
	session: CompatibilitySessionData,
	variant: String
) -> bool:
	var raw_keys: Variant = assessment.variant_behavior_keys.get(variant, [])
	if raw_keys is not Array:
		return false
	for raw_key: Variant in raw_keys:
		if _matches_behavior_key(session, str(raw_key)):
			return true
	return false

static func _matches_behavior_key(session: CompatibilitySessionData, key: String) -> bool:
	var parts := key.split(":", false)
	if parts.size() < 3:
		return false
	var kind := parts[0]
	var qid := parts[1]
	match kind:
		"UNCHANGED_FINAL":
			var expected := parts[2]
			return str(session.final_answer_by_question.get(qid, "")) == expected and int(session.answer_change_count_by_question.get(qid, 0)) == 0
		"REVISITED_KEPT":
			var expected := parts[2]
			return bool(session.revisited_and_kept.get(qid, false)) and str(session.final_answer_by_question.get(qid, "")) == expected
		"CHANGED_FROM_TO":
			if parts.size() < 4:
				return false
			return str(session.first_answer_by_question.get(qid, "")) == parts[2] and str(session.final_answer_by_question.get(qid, "")) == parts[3]
	return false

static func _variant_list_has(value: Variant, variant: String) -> bool:
	if value is PackedStringArray:
		return (value as PackedStringArray).has(variant)
	if value is Array:
		return (value as Array).has(variant)
	return false
