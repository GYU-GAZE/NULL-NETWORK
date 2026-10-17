@tool
extends Resource
class_name WebsitePage

enum OverflowPolicy {
	FIXED_VIEWPORT,
	PAGE_SCROLL,
	SELF_MANAGED_SCROLL,
}

@export_category("Route")
@export var url: String = "null.net"
@export var match_as_prefix: bool = false

@export_category("Browser Metadata")
@export var page_title: String = "New Page"
@export var favicon: Texture2D
@export var record_in_browser_history: bool = true

@export_category("Page Scene")
@export var site_scene: PackedScene
@export var overflow_policy: OverflowPolicy = OverflowPolicy.PAGE_SCROLL

func has_valid_route() -> bool:
	return not url.strip_edges().is_empty()


func has_site_scene() -> bool:
	return site_scene != null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var route_error := BrowserRoute.validate(url)
	if not route_error.is_empty():
		errors.append(route_error)
	if site_scene == null:
		errors.append("Page '%s' has no site_scene." % url)
		return errors
	var root := site_scene.instantiate()
	if root is not Control:
		errors.append("Page '%s' must have a Control root." % url)
	elif overflow_policy == OverflowPolicy.PAGE_SCROLL:
		if root is not Container or root is ScrollContainer:
			errors.append("Document '%s' needs a natural-height Container root, without a root ScrollContainer." % url)
	elif overflow_policy == OverflowPolicy.SELF_MANAGED_SCROLL:
		if not _contains_scroll(root):
			errors.append("Self-managed page '%s' must provide a ScrollContainer." % url)
	root.free()
	return errors


func _contains_scroll(node: Node) -> bool:
	if node is ScrollContainer:
		return true
	for child: Node in node.get_children():
		if _contains_scroll(child):
			return true
	return false
