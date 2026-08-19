extends Node

signal routes_rebuilt

@export var website_catalog: WebsiteCatalog
## Compatibility fallback for scenes/tests that still inject routes directly.
@export var registered_sites: Array[WebsitePage] = []

var _exact_routes: Dictionary = {}
var _prefix_routes: Array[WebsitePage] = []


func _ready() -> void:
	rebuild_routes()


func normalize_url(raw_url: String) -> String:
	var clean_url: String = raw_url.to_lower().strip_edges()
	clean_url = clean_url.trim_prefix("https://")
	clean_url = clean_url.trim_prefix("http://")
	clean_url = clean_url.trim_prefix("www.")
	return clean_url


func get_registered_pages() -> Array[WebsitePage]:
	if website_catalog != null:
		return website_catalog.pages
	return registered_sites


func rebuild_routes() -> void:
	_exact_routes.clear()
	_prefix_routes.clear()

	if website_catalog != null:
		for error: String in website_catalog.validate_data():
			push_error("WebsiteCatalog: %s" % error)

	for site: WebsitePage in get_registered_pages():
		_register_site(site)

	_prefix_routes.sort_custom(func(a: WebsitePage, b: WebsitePage) -> bool:
		return normalize_url(a.url).length() > normalize_url(b.url).length()
	)

	routes_rebuilt.emit()


func fetch_page(url: String) -> WebsitePage:
	var target_url: String = normalize_url(url)

	if target_url.is_empty():
		return null

	var exact_key: String = _get_exact_key(target_url)

	if _exact_routes.has(exact_key):
		return _exact_routes[exact_key] as WebsitePage

	for site in _prefix_routes:
		var site_url: String = normalize_url(site.url)

		if target_url.begins_with(site_url):
			return site

	return null


func _register_site(site: WebsitePage) -> void:
	if site == null:
		return

	var site_url: String = normalize_url(site.url)

	if site_url.is_empty():
		push_warning("SimulatedDNS: ignored WebsitePage with an empty route.")
		return

	if site.site_scene == null:
		push_warning("SimulatedDNS: route '%s' has no site_scene." % site.url)

	if site.match_as_prefix:
		_prefix_routes.append(site)
		return

	var exact_key: String = _get_exact_key(site_url)

	if _exact_routes.has(exact_key):
		var previous: WebsitePage = _exact_routes[exact_key] as WebsitePage
		push_warning(
			"SimulatedDNS: duplicate route '%s'. '%s' was replaced by '%s'." % [
				exact_key,
				previous.resource_path,
				site.resource_path
			]
		)

	_exact_routes[exact_key] = site


func _get_exact_key(url: String) -> String:
	var key: String = normalize_url(url)

	while key.ends_with("/"):
		key = key.trim_suffix("/")

	return key
