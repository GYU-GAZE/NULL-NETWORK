extends Node

var story_flags: Dictionary = {}
var read_threads: Dictionary = {}
var watched_threads: Dictionary = {}
var thread_visibility_signatures: Dictionary = {}


func set_flag(flag_name: String, value: bool) -> void:
	if flag_name.is_empty():
		return

	story_flags[flag_name] = value


func get_flag(flag_name: String, default_value: bool = false) -> bool:
	return story_flags.get(flag_name, default_value)


func toggle_flag(flag_name: String) -> bool:
	if flag_name.is_empty():
		return false

	var new_value: bool = not get_flag(flag_name, false)
	story_flags[flag_name] = new_value
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
