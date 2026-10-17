extends Resource
class_name BrowserTabData

const DEFAULT_PAGE_TITLE: String = "Nova Aba"
var history: Array[BrowserHistoryEntry] = []
var history_index: int = -1
var page_title: String = DEFAULT_PAGE_TITLE
var favicon: Texture2D
var current_url: String:
	get:
		var entry := current_entry()
		return entry.url if entry != null else ""


func current_entry() -> BrowserHistoryEntry:
	return history[history_index] if history_index >= 0 and history_index < history.size() else null


func navigate_to(url: String, title: String = "", icon: Texture2D = null) -> void:
	var clean := BrowserRoute.normalize(url)
	if clean.is_empty():
		return
	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)
	var entry := BrowserHistoryEntry.new()
	entry.url = clean
	history.append(entry)
	history_index = history.size() - 1
	set_page_title(title)
	set_favicon(icon)


func can_go_back() -> bool:
	return history_index > 0


func go_back() -> String:
	if can_go_back():
		history_index -= 1
	return current_url


func can_go_forward() -> bool:
	return history_index >= 0 and history_index < history.size() - 1


func go_forward() -> String:
	if can_go_forward():
		history_index += 1
	return current_url


func set_page_title(title: String) -> void:
	page_title = title.strip_edges()
	if page_title.is_empty():
		page_title = current_url if not current_url.is_empty() else DEFAULT_PAGE_TITLE


func set_favicon(icon: Texture2D) -> void:
	favicon = icon


func to_session_state() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entry: BrowserHistoryEntry in history:
		entries.append(entry.to_data())
	return {"entries": entries, "history_index": history_index, "page_title": page_title, "favicon_path": favicon.resource_path if favicon != null else ""}


static func from_session_state(state: Dictionary) -> BrowserTabData:
	var tab := BrowserTabData.new()
	var entries: Variant = state.get("entries", [])
	if entries is Array:
		for raw: Variant in entries:
			if raw is Dictionary:
				var entry := BrowserHistoryEntry.from_data(raw)
				if not entry.url.is_empty():
					tab.history.append(entry)
	# v1 kept URL strings plus custom state for only the current history entry.
	if tab.history.is_empty():
		var old_history: Variant = state.get("history", [])
		if old_history is Array:
			for raw: Variant in old_history:
				if raw is String and not BrowserRoute.normalize(raw).is_empty():
					tab.navigate_to(raw)
		if tab.history.is_empty() and not str(state.get("current_url", "")).is_empty():
			tab.navigate_to(str(state.current_url))
	if not tab.history.is_empty():
		tab.history_index = clampi(int(state.get("history_index", tab.history.size() - 1)), 0, tab.history.size() - 1)
		if not state.has("entries") and state.get("site_state", {}) is Dictionary:
			tab.current_entry().page_state = BrowserHistoryEntry.sanitize(state.get("site_state", {}))
	tab.set_page_title(str(state.get("page_title", "")))
	var icon_path := str(state.get("favicon_path", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		tab.favicon = load(icon_path) as Texture2D
	return tab
