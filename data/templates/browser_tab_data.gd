extends Resource
class_name BrowserTabData

@export var current_url: String = ""
@export var page_title: String = "Nova Aba"

var history: Array[String] = []
var history_index: int = -1
var custom_site_state: Dictionary = {}


func navigate_to(url: String, title: String = "") -> void:
	if url.is_empty():
		return

	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)

	history.append(url)
	history_index = history.size() - 1

	current_url = url

	if not title.is_empty():
		page_title = title
	else:
		page_title = url


func can_go_back() -> bool:
	return history_index > 0


func go_back() -> String:
	if not can_go_back():
		return current_url

	history_index -= 1
	current_url = history[history_index]
	return current_url


func can_go_forward() -> bool:
	return history_index < history.size() - 1


func go_forward() -> String:
	if not can_go_forward():
		return current_url

	history_index += 1
	current_url = history[history_index]
	return current_url


func set_page_title(title: String) -> void:
	if title.is_empty():
		page_title = current_url
	else:
		page_title = title


func clear_custom_site_state() -> void:
	custom_site_state = {}