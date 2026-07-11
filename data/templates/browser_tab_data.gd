extends Resource
class_name BrowserTabData

const DEFAULT_PAGE_TITLE: String = "Nova Aba"

@export var current_url: String = ""
@export var page_title: String = DEFAULT_PAGE_TITLE
@export var favicon: Texture2D

var history: Array[String] = []
var history_index: int = -1
var site_state: Dictionary = {}


func navigate_to(
	url: String,
	title: String = "",
	icon: Texture2D = null
) -> void:
	var clean_url: String = url.strip_edges()

	if clean_url.is_empty():
		return

	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)

	history.append(clean_url)
	history_index = history.size() - 1
	current_url = clean_url

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
	return history_index >= 0 and history_index < history.size() - 1


func go_forward() -> String:
	if not can_go_forward():
		return current_url

	history_index += 1
	current_url = history[history_index]

	return current_url


func set_page_title(title: String) -> void:
	var clean_title: String = title.strip_edges()

	if clean_title.is_empty():
		page_title = current_url if not current_url.is_empty() else DEFAULT_PAGE_TITLE
		return

	page_title = clean_title


func set_favicon(icon: Texture2D) -> void:
	favicon = icon


func clear_site_state() -> void:
	site_state = {}


func to_session_state() -> Dictionary:
	var favicon_path: String = ""

	if favicon != null:
		favicon_path = favicon.resource_path

	return {
		"current_url": current_url,
		"page_title": page_title,
		"favicon_path": favicon_path,
		"history": history.duplicate(),
		"history_index": history_index,
		"site_state": site_state.duplicate(true)
	}


static func from_session_state(state: Dictionary) -> BrowserTabData:
	var tab := BrowserTabData.new()

	tab.current_url = str(state.get("current_url", "")).strip_edges()
	tab.page_title = str(
		state.get("page_title", DEFAULT_PAGE_TITLE)
	).strip_edges()

	if tab.page_title.is_empty():
		tab.page_title = (
			tab.current_url
			if not tab.current_url.is_empty()
			else DEFAULT_PAGE_TITLE
		)

	var raw_history: Variant = state.get("history", [])

	if raw_history is Array:
		for raw_url in raw_history:
			var clean_url: String = str(raw_url).strip_edges()

			if not clean_url.is_empty():
				tab.history.append(clean_url)

	if tab.history.is_empty():
		tab.history_index = -1
	else:
		tab.history_index = clampi(
			int(state.get("history_index", tab.history.size() - 1)),
			0,
			tab.history.size() - 1
		)

		if tab.current_url.is_empty():
			tab.current_url = tab.history[tab.history_index]

	var raw_site_state: Variant = state.get("site_state", {})

	if raw_site_state is Dictionary:
		tab.site_state = (raw_site_state as Dictionary).duplicate(true)

	var favicon_path: String = str(
		state.get("favicon_path", "")
	).strip_edges()

	if (
		not favicon_path.is_empty()
		and ResourceLoader.exists(favicon_path)
	):
		var loaded_resource: Resource = ResourceLoader.load(favicon_path)

		if loaded_resource is Texture2D:
			tab.favicon = loaded_resource as Texture2D

	return tab
