@tool
extends Resource
class_name WebsiteCatalog

## Authoring catalog for every simulated Browser route.
## SimulatedDNS consumes this Resource instead of owning a hand-maintained list
## directly in its autoload scene.

@export var pages: Array[WebsitePage] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var routes := {}
	for index: int in range(pages.size()):
		var page := pages[index]
		if page == null:
			errors.append("Page %d is null." % index)
			continue
		var key := BrowserRoute.normalize(page.url)
		var kind := "prefix:" if page.match_as_prefix else "exact:"
		if routes.has(kind + key):
			errors.append("Duplicate %s route '%s'." % [kind.trim_suffix(":"), key])
		routes[kind + key] = true
		for error: String in page.validate_data():
			errors.append(error)
	# Nested prefixes are deliberate and deterministic: longest segment prefix
	# wins. Exact routes override prefixes at the same URL, as in a normal router.
	return errors
