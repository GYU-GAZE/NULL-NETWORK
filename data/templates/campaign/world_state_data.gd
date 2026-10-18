extends Resource
class_name WorldStateData


var story_flags: Dictionary = {}
var numeric_vars: Dictionary = {}
var location_infestation: Dictionary = {}
var persistent_objects: Dictionary = {}
var population_states: Dictionary = {}
var ecology_zones: Dictionary = {}
var ecology_route: Dictionary = {}
var completed_incident_ids: PackedStringArray = PackedStringArray()


func reset() -> void:
	story_flags.clear()
	numeric_vars.clear()
	location_infestation.clear()
	persistent_objects.clear()
	population_states.clear()
	ecology_zones.clear()
	ecology_route.clear()
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


func set_population_state(
	location_id: String,
	state: Dictionary
) -> bool:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return false

	population_states[clean_id] = state.duplicate(true)
	return true


func get_population_state(location_id: String) -> Dictionary:
	var clean_id: String = location_id.strip_edges()
	var value: Variant = population_states.get(clean_id, {})

	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func to_save_data() -> Dictionary:
	return {
		"story_flags": story_flags.duplicate(true),
		"numeric_vars": numeric_vars.duplicate(true),
		"location_infestation": location_infestation.duplicate(true),
		"persistent_objects": persistent_objects.duplicate(true),
		"population_states": population_states.duplicate(true),
		"ecology_zones": ecology_zones.duplicate(true),
		"ecology_route": ecology_route.duplicate(true),
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
	population_states = _read_dictionary(
		data.get("population_states", {})
	)
	ecology_zones = _read_dictionary(data.get("ecology_zones", {}))
	ecology_route = _read_dictionary(data.get("ecology_route", {}))
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


static func validate_ecology(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if data.get("ecology_zones", {}) is not Dictionary or data.get("ecology_route", {}) is not Dictionary:
		return PackedStringArray(["World ecology state must use dictionaries."])
	for id: Variant in data.get("ecology_zones", {}):
		var zone: Variant = data.ecology_zones[id]
		if zone is not Dictionary or int(zone.get("version", -1)) != 1 or zone.get("species", {}) is not Dictionary or zone.get("applied_effect_receipts", {}) is not Dictionary:
			errors.append("Invalid ecological zone state: " + str(id))
			continue
		var total := 0
		for species: Variant in zone.species.values():
			if species is not Dictionary:
				errors.append("Ecological species state must be a dictionary.")
				continue
			var current := int(species.get("population_current", -1))
			var resonance := int(species.get("purify_resonance", -1))
			if current < 0 or current > int(species.get("population_capacity", 2147483647)) or int(species.get("population_base", -1)) < 0 or resonance < 0 or resonance > 3:
				errors.append("Invalid ecological population/resonance.")
			total += current
		if total > int(zone.get("population_capacity", 2147483647)) or (bool(zone.get("collapsed", false)) and total != 0): errors.append("Ecological capacity/collapse invariant violated.")
	return errors
