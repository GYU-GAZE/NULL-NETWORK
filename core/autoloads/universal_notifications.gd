extends Node

signal notification_requested(title: String, message: String)

var notification_history: Array[Dictionary] = []


func push(title: String, message: String) -> void:
	var clean_title: String = title.strip_edges()
	var clean_message: String = message.strip_edges()

	if clean_title.is_empty() and clean_message.is_empty():
		return

	var data: Dictionary = {
		"title": clean_title,
		"message": clean_message
	}

	notification_history.append(data)
	notification_requested.emit(clean_title, clean_message)


func push_simple(message: String) -> void:
	push("", message)


func clear_history() -> void:
	notification_history.clear()


func get_history() -> Array[Dictionary]:
	return notification_history.duplicate()
