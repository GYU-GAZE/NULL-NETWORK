extends Resource
class_name APKPersonalityData


@export var personality_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if personality_id.strip_edges().is_empty():
		errors.append("APKPersonalityData has an empty personality_id.")

	if display_name.strip_edges().is_empty():
		errors.append("APK personality '%s' has no display name." % personality_id)

	return errors
