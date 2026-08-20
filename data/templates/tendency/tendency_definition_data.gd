@tool
extends Resource
class_name TendencyDefinitionData


@export var tendency_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var accent_color: Color = Color(0.2, 0.76, 1.0, 1.0)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if tendency_id.strip_edges().is_empty():
		errors.append("Tendency definition requires tendency_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Tendency '%s' requires display_name." % tendency_id)
	if description.strip_edges().is_empty():
		errors.append("Tendency '%s' requires description." % tendency_id)
	return errors
