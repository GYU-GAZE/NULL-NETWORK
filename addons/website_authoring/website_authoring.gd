@tool
extends RefCounted
class_name WebsiteAuthoring

const DEFAULT_CATALOG: String = "res://data/content/sites/website_catalog.tres"
const TEMPLATES: Dictionary = {
	"document": "res://addons/website_authoring/templates/document.tscn",
	"application": "res://addons/website_authoring/templates/application.tscn",
	"viewport": "res://addons/website_authoring/templates/viewport.tscn",
}


## This is the creation flow called by the actual Editor dialog and acceptance
## tests. It writes only content scenes/Resources and the selected catalog.
static func create_page(options: Dictionary) -> Dictionary:
	var internal_name := str(options.get("name", "")).strip_edges()
	var url := BrowserRoute.normalize(str(options.get("url", "")))
	var title := str(options.get("title", "")).strip_edges()
	var folder := str(options.get("folder", "")).trim_suffix("/")
	var template := str(options.get("template", "document"))
	var catalog_path := str(options.get("catalog", DEFAULT_CATALOG))
	var errors := PackedStringArray()
	if internal_name.is_empty() or not internal_name.is_valid_identifier():
		errors.append("Internal name must use letters, numbers and underscores.")
	var route_error := BrowserRoute.validate(url)
	if not route_error.is_empty():
		errors.append(route_error)
	if title.is_empty():
		errors.append("Page title is required.")
	if not folder.begins_with("res://") or ".." in folder or folder == "res:":
		errors.append("Choose a destination folder inside res://.")
	if not TEMPLATES.has(template):
		errors.append("Choose document, application or viewport template.")
	var catalog := ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_IGNORE) as WebsiteCatalog if FileAccess.file_exists(catalog_path) else null
	if catalog == null:
		errors.append("The selected WebsiteCatalog could not be loaded.")
	else:
		for page: WebsitePage in catalog.pages:
			if page != null and BrowserRoute.normalize(page.url) == url:
				errors.append("URL '%s' is already registered." % url)
	var scene_path := folder.path_join(internal_name + ".tscn")
	var page_path := folder.path_join(internal_name + ".tres")
	for path: String in [scene_path, page_path]:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
			errors.append("File already exists: %s" % path)
	var favicon_path := str(options.get("favicon", ""))
	var favicon: Texture2D
	if not favicon_path.is_empty():
		favicon = load(favicon_path) as Texture2D if ResourceLoader.exists(favicon_path) else null
		if favicon == null:
			errors.append("Favicon must be an existing texture.")
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var template_scene := load(TEMPLATES[template]) as PackedScene if ResourceLoader.exists(TEMPLATES[template]) else null
	if template_scene == null:
		return {"ok": false, "errors": PackedStringArray(["The selected page template is missing or invalid."])}
	var root := template_scene.instantiate()
	root.name = internal_name
	var heading := root.find_child("Heading", true, false) as Label
	if heading != null:
		heading.text = title
	var scene := PackedScene.new()
	var packed := scene.pack(root)
	root.free()
	if packed != OK:
		return {"ok": false, "errors": PackedStringArray(["Could not pack the page template."])}
	var page := WebsitePage.new()
	page.url = url
	page.page_title = title
	page.favicon = favicon
	page.site_scene = scene
	page.overflow_policy = {"document": WebsitePage.OverflowPolicy.PAGE_SCROLL, "application": WebsitePage.OverflowPolicy.SELF_MANAGED_SCROLL, "viewport": WebsitePage.OverflowPolicy.FIXED_VIEWPORT}[template]
	var next_catalog := WebsiteCatalog.new()
	next_catalog.pages = catalog.pages.duplicate()
	next_catalog.pages.append(page)
	errors = next_catalog.validate_data()
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return {"ok": false, "errors": PackedStringArray(["Cannot create destination folder."])}
	var temporary_catalog := catalog_path.get_basename() + ".pending.tres"
	if FileAccess.file_exists(temporary_catalog):
		return {"ok": false, "errors": PackedStringArray(["A pending catalog exists; resolve it before creating another page."])}
	var result := ResourceSaver.save(scene, scene_path)
	if result == OK:
		scene.take_over_path(scene_path)
		result = ResourceSaver.save(page, page_path)
	if result == OK:
		page.take_over_path(page_path)
		result = ResourceSaver.save(next_catalog, temporary_catalog)
	if result == OK:
		result = DirAccess.rename_absolute(temporary_catalog, catalog_path)
	if result != OK:
		# The existing catalog is replaced only after both files and the complete
		# next catalog have been saved. Cancel/validation never writes anything.
		for path: String in [scene_path, page_path, temporary_catalog]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		return {"ok": false, "errors": PackedStringArray(["Creation failed (%s); new files were rolled back." % error_string(result)])}
	ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return {"ok": true, "scene": scene_path, "page": page_path, "catalog": catalog_path}
