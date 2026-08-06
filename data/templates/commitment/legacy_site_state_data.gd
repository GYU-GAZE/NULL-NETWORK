extends Resource
class_name LegacySiteStateData


const STATE_VERSION: int = 1
const OBJECT_KIND: String = "legacy_site"

var legacy_site_id: String = ""
var operator_id: String = ""
var operator_display_name: String = ""
var location_id: String = ""
var game_day: int = 1
var action_index: int = 0
var encounter_id: String = ""
var recovered: bool = false
var recoverable_data: Dictionary = {}
var metadata: Dictionary = {}


func get_display_id() -> String:
	return legacy_site_id.strip_edges()


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("LegacySiteStateData requires a legacy_site_id.")

	if operator_id.strip_edges().is_empty():
		errors.append("Legacy Site requires an archived operator_id.")

	if location_id.strip_edges().is_empty():
		errors.append("Legacy Site requires a location_id.")

	if game_day < 1:
		errors.append("Legacy Site game_day must be at least 1.")

	if action_index < 0:
		errors.append("Legacy Site action_index cannot be negative.")

	return errors


func to_save_data() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"object_kind": OBJECT_KIND,
		"legacy_site_id": get_display_id(),
		"operator_id": operator_id.strip_edges(),
		"operator_display_name": operator_display_name.strip_edges(),
		"location_id": location_id.strip_edges(),
		"game_day": maxi(1, game_day),
		"action_index": maxi(0, action_index),
		"encounter_id": encounter_id.strip_edges(),
		"recovered": recovered,
		"recoverable_data": recoverable_data.duplicate(true),
		"metadata": metadata.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	legacy_site_id = str(data.get("legacy_site_id", "")).strip_edges()
	operator_id = str(data.get("operator_id", "")).strip_edges()
	operator_display_name = str(
		data.get("operator_display_name", "")
	).strip_edges()
	location_id = str(data.get("location_id", "")).strip_edges()
	game_day = maxi(1, int(data.get("game_day", 1)))
	action_index = maxi(0, int(data.get("action_index", 0)))
	encounter_id = str(data.get("encounter_id", "")).strip_edges()
	recovered = bool(data.get("recovered", false))
	recoverable_data = _read_dictionary(data.get("recoverable_data", {}))
	metadata = _read_dictionary(data.get("metadata", {}))


static func from_save_data(data: Dictionary) -> LegacySiteStateData:
	var state := LegacySiteStateData.new()
	state.load_save_data(data)
	return state


func _read_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}
