extends Resource
class_name DialogueSpeakerData


@export_category("Identity")
@export var speaker_id: String = ""
@export var display_name: String = ""


func get_display_id() -> String:
	return speaker_id.strip_edges()


func get_display_name() -> String:
	var clean_name: String = display_name.strip_edges()

	if not clean_name.is_empty():
		return clean_name

	return get_display_id()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("speaker_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append("display_name cannot be empty.")

	return errors
