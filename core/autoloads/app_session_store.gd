extends Node

signal app_state_saved(app_id: String)
signal app_state_cleared(app_id: String)
signal all_app_states_cleared

const SAVE_DATA_VERSION: int = 1

var _app_states: Dictionary = {}


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_APP_SESSIONS)


func has_app_state(app_id: String) -> bool:
	var clean_id: String = _normalize_app_id(app_id)

	if clean_id.is_empty():
		return false

	return _app_states.has(clean_id)


func save_app_state(app_id: String, state: Dictionary) -> void:
	var clean_id: String = _normalize_app_id(app_id)

	if clean_id.is_empty():
		push_warning("AppSessionStore: cannot save state for an empty app_id.")
		return

	_app_states[clean_id] = state.duplicate(true)
	app_state_saved.emit(clean_id)


func get_app_state(app_id: String) -> Dictionary:
	var clean_id: String = _normalize_app_id(app_id)

	if clean_id.is_empty() or not _app_states.has(clean_id):
		return {}

	var stored_state: Variant = _app_states[clean_id]

	if not stored_state is Dictionary:
		return {}

	return (stored_state as Dictionary).duplicate(true)


func clear_app_state(app_id: String) -> void:
	var clean_id: String = _normalize_app_id(app_id)

	if clean_id.is_empty() or not _app_states.has(clean_id):
		return

	_app_states.erase(clean_id)
	app_state_cleared.emit(clean_id)


func clear_all_app_states() -> void:
	if _app_states.is_empty():
		return

	_app_states.clear()
	all_app_states_cleared.emit()


func export_save_data() -> Dictionary:
	return {
		"version": SAVE_DATA_VERSION,
		"app_states": _app_states.duplicate(true)
	}


func import_save_data(save_data: Dictionary) -> void:
	_app_states.clear()

	var stored_states: Variant = save_data.get("app_states", {})

	if not stored_states is Dictionary:
		push_warning("AppSessionStore: imported app_states is not a Dictionary.")
		return

	var state_dictionary := stored_states as Dictionary

	for raw_app_id: Variant in state_dictionary.keys():
		var clean_id: String = _normalize_app_id(str(raw_app_id))
		var raw_state: Variant = state_dictionary[raw_app_id]

		if clean_id.is_empty() or raw_state is not Dictionary:
			continue

		_app_states[clean_id] = (raw_state as Dictionary).duplicate(true)


func reset_save_data() -> void:
	clear_all_app_states()


func _normalize_app_id(app_id: String) -> String:
	return app_id.strip_edges()
