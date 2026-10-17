@tool
extends EditorPlugin


func _enter_tree() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	print("EDITOR_SMOKE: production plugin lookup")
	await get_tree().create_timer(2.0).timeout
	var production := _find_production_plugin(get_tree().root)
	if production == null:
		_fail("Production authoring EditorPlugin was not enabled.")
		return
	# A new path also exercises open_scene_from_path when a previous isolated
	# smoke session was restored by the Editor's own workspace state.
	var folder := "res://editor_smoke_output/run_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	var catalog_path := folder.path_join("catalog.tres")
	for filename: String in ["editor_created.tscn", "editor_created.tres", "catalog.pending.tres"]:
		if FileAccess.file_exists(folder.path_join(filename)):
			DirAccess.remove_absolute(folder.path_join(filename))
	ResourceSaver.save(WebsiteCatalog.new(), catalog_path)
	production.call("_open_dialog")
	var fields: Dictionary = production.get("_fields")
	fields.name.text = "editor_created"
	fields.url.text = "HTTPS://WWW.EDITOR.ACCEPTANCE/"
	fields.title.text = "Created through the Editor dialog"
	fields.folder.text = folder
	fields.catalog.text = catalog_path
	production.call("_create")
	print("EDITOR_SMOKE: create dialog confirmed")
	await get_tree().create_timer(2.0).timeout
	var catalog := ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_IGNORE) as WebsiteCatalog
	if catalog == null or catalog.pages.size() != 1 or catalog.pages[0].url != "editor.acceptance":
		_fail("Editor dialog did not create/register its WebsitePage.")
		return
	var edited := get_editor_interface().get_edited_scene_root()
	print("EDITOR_SMOKE: catalog verified; checking edited scene")
	if edited == null or edited.scene_file_path != folder.path_join("editor_created.tscn"):
		_fail("Editor did not open the generated scene for editing.")
		return
	var dialog := production.get("_dialog") as ConfirmationDialog
	if dialog.visible:
		_fail("Successful creation did not close the dialog.")
		return
	# Invalid confirmation leaves the current catalog byte-identical and reports
	# an inline error. Cancel itself performs no creation writes.
	var bytes := FileAccess.get_file_as_bytes(catalog_path)
	production.call("_open_dialog")
	fields.name.text = "duplicate"
	production.call("_create")
	print("EDITOR_SMOKE: duplicate rejected")
	if FileAccess.get_file_as_bytes(catalog_path) != bytes or not dialog.visible:
		_fail("Invalid Editor creation altered catalog or hid the error.")
		return
	if (production.get("_message") as Label).text.is_empty():
		_fail("Editor creation error was not shown.")
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--editor-capture=") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png(argument.trim_prefix("--editor-capture="))
			dialog.get_texture().get_image().save_png(argument.trim_prefix("--editor-capture=").get_basename() + "-dialog.png")
	print("WEBSITE_AUTHORING_EDITOR_SMOKE: PASS")
	get_tree().quit(0)


func _find_production_plugin(node: Node) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == "res://addons/website_authoring/website_authoring_plugin.gd":
		return node
	for child: Node in node.get_children():
		var found := _find_production_plugin(child)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error(message)
	print("WEBSITE_AUTHORING_EDITOR_SMOKE: FAIL")
	get_tree().quit(1)
