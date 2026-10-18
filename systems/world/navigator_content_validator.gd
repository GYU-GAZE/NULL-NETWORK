@tool
extends RefCounted
class_name NavigatorContentValidator

## Structural authoring validation; it does not spawn an active area or mutate
## campaign state. Hidden narrative-only locations may omit a local scene.
static func validate_area(data: LocalAreaData) -> PackedStringArray:
	var errors := PackedStringArray()
	if data.get_display_id().is_empty():
		errors.append("Area ID is required.")
	if data.area_scene == null:
		errors.append("Area scene is required.")
		return errors
	var root := data.area_scene.instantiate()
	if root is not NavigatorLocalAreaScene:
		errors.append("Area root must inherit NavigatorLocalAreaScene.")
	else:
		if root.get_node_or_null("%Player") is not LocalAreaPlayerController:
			errors.append("A unique Player inheriting LocalAreaPlayerController is required.")
		var entries := root.get_node_or_null("%EntryPoints")
		if entries == null:
			errors.append("A unique EntryPoints node is required.")
		var entry_ids := {}
		if entries != null:
			for node: Node in entries.find_children("*", "LocalAreaEntryPoint", true, false):
				var id: String = node.get_entry_id()
				if id.is_empty() or entry_ids.has(id):
					errors.append("Empty or duplicate entry ID: %s" % id)
				entry_ids[id] = true
		if not entry_ids.has(data.default_entry_id):
			errors.append("Default entry '%s' does not exist." % data.default_entry_id)
		var point_ids := {}
		for node: Node in root.find_children("*", "LocalAreaSpawnPoint", true, false):
			var id: String = node.get_display_id()
			if id.is_empty() or point_ids.has(id):
				errors.append("Empty or duplicate spawn point ID: %s" % id)
			point_ids[id] = true
		var population := root.get_node_or_null("%PopulationController") as LocalAreaPopulationController
		if population != null:
			if population.get_node_or_null(population.spawn_points_path) == null or population.get_node_or_null(population.population_actors_path) is not Node2D:
				errors.append("PopulationController paths must resolve to spawn points and a Node2D actor root.")
	root.free()
	return errors


static func validate_location(location: MapLocation) -> PackedStringArray:
	var errors := PackedStringArray()
	if location.location_id.strip_edges().is_empty():
		errors.append("Location ID is required.")
	if location.location_name.strip_edges().is_empty():
		errors.append("Location name is required.")
	for condition: ConditionRuleData in [location.unlock_conditions, location.availability_conditions]:
		if condition != null:
			errors.append_array(condition.validate_data())
	for period: String in location.required_time_periods:
		if period.to_upper() not in ["DAY", "NIGHT"]:
			errors.append("Legacy time period must be DAY or NIGHT.")
	if location.local_area != null:
		errors.append_array(validate_area(location.local_area))
		if location.travel_activity == null and location.show_on_world_map:
			errors.append("Explorable locations require a travel activity.")
		elif location.travel_activity != null:
			errors.append_array(location.travel_activity.validate_data())
	elif location.travel_activity != null or location.spawn_table != null:
		errors.append("Travel/population requires a local area; narrative-only locations should omit both.")
	if location.spawn_table != null:
		errors.append_array(location.spawn_table.validate_data())
		if location.local_area != null and location.local_area.area_scene != null:
			var root := location.local_area.area_scene.instantiate()
			var has_common_point := false
			for point: Node in root.find_children("*", "LocalAreaSpawnPoint", true, false):
				has_common_point = has_common_point or point.can_host(LocalAreaSpawnPoint.SpawnKind.COMMON_ENCOUNTER)
			if root.get_node_or_null("%PopulationController") == null or not has_common_point:
				errors.append("SpawnTable requires PopulationController and a compatible common spawn point.")
			root.free()
	return errors


static func validate_world(world: NavigatorWorldData, catalog: GameContentCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var known := {}
	if catalog != null:
		for location: MapLocation in catalog.locations:
			if location == null:
				errors.append("Global catalog contains a null location.")
			else:
				if known.has(location.get_display_id()):
					errors.append("Duplicate global location: %s" % location.get_display_id())
				known[location.get_display_id()] = location
	var seen := {}
	for location: MapLocation in world.locations:
		if location == null:
			errors.append("World map contains a null location.")
			continue
		var id := location.get_display_id()
		if seen.has(id):
			errors.append("Duplicate world map location: %s" % id)
		seen[id] = true
		if catalog != null and (not known.has(id) or known[id] != location):
			errors.append("World map location '%s' must reference the same Resource registered in GameContentCatalog." % id)
		errors.append_array(validate_location(location))
	if not world.initial_location_id.is_empty() and not seen.has(world.initial_location_id):
		errors.append("Initial world location is not registered in this map.")
	return errors
