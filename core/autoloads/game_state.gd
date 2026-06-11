extends Node

signal flag_changed(flag_name: String, value: bool)
signal number_changed(var_name: String, value: int)
signal game_state_changed

var story_flags: Dictionary = {}
var read_threads: Dictionary = {}
var watched_threads: Dictionary = {}
var thread_visibility_signatures: Dictionary = {}
var numeric_vars: Dictionary = {}

var changelog_read_signature: String = ""
var notified_changelog_entries: Dictionary = {}


func set_flag(flag_name: String, value: bool) -> void:
	if flag_name.is_empty():
		return

	story_flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	game_state_changed.emit()


func get_flag(flag_name: String, default_value: bool = false) -> bool:
	return story_flags.get(flag_name, default_value)


func toggle_flag(flag_name: String) -> bool:
	if flag_name.is_empty():
		return false

	var new_value: bool = not get_flag(flag_name, false)
	story_flags[flag_name] = new_value
	flag_changed.emit(flag_name, new_value)
	game_state_changed.emit()
	return new_value


func mark_thread_as_read(thread_id: String, visibility_signature: String = "") -> void:
	if thread_id.is_empty():
		return

	read_threads[thread_id] = true

	if not visibility_signature.is_empty():
		thread_visibility_signatures[thread_id] = visibility_signature


func mark_thread_as_unread(thread_id: String) -> void:
	if thread_id.is_empty():
		return

	read_threads.erase(thread_id)


func has_read_thread(thread_id: String) -> bool:
	if thread_id.is_empty():
		return false

	return read_threads.get(thread_id, false)


func update_thread_visibility_signature(thread_id: String, visibility_signature: String) -> void:
	if thread_id.is_empty():
		return

	thread_visibility_signatures[thread_id] = visibility_signature


func get_thread_visibility_signature(thread_id: String) -> String:
	if thread_id.is_empty():
		return ""

	return str(thread_visibility_signatures.get(thread_id, ""))


func sync_thread_read_state(thread_id: String, visibility_signature: String) -> void:
	if thread_id.is_empty():
		return

	if visibility_signature.is_empty():
		return

	if not has_read_thread(thread_id):
		return

	var previous_signature: String = get_thread_visibility_signature(thread_id)

	if previous_signature.is_empty():
		thread_visibility_signatures[thread_id] = visibility_signature
		return

	if previous_signature != visibility_signature:
		mark_thread_as_unread(thread_id)


func watch_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return

	watched_threads[thread_id] = true


func unwatch_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return

	watched_threads.erase(thread_id)


func toggle_thread_watch(thread_id: String) -> bool:
	if thread_id.is_empty():
		return false

	if is_thread_watched(thread_id):
		unwatch_thread(thread_id)
		return false

	watch_thread(thread_id)
	return true


func is_thread_watched(thread_id: String) -> bool:
	if thread_id.is_empty():
		return false

	return watched_threads.get(thread_id, false)


func set_number(var_name: String, value: int) -> void:
	if var_name.is_empty():
		return

	numeric_vars[var_name] = value
	number_changed.emit(var_name, value)
	game_state_changed.emit()


func add_number(var_name: String, amount: int) -> int:
	if var_name.is_empty():
		return 0

	var new_value: int = get_number(var_name) + amount
	numeric_vars[var_name] = new_value
	number_changed.emit(var_name, new_value)
	game_state_changed.emit()
	return new_value


func get_number(var_name: String, default_value: int = 0) -> int:
	if var_name.is_empty():
		return default_value

	return int(numeric_vars.get(var_name, default_value))


func mark_changelog_as_read(visibility_signature: String) -> void:
	changelog_read_signature = visibility_signature


func has_read_changelog_signature(visibility_signature: String) -> bool:
	if visibility_signature.is_empty():
		return true

	return changelog_read_signature == visibility_signature


func mark_changelog_entry_as_notified(notification_key: String) -> void:
	if notification_key.is_empty():
		return

	notified_changelog_entries[notification_key] = true


func was_changelog_entry_notified(notification_key: String) -> bool:
	if notification_key.is_empty():
		return true

	return notified_changelog_entries.get(notification_key, false)
