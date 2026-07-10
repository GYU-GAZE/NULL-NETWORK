extends Resource
class_name WebsitePage

@export_category("Route")
@export var url: String = "null.net"
@export var match_as_prefix: bool = false

@export_category("Browser Metadata")
@export var page_title: String = "New Page"
@export var favicon: Texture2D
@export var record_in_browser_history: bool = true

@export_category("Page Scene")
@export var site_scene: PackedScene


func has_valid_route() -> bool:
	return not url.strip_edges().is_empty()


func has_site_scene() -> bool:
	return site_scene != null
