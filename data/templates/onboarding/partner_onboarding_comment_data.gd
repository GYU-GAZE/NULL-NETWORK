@tool
extends Resource
class_name PartnerOnboardingCommentData


@export var apk_id: String = ""
@export_multiline var default_line: String = ""
@export var tendency_lines: Dictionary = {}


func get_line(dominant_tendency: String) -> String:
	var tendency_id := dominant_tendency.strip_edges().to_lower()
	var selected := str(tendency_lines.get(tendency_id, default_line)).strip_edges()
	if selected.is_empty():
		selected = default_line.strip_edges()
	return selected.replace("{TENDENCY}", tendency_id.to_upper())


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if apk_id.strip_edges().is_empty():
		errors.append("Partner onboarding comment requires apk_id.")
	if default_line.strip_edges().is_empty():
		errors.append("Partner onboarding comment '%s' requires default_line." % apk_id)
	return errors
