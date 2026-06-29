extends Node

signal flag_changed(flag_name: String, value: bool)
signal number_changed(var_name: String, value: int)
signal game_state_changed
signal browser_history_changed

var story_flags: Dictionary = {}
var read_threads: Dictionary = {}
var watched_threads: Dictionary = {}
var thread_visibility_signatures: Dictionary = {}
var numeric_vars: Dictionary = {}

var browser_site_history: Array[Dictionary] = []
var browser_history_visit_counter: int = 0
var pinned_browser_sites: Array[Dictionary] = []


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


func register_browser_visit(url: String, title: String, favicon: Texture2D = null) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	browser_history_visit_counter += 1

	var existing_index: int = _find_browser_history_index(clean_url)

	var entry: Dictionary = {
		"url": clean_url,
		"title": title if not title.strip_edges().is_empty() else clean_url,
		"favicon": favicon,
		"last_visited_order": browser_history_visit_counter
	}

	if existing_index >= 0:
		browser_site_history[existing_index] = entry
	else:
		browser_site_history.append(entry)

	browser_site_history.sort_custom(_sort_browser_history_entries)
	browser_history_changed.emit()


func get_recent_browser_sites(limit: int = 12) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count: int = min(limit, browser_site_history.size())

	for i in range(count):
		result.append(browser_site_history[i])

	return result


func clear_browser_history() -> void:
	browser_site_history.clear()
	browser_history_changed.emit()


func _find_browser_history_index(url: String) -> int:
	for i in range(browser_site_history.size()):
		var entry: Dictionary = browser_site_history[i]

		if str(entry.get("url", "")) == url:
			return i

	return -1


func _sort_browser_history_entries(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("last_visited_order", 0)) > int(b.get("last_visited_order", 0))

func pin_browser_site(url: String, title: String, favicon: Texture2D = null) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	var existing_index: int = _find_pinned_browser_site_index(clean_url)

	var entry: Dictionary = {
		"url": clean_url,
		"title": title if not title.strip_edges().is_empty() else clean_url,
		"favicon": favicon
	}

	if existing_index >= 0:
		pinned_browser_sites[existing_index] = entry
	else:
		pinned_browser_sites.append(entry)

	game_state_changed.emit()


func unpin_browser_site(url: String) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	var existing_index: int = _find_pinned_browser_site_index(clean_url)

	if existing_index < 0:
		return

	pinned_browser_sites.remove_at(existing_index)
	game_state_changed.emit()


func toggle_browser_site_pin(url: String, title: String, favicon: Texture2D = null) -> bool:
	if is_browser_site_pinned(url):
		unpin_browser_site(url)
		return false

	pin_browser_site(url, title, favicon)
	return true


func is_browser_site_pinned(url: String) -> bool:
	return _find_pinned_browser_site_index(url.strip_edges()) >= 0


func get_pinned_browser_sites() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in pinned_browser_sites:
		result.append(entry)

	return result


func _find_pinned_browser_site_index(url: String) -> int:
	for i in range(pinned_browser_sites.size()):
		var entry: Dictionary = pinned_browser_sites[i]

		if str(entry.get("url", "")) == url:
			return i

	return -1
