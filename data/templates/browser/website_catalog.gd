@tool
extends Resource
class_name WebsiteCatalog

## Authoring catalog for every simulated Browser route.
## SimulatedDNS consumes this Resource instead of owning a hand-maintained list
## directly in its autoload scene.

@export var pages: Array[WebsitePage] = []


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var exact_urls: Dictionary = {}
	for index: int in range(pages.size()):
		var page: WebsitePage = pages[index]
		if page == null:
			errors.append("Page %d is null." % index)
			continue
		var clean_url := page.url.strip_edges().to_lower()
		if clean_url.is_empty():
			errors.append("Page %d has an empty url." % index)
			continue
		if not page.match_as_prefix:
			while clean_url.ends_with("/"):
				clean_url = clean_url.trim_suffix("/")
			if exact_urls.has(clean_url):
				errors.append("Duplicate exact route '%s'." % clean_url)
			exact_urls[clean_url] = true
		if page.site_scene == null:
			errors.append("Page '%s' has no site_scene." % page.url)
	return errors
