extends Resource
class_name CompatibilityAnswerData

@export var answer_id: String = "A"
@export_multiline var text: String = ""
@export var axis_weights: Dictionary = {}
@export var tendency_weights: Dictionary = {}
@export var variant_key: String = ""

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if answer_id.strip_edges().is_empty():
		errors.append("Compatibility answer requires an id.")
	if text.strip_edges().is_empty():
		errors.append("Compatibility answer '%s' requires text." % answer_id)
	return errors
