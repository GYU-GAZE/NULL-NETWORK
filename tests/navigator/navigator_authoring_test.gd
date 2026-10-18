extends NavigatorTestHarness


func run() -> void:
	var folder := "res://.godot/navigator_authoring_fixture/run_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	var source: GameContentCatalog = ContentRegistry.catalog
	var catalog := source.duplicate() as GameContentCatalog
	var world := NavigatorWorldData.new()
	world.world_id = "authoring_acceptance"
	world.map_logical_size = Vector2i(640, 360)
	var catalog_path := folder.path_join("catalog.tres")
	var world_path := folder.path_join("world.tres")
	ResourceSaver.save(catalog, catalog_path)
	ResourceSaver.save(world, world_path)
	var options := {"id": "acceptance_district", "name": "Acceptance District", "description": "Created with the production location authoring flow.", "position": Vector2(0.3, 0.6), "visible": true, "folder": folder, "catalog": catalog_path, "world": world_path, "activity": "res://data/content/activities/travel_akihabara.tres", "spawn_table": "res://data/content/navigator/areas/akihabara/akihabara_spawn_table.tres"}
	var result := LocationAuthoring.create_location(options)
	check(result.ok, "Production location authoring failed: %s" % result)
	if not result.ok:
		finish("NAVIGATOR_AUTHORING_TEST")
		return
	var created := ResourceLoader.load(result.location, "", ResourceLoader.CACHE_MODE_REPLACE) as MapLocation
	check(created.validate_data().is_empty(), "Created location does not satisfy runtime contract")
	var updated := ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_REPLACE) as GameContentCatalog
	check(updated.get_script() == source.get_script(), "Authoring replaced a concrete content catalog with its base class")
	for key: String in ["calendar_catalog", "encyclopedia_catalog", "npc_catalog"]:
		check(updated.get(key) == source.get(key), "Specialized content was lost: %s" % key)
	check(updated.locations.size() == source.locations.size() + 1, "Authoring replaced existing locations")
	var updated_world := ResourceLoader.load(world_path, "", ResourceLoader.CACHE_MODE_REPLACE) as NavigatorWorldData
	check(updated_world.validate_data(updated).is_empty(), "Created world projection disagrees with global registry")
	var original_catalog := FileAccess.get_file_as_bytes(catalog_path)
	var original_world := FileAccess.get_file_as_bytes(world_path)
	check(not LocationAuthoring.create_location(options).ok, "Duplicate location ID was accepted")
	check(original_catalog == FileAccess.get_file_as_bytes(catalog_path) and original_world == FileAccess.get_file_as_bytes(world_path), "Duplicate creation altered a catalog")
	var linked := options.duplicate()
	linked.id = "linked_area"
	linked.scene = result.scene
	check(LocationAuthoring.create_location(linked).ok, "Authoring could not link an existing compatible scene")
	check(not FileAccess.file_exists(folder.path_join("linked_area.tscn")), "Linking an existing scene generated a redundant scene")
	original_catalog = FileAccess.get_file_as_bytes(catalog_path)
	original_world = FileAccess.get_file_as_bytes(world_path)
	var invalid := options.duplicate()
	invalid.id = "invalid_area"
	invalid.scene = "res://apps/browser/app_browser.tscn"
	check(not LocationAuthoring.create_location(invalid).ok, "Incompatible scene was accepted")
	invalid = options.duplicate()
	invalid.id = "missing_resource"
	invalid.spawn_table = "res://no_such_spawn_table.tres"
	check(not LocationAuthoring.create_location(invalid).ok, "Broken Resource reference was accepted")
	var pending := world_path.get_basename() + ".pending.tres"
	DirAccess.make_dir_absolute(pending)
	var interrupted := options.duplicate()
	interrupted.id = "rollback_probe"
	print("LOCATION_EXPECTED_WRITE_FAILURE: BEGIN")
	check(not LocationAuthoring.create_location(interrupted).ok, "Catalog write failure was reported as success")
	print("LOCATION_EXPECTED_WRITE_FAILURE: END")
	check(original_catalog == FileAccess.get_file_as_bytes(catalog_path) and original_world == FileAccess.get_file_as_bytes(world_path), "Failed creation did not preserve both original catalogs")
	for name: String in ["rollback_probe.tscn", "rollback_probe_area.tres", "rollback_probe.tres"]:
		check(not FileAccess.file_exists(folder.path_join(name)), "Failed creation left a partial file: %s" % name)
	DirAccess.remove_absolute(pending)
	var area := created.local_area.duplicate() as LocalAreaData
	area.default_entry_id = "missing"
	check(not area.validate_data().is_empty(), "Missing entry point was accepted")
	area = created.local_area.duplicate() as LocalAreaData
	var root := area.area_scene.instantiate()
	var points := root.get_node("PopulationController/SpawnPoints")
	var copy := points.get_child(0).duplicate()
	points.add_child(copy)
	copy.owner = root
	var bad_scene := PackedScene.new()
	bad_scene.pack(root)
	root.free()
	area.area_scene = bad_scene
	check(not area.validate_data().is_empty(), "Duplicate spawn point was accepted")
	var unrelated := updated_world.duplicate() as NavigatorWorldData
	unrelated.locations = updated_world.locations.duplicate()
	unrelated.locations[0] = created.duplicate() as MapLocation
	check(not unrelated.validate_data(updated).is_empty(), "A parallel gameplay definition with the same location ID was accepted")
	# The generated scene is opened by the actual runtime, with population.
	var view := (load("res://apps/navigator/local_area/navigator_local_area_view.tscn") as PackedScene).instantiate() as NavigatorLocalAreaView
	view.size = Vector2(640, 360)
	add_child(view)
	check(view.open_area(created.local_area, "", Vector2.ZERO, false, {}, created), "Generated scene did not open in NavigatorLocalAreaView")
	view.activate()
	await settle()
	check(view.get_current_area_instance().player.global_position == Vector2(160, 180), "Generated entry did not position Player correctly")
	await capture("authored_local_area")
	view.queue_free()
	await get_tree().process_frame
	finish("NAVIGATOR_AUTHORING_TEST")
