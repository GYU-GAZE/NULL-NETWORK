extends Resource
class_name BrowserTabData

@export var current_url: String = ""
@export var page_title: String = "Nova Aba"
@export var favicon: Texture2D

var history: Array[String] = []
var history_index: int = -1
var site_state: Dictionary = {}


func navigate_to(url: String, title: String = "", icon: Texture2D = null) -> void:
	if url.is_empty():
		return

	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)

	history.append(url)
	history_index = history.size() - 1
	current_url = url

	set_page_title(title)
	set_favicon(icon)


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
	page_title = current_url if title.is_empty() else title


func set_favicon(icon: Texture2D) -> void:
	favicon = icon


func clear_site_state() -> void:
	site_state = {}
