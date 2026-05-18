extends Node

var story_flags: Dictionary = {}
var read_threads: Dictionary = {}

func set_flag(flag_name: String, value: bool) -> void:
	if flag_name.is_empty():
		return
	
	story_flags[flag_name] = value

func get_flag(flag_name: String, default_value: bool = false) -> bool:
	return story_flags.get(flag_name, default_value)

func toggle_flag(flag_name: String) -> bool:
	if flag_name.is_empty():
		return false
	
	var new_value := not get_flag(flag_name, false)
	story_flags[flag_name] = new_value
	return new_value

func mark_thread_as_read(thread_id: String) -> void:
	if thread_id.is_empty():
		return

	read_threads[thread_id] = true


func has_read_thread(thread_id: String) -> bool:
	if thread_id.is_empty():
		return false

	return read_threads.get(thread_id, false)