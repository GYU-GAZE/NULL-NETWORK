extends Resource
class_name CompatibilityQuestionData

enum Category { EVERYDAY, CRITICAL, MORAL }

@export var question_id: String = "Q01"
@export var category: Category = Category.EVERYDAY
@export_multiline var prompt: String = ""
@export var measured_axes: PackedStringArray = PackedStringArray()
@export var answers: Array[CompatibilityAnswerData] = []
@export var shuffle_answers: bool = true

func get_answer(answer_id: String) -> CompatibilityAnswerData:
	var clean_id := answer_id.strip_edges().to_upper()
	for answer_value in answers:
		var answer := answer_value as CompatibilityAnswerData
		if answer != null and answer.answer_id.strip_edges().to_upper() == clean_id:
			return answer
	return null

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if question_id.strip_edges().is_empty():
		errors.append("Compatibility question requires an id.")
	if prompt.strip_edges().is_empty():
		errors.append("Compatibility question '%s' requires a prompt." % question_id)
	if answers.size() != 4:
		errors.append("Compatibility question '%s' must expose exactly four answers." % question_id)
	for answer_value in answers:
		var answer := answer_value as CompatibilityAnswerData
		if answer == null:
			errors.append("Compatibility question '%s' contains a null answer." % question_id)
		else:
			errors.append_array(answer.validate_data())
	return errors
