@tool
extends EditorPlugin


func _enter_tree() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().create_timer(2).timeout
	var production := _find_plugin(get_tree().root)
	if production == null:
		_fail("Production location EditorPlugin is not enabled.")
		return
	var folder := "res://editor_location_output/run_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	var catalog := load(LocationAuthoring.DEFAULT_CATALOG) as GameContentCatalog
	var copy := catalog.duplicate() as GameContentCatalog
	var world := NavigatorWorldData.new()
	world.world_id = "editor_acceptance"
	world.map_logical_size = Vector2i(640, 360)
	var catalog_path := folder.path_join("catalog.tres")
	var world_path := folder.path_join("world.tres")
	ResourceSaver.save(copy, catalog_path)
	ResourceSaver.save(world, world_path)
	production.call("_open_dialog")
	var fields: Dictionary = production.get("_fields")
	fields.id.text = "editor_district"
	fields.name.text = "District created in the Editor"
	fields.description.text = "Native location authoring acceptance."
	fields.folder.text = folder
	fields.catalog.text = catalog_path
	fields.world.text = world_path
	fields.activity.text = "res://data/content/activities/travel_akihabara.tres"
	fields.spawn_table.text = "res://data/content/navigator/areas/akihabara/akihabara_spawn_table.tres"
	production.call("_create")
	await get_tree().create_timer(2).timeout
	var edited := get_editor_interface().get_edited_scene_root()
	var updated := ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GameContentCatalog
	var updated_world := ResourceLoader.load(world_path, "", ResourceLoader.CACHE_MODE_IGNORE) as NavigatorWorldData
	if edited == null or edited.scene_file_path != folder.path_join("editor_district.tscn") or updated == null or updated.locations.size() != catalog.locations.size() + 1:
		_fail("Dialog did not create/register/open the new local area.")
		return
	if updated.get_script() != catalog.get_script() or not updated_world.validate_data(updated).is_empty():
		_fail("Dialog changed catalog type or registered inconsistent resources.")
		return
	production.call("_open_dialog")
	fields.id.text = "editor_linked"
	fields.scene.text = edited.scene_file_path
	production.call("_create")
	await get_tree().create_timer(1).timeout
	updated = ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GameContentCatalog
	if updated.locations.size() != catalog.locations.size() + 2 or FileAccess.file_exists(folder.path_join("editor_linked.tscn")):
		_fail("Dialog failed to link an existing scene without duplicating it.")
		return
	var bytes := FileAccess.get_file_as_bytes(catalog_path)
	production.call("_open_dialog")
	production.call("_create")
	var dialog := production.get("_dialog") as ConfirmationDialog
	if bytes != FileAccess.get_file_as_bytes(catalog_path) or not dialog.visible or (production.get("_message") as Label).text.is_empty():
		_fail("Duplicate ID was not rejected without changing the catalog.")
		return
	await get_tree().process_frame
	if dialog.size.y > 900:
		_fail("Validation error expanded the authoring dialog beyond a usable height.")
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--editor-capture=") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var path := argument.trim_prefix("--editor-capture=")
			get_tree().root.get_texture().get_image().save_png(path)
			dialog.get_texture().get_image().save_png(path.get_basename() + "-dialog.png")
	print("LOCATION_AUTHORING_EDITOR_SMOKE: PASS")
	get_tree().quit(0)


func _find_plugin(node: Node) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == "res://addons/location_authoring/location_authoring_plugin.gd":
		return node
	for child: Node in node.get_children():
		var found := _find_plugin(child)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	print("LOCATION_AUTHORING_EDITOR_SMOKE: FAIL")
	get_tree().quit(1)
