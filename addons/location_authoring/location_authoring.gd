@tool
extends RefCounted
class_name LocationAuthoring

const DEFAULT_CATALOG := "res://data/content/game_content_catalog.tres"
const DEFAULT_WORLD := "res://data/content/navigator/world_map.tres"
const TEMPLATE := "res://addons/location_authoring/local_area_template.tscn"


static func create_location(options: Dictionary) -> Dictionary:
	var id := str(options.get("id", "")).strip_edges()
	var title := str(options.get("name", "")).strip_edges()
	var folder := str(options.get("folder", "")).trim_suffix("/")
	var catalog_path := str(options.get("catalog", DEFAULT_CATALOG))
	var world_path := str(options.get("world", DEFAULT_WORLD))
	var errors := PackedStringArray()
	if not id.is_valid_identifier() or title.is_empty():
		errors.append("Use a stable identifier (letters/numbers/underscores) and a location name.")
	if not folder.begins_with("res://") or ".." in folder or folder == "res:":
		errors.append("Destination must be a folder inside res://.")
	var catalog := ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GameContentCatalog if FileAccess.file_exists(catalog_path) else null
	var world := ResourceLoader.load(world_path, "", ResourceLoader.CACHE_MODE_IGNORE) as NavigatorWorldData if FileAccess.file_exists(world_path) else null
	if catalog == null or world == null or catalog_path == world_path:
		errors.append("Choose valid GameContentCatalog and NavigatorWorldData files.")
	else:
		errors.append_array(world.validate_data(catalog))
		for location: MapLocation in catalog.locations:
			if location != null and location.get_display_id() == id:
				errors.append("Location ID '%s' is already registered." % id)
	var position: Vector2 = options.get("position", Vector2(0.5, 0.5))
	if not position.is_finite() or position.x < 0 or position.y < 0 or position.x > 1 or position.y > 1:
		errors.append("Map position must be normalized between 0 and 1.")
	var category := int(options.get("category", MapLocation.LocationCategory.OTHER))
	if category < 0 or category >= MapLocation.LocationCategory.size():
		errors.append("Choose a valid location category.")
	var activity: ActivityDefinitionData = _optional_resource(options, "activity", errors) as ActivityDefinitionData
	var table: SpawnTable = _optional_resource(options, "spawn_table", errors) as SpawnTable
	var unlock: ConditionRuleData = _optional_resource(options, "unlock_conditions", errors) as ConditionRuleData
	var availability: ConditionRuleData = _optional_resource(options, "availability_conditions", errors) as ConditionRuleData
	var icon: Texture2D = _optional_resource(options, "icon", errors) as Texture2D
	if activity == null:
		errors.append("A travel ActivityDefinitionData is required.")
	for pair: Array in [["spawn_table", table], ["unlock_conditions", unlock], ["availability_conditions", availability], ["icon", icon]]:
		if not str(options.get(pair[0], "")).is_empty() and pair[1] == null:
			errors.append("Incorrect Resource type for %s." % pair[0])
	var existing := str(options.get("scene", "")).strip_edges()
	var scene: PackedScene = ResourceLoader.load(existing) as PackedScene if not existing.is_empty() and ResourceLoader.exists(existing) else null
	if not existing.is_empty() and scene == null:
		errors.append("Existing local scene could not be loaded.")
	var scene_path := folder.path_join(id + ".tscn")
	var area_path := folder.path_join(id + "_area.tres")
	var location_path := folder.path_join(id + ".tres")
	var new_paths: Array[String] = [area_path, location_path]
	if existing.is_empty():
		new_paths.push_front(scene_path)
	for path: String in new_paths:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
			errors.append("Destination already exists: %s" % path)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	if scene == null:
		var template := load(TEMPLATE) as PackedScene
		if template == null:
			return {"ok": false, "errors": PackedStringArray(["Local area template is missing."])}
		var root := template.instantiate()
		root.name = id
		scene = PackedScene.new()
		var packed := scene.pack(root)
		root.free()
		if packed != OK:
			return {"ok": false, "errors": PackedStringArray(["Could not pack the local area template."])}
	var area := LocalAreaData.new()
	area.area_id = id + ".local"
	area.area_name = title
	area.area_description = str(options.get("description", ""))
	area.area_scene = scene
	var location := MapLocation.new()
	location.location_id = id
	location.location_name = title
	location.location_description = area.area_description
	location.world_map_position = position
	location.category = category as MapLocation.LocationCategory
	location.initially_discovered = bool(options.get("visible", true))
	location.unlocked_by_default = bool(options.get("unlocked", true))
	location.unlock_conditions = unlock
	location.availability_conditions = availability
	location.marker_icon = icon
	location.local_area = area
	location.travel_activity = activity
	location.spawn_table = table
	# Duplicate the concrete Resource, not its base type. Specialized calendar,
	# social and Encyclopedia content/properties remain exactly the same.
	var next_catalog := catalog.duplicate() as GameContentCatalog
	next_catalog.locations = catalog.locations.duplicate()
	next_catalog.locations.append(location)
	var next_world := world.duplicate() as NavigatorWorldData
	next_world.locations = world.locations.duplicate()
	next_world.locations.append(location)
	# The Editor validates location structure/cross-references without executing
	# unrelated gameplay Resources or their autoload-dependent validators.
	if not Engine.is_editor_hint():
		errors.append_array(next_catalog.validate_data())
	errors.append_array(next_world.validate_data(next_catalog))
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return {"ok": false, "errors": PackedStringArray(["Cannot create destination folder."])}
	var writes: Array[Array] = []
	if existing.is_empty():
		writes.append([scene, scene_path])
	writes.append_array([[area, area_path], [location, location_path]])
	var catalogs: Array[Array] = [[next_catalog, catalog_path], [next_world, world_path]]
	var result := _save_transaction(writes, catalogs)
	if not result.ok:
		return result
	ResourceLoader.load(catalog_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	ResourceLoader.load(world_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return {"ok": true, "scene": existing if not existing.is_empty() else scene_path, "area": area_path, "location": location_path, "catalog": catalog_path, "world": world_path}


static func _optional_resource(options: Dictionary, key: String, errors: PackedStringArray) -> Resource:
	var path := str(options.get(key, "")).strip_edges()
	if path.is_empty():
		return null
	var resource := ResourceLoader.load(path) if ResourceLoader.exists(path) else null
	if resource == null:
		errors.append("Missing Resource for %s: %s" % [key, path])
	return resource


static func _save_transaction(writes: Array[Array], catalogs: Array[Array]) -> Dictionary:
	var created: Array[String] = []
	var temporary: Array[String] = []
	var backups := {}
	for pair: Array in catalogs:
		var path := str(pair[1])
		var pending := path.get_basename() + ".pending.tres"
		if FileAccess.file_exists(pending):
			return {"ok": false, "errors": PackedStringArray(["A pending catalog exists; resolve it before creating another location."])}
		backups[path] = FileAccess.get_file_as_bytes(path)
	var failure := OK
	for pair: Array in writes:
		created.append(pair[1])
		failure = ResourceSaver.save(pair[0], pair[1])
		if failure != OK:
			break
		(pair[0] as Resource).take_over_path(pair[1])
	if failure == OK:
		for pair: Array in catalogs:
			var pending := str(pair[1]).get_basename() + ".pending.tres"
			temporary.append(pending)
			failure = ResourceSaver.save(pair[0], pending)
			if failure != OK:
				break
	var replaced: Array[String] = []
	if failure == OK:
		for index: int in range(catalogs.size()):
			failure = DirAccess.rename_absolute(temporary[index], catalogs[index][1])
			if failure != OK:
				break
			replaced.append(catalogs[index][1])
	if failure != OK:
		var rollback_errors := PackedStringArray()
		for path: String in replaced:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(backups[path])
				file.close()
			else:
				rollback_errors.append("Could not restore catalog: %s" % path)
		for path: String in created + temporary:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		rollback_errors.append("Creation failed (%s); new files rolled back." % error_string(failure))
		return {"ok": false, "errors": rollback_errors}
	return {"ok": true}
