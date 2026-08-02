extends Resource
class_name WorldStateData


var story_flags: Dictionary = {}
var numeric_vars: Dictionary = {}
var location_infestation: Dictionary = {}
var persistent_objects: Dictionary = {}
var completed_incident_ids: PackedStringArray = PackedStringArray()


func reset() -> void:
	story_flags.clear()
	numeric_vars.clear()
	location_infestation.clear()
	persistent_objects.clear()
	completed_incident_ids.clear()


func set_flag(flag_name: String, value: bool) -> void:
	var clean_name: String = flag_name.strip_edges()

	if not clean_name.is_empty():
		story_flags[clean_name] = value


func get_flag(flag_name: String, default_value: bool = false) -> bool:
	return bool(story_flags.get(flag_name.strip_edges(), default_value))


func set_number(var_name: String, value: int) -> void:
	var clean_name: String = var_name.strip_edges()

	if not clean_name.is_empty():
		numeric_vars[clean_name] = value


func get_number(var_name: String, default_value: int = 0) -> int:
	return int(numeric_vars.get(var_name.strip_edges(), default_value))


func set_infestation(location_id: String, value: int) -> void:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return

	if value <= 0:
		location_infestation.erase(clean_id)
		return

	location_infestation[clean_id] = value


func get_infestation(location_id: String) -> int:
	return int(location_infestation.get(location_id.strip_edges(), 0))


func mark_incident_completed(incident_id: String) -> void:
	var clean_id: String = incident_id.strip_edges()

	if not clean_id.is_empty() and not completed_incident_ids.has(clean_id):
		completed_incident_ids.append(clean_id)


func to_save_data() -> Dictionary:
	return {
		"story_flags": story_flags.duplicate(true),
		"numeric_vars": numeric_vars.duplicate(true),
		"location_infestation": location_infestation.duplicate(true),
		"persistent_objects": persistent_objects.duplicate(true),
		"completed_incident_ids": _string_array_to_array(
			completed_incident_ids
		)
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	story_flags = _read_dictionary(data.get("story_flags", {}))
	numeric_vars = _read_dictionary(data.get("numeric_vars", {}))
	location_infestation = _read_dictionary(
		data.get("location_infestation", {})
	)
	persistent_objects = _read_dictionary(
		data.get("persistent_objects", {})
	)
	completed_incident_ids = _read_id_array(
		data.get("completed_incident_ids", [])
	)


func _read_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)

	return {}


func _read_id_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty() and not result.has(clean_id):
			result.append(clean_id)

	return result


func _string_array_to_array(value: PackedStringArray) -> Array[String]:
	var result: Array[String] = []

	for entry: String in value:
		result.append(entry)

	return result
