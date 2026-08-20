extends Resource
class_name APKPersonalityData


@export var personality_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var first_impression_profile: APKFirstImpressionProfileData


func get_first_impression_line(trait_id: String) -> String:
	if first_impression_profile == null:
		return ""
	return first_impression_profile.get_line(trait_id)


func get_first_impression_reaction(trait_id: String) -> int:
	if first_impression_profile == null:
		return APKFirstImpressionProfileData.Reaction.NEUTRAL
	return first_impression_profile.get_reaction(trait_id)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if personality_id.strip_edges().is_empty():
		errors.append("APKPersonalityData has an empty personality_id.")

	if display_name.strip_edges().is_empty():
		errors.append("APK personality '%s' has no display name." % personality_id)

	if first_impression_profile != null:
		errors.append_array(first_impression_profile.validate_data())

	return errors
