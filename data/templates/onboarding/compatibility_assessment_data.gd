extends Resource
class_name CompatibilityAssessmentData

@export var questions: Array[CompatibilityQuestionData] = []
@export var candidates: Array[CompatibilityCandidateData] = []
@export var manual_candidate_ids: PackedStringArray = PackedStringArray([
	"REVQUIRE", "VOCALYTE", "WIZIP", "PABUBU", "TROJAW"
])
@export var exposure_correction: Dictionary = {
	"valour": 6.0,
	"logic": 12.25,
	"sync": 10.5,
	"self": 5.0
}
@export var writing_style_variant_affinity: Dictionary = {
	"normal": PackedStringArray(["CONDUCTIVE", "DEPLETIVE"]),
	"cute": PackedStringArray(["COMBUSTIVE", "DESTRUCTIVE"]),
	"lazy": PackedStringArray(["CORROSIVE", "DECEPTIVE"]),
	"formal": PackedStringArray(["CRYOSIVE", "DEFENSIVE"])
}
@export var kaomoji_variant_affinity: Dictionary = {
	"frequent": PackedStringArray(["COMBUSTIVE", "CONDUCTIVE", "DESTRUCTIVE"]),
	"occasional": PackedStringArray(["CORROSIVE", "DECEPTIVE", "DEPLETIVE"]),
	"never": PackedStringArray(["CRYOSIVE", "DEFENSIVE"])
}
@export var variant_behavior_keys: Dictionary = {
	"COMBUSTIVE": ["UNCHANGED_FINAL:Q14:B", "CHANGED_FROM_TO:Q06:B:A"],
	"CRYOSIVE": ["REVISITED_KEPT:Q15:C", "CHANGED_FROM_TO:Q14:B:C"],
	"CONDUCTIVE": ["REVISITED_KEPT:Q09:B", "CHANGED_FROM_TO:Q10:D:A"],
	"CORROSIVE": ["REVISITED_KEPT:Q15:D", "CHANGED_FROM_TO:Q07:B:C"],
	"DEFENSIVE": ["REVISITED_KEPT:Q11:A", "CHANGED_FROM_TO:Q04:C:A"],
	"DESTRUCTIVE": ["UNCHANGED_FINAL:Q15:A", "CHANGED_FROM_TO:Q16:A:D"],
	"DEPLETIVE": ["REVISITED_KEPT:Q17:B", "CHANGED_FROM_TO:Q09:A:D"],
	"DECEPTIVE": ["REVISITED_KEPT:Q12:C", "CHANGED_FROM_TO:Q17:A:D"]
}
@export_range(1, 16, 1) var variant_threshold: int = 8
@export_range(0, 4, 1) var max_registration_variant_bonus: int = 2

func get_question(question_id: String) -> CompatibilityQuestionData:
	var clean_id := question_id.strip_edges().to_upper()
	for question: CompatibilityQuestionData in questions:
		if question != null and question.question_id.strip_edges().to_upper() == clean_id:
			return question
	return null

func get_candidate(candidate_id: String) -> CompatibilityCandidateData:
	var clean_id := candidate_id.strip_edges().to_upper()
	for candidate: CompatibilityCandidateData in candidates:
		if candidate != null and candidate.candidate_id.strip_edges().to_upper() == clean_id:
			return candidate
	return null

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if questions.size() != 18:
		errors.append("Compatibility Assessment must contain exactly 18 questions.")
	for question: CompatibilityQuestionData in questions:
		if question == null:
			errors.append("Compatibility Assessment contains a null question.")
		else:
			errors.append_array(question.validate_data())
	if candidates.is_empty():
		errors.append("Compatibility Assessment requires at least one candidate.")
	for candidate: CompatibilityCandidateData in candidates:
		if candidate == null:
			errors.append("Compatibility Assessment contains a null candidate.")
		else:
			errors.append_array(candidate.validate_data())
	for manual_id: String in manual_candidate_ids:
		var candidate := get_candidate(manual_id)
		if candidate == null:
			errors.append("Manual candidate '%s' is not part of the Assessment pool." % manual_id)
		elif candidate.candidate_class != CompatibilityCandidateData.CandidateClass.STANDARD:
			errors.append("Manual candidate '%s' must be STANDARD." % manual_id)
	return errors
