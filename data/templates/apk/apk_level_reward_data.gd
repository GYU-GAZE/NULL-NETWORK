extends Resource
class_name APKLevelRewardData


@export_range(2, 100, 1) var required_level: int = 2
@export var active_module_ids: PackedStringArray = PackedStringArray()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := PackedStringArray()

	for raw_id: String in active_module_ids:
		var clean_id: String = raw_id.strip_edges()

		if clean_id.is_empty():
			errors.append("Level %d reward contains an empty Module ID." % required_level)
		elif seen.has(clean_id):
			errors.append("Level %d reward repeats Module '%s'." % [required_level, clean_id])
		else:
			seen.append(clean_id)

	return errors
