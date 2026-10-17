extends RefCounted
class_name BrowserHistoryEntry

var url: String = ""
var page_state: Dictionary = {}
var scroll_y: int = 0


func to_data() -> Dictionary:
	return {"url": url, "page_state": sanitize(page_state), "scroll_y": scroll_y}


static func from_data(data: Dictionary) -> BrowserHistoryEntry:
	var entry := BrowserHistoryEntry.new()
	entry.url = BrowserRoute.normalize(str(data.get("url", "")))
	var state: Variant = data.get("page_state", {})
	entry.page_state = sanitize(state) if state is Dictionary else {}
	entry.scroll_y = maxi(0, int(data.get("scroll_y", 0)))
	return entry


## Session data contains only values. Never persist Nodes, Resources or Callables
## returned by a page, including references nested in custom form state.
static func sanitize(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			if key is String or key is StringName:
				result[str(key)] = sanitize(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(sanitize(item))
		return result
	if value == null or value is String or value is StringName or value is bool or value is int or value is float:
		return value
	return null
