extends NavigatorTestHarness


func run() -> void:
	prepare_campaign("map_contract_acceptance")
	var original: GameContentCatalog = ContentRegistry.catalog
	var location := ContentRegistry.get_location("akihabara").duplicate() as MapLocation
	location.location_id = "test_map_contract"
	location.initially_discovered = false
	location.unlocked_by_default = false
	location.locked_message = "Membership required"
	var unlock := FlagConditionData.new()
	unlock.flag_name = "test.navigator.unlock"
	location.unlock_conditions = unlock
	var available := NumberConditionData.new()
	available.number_name = "test.navigator.access"
	available.minimum_value = 5
	location.availability_conditions = available
	location.required_time_periods.assign(["NIGHT"])
	GameState.set_flag(unlock.flag_name, false)
	GameState.set_number(available.number_name, 0)
	var catalog := original.duplicate() as GameContentCatalog
	catalog.locations = catalog.locations.duplicate()
	catalog.locations.append(location)
	check(ContentRegistry.configure_catalog(catalog).is_empty(), "Map contract fixture was not registered")
	var state := NavigatorLocationStateResolver.resolve(location)
	check(not state.is_discovered and not state.should_show and not state.can_enter(), "Unknown location is visible/accessible")
	check(LocationDiscoveryService.discover(location.location_id), "Registered location discovery failed")
	state = NavigatorLocationStateResolver.resolve(location)
	check(state.is_discovered and state.should_show and not state.is_progression_unlocked, "Discovery bypassed an explicit unlock restriction")
	check(state.can_select() and not state.can_enter() and state.availability_message == location.locked_message, "Locked marker cannot explain its authored restriction")
	NavigatorLocationStateResolver.mark_announced(location)
	var world := NavigatorWorldData.new()
	world.map_logical_size = Vector2i(1200, 800)
	world.locations.assign([location])
	var view := (load("res://apps/navigator/world_map/navigator_world_map_view.tscn") as PackedScene).instantiate() as NavigatorWorldMapView
	view.world_data = world
	view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(600, 400)
	add_child(view)
	await settle(0.1)
	var marker := view._markers_by_location_id[location.location_id] as NavigatorLocationMarker
	var marker_id := marker.get_instance_id()
	marker.pressed.emit()
	check(view.get_selected_location() == location and view.enter_area_button.disabled and view.enter_area_button.text == location.locked_message, "Locked marker UI permits impossible travel or hides its reason")
	GameState.set_flag(unlock.flag_name, true)
	await settle(0.08)
	state = NavigatorLocationStateResolver.resolve(location)
	check(state.is_progression_unlocked and not state.is_available_now and view.enter_area_button.disabled, "Progression unlock ignored temporal availability")
	TimeManager.advance_action(12)
	GameState.set_number(available.number_name, 5)
	await settle(0.1)
	state = NavigatorLocationStateResolver.resolve(location)
	check(state.can_enter() and not view.enter_area_button.disabled, "Relevant time/number changes did not enable travel reactively")
	check(marker.get_instance_id() == marker_id, "Map state update recreated its marker")
	var runtime_id := marker._runtime_state.get_instance_id()
	GameState.set_flag("test.navigator.unrelated", true)
	await settle(0.05)
	check(marker._runtime_state.get_instance_id() == runtime_id, "Unrelated flag reevaluated map conditions")
	for extent: Vector2 in [Vector2(450, 300), Vector2(800, 480), Vector2(601, 401)]:
		view.size = extent
		view.set_pan_normalized(Vector2(0.3, 0.7))
		await settle(0.05)
		check(view.map_content.position == view.map_content.position.round() and marker.position == marker.position.round(), "Map resize/pan introduced subpixels")
		var saved_pan := view.get_pan_normalized()
		view.deactivate()
		view.activate()
		check(view.get_pan_normalized().distance_to(saved_pan) < 0.01, "Changing app activation lost map pan")
	var invalid := location.duplicate() as MapLocation
	invalid.local_area = location.local_area.duplicate() as LocalAreaData
	invalid.local_area.default_entry_id = "missing"
	check(not NavigatorLocationStateResolver.resolve(invalid).can_enter(), "Map can confirm an area with a nonexistent entry point")
	var reference := MapLocation.new()
	reference.location_id = "narrative_only"
	reference.location_name = "Narrative reference"
	reference.show_on_world_map = false
	check(reference.validate_data().is_empty(), "Narrative-only location was forced to provide a map")
	view.queue_free()
	await get_tree().process_frame
	ContentRegistry.configure_catalog(original)
	finish("NAVIGATOR_MAP_CONTRACT_TEST")
