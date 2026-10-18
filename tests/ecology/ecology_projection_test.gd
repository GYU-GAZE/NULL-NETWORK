extends NavigatorTestHarness

func run() -> void:
	prepare_campaign("ecology_projection")
	var location := ContentRegistry.get_location("akihabara")
	var zone := location.ecology_zone
	var area := location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, location)
	check(await until(func() -> bool: return area.field_navigation.ready), "Ecological field geometry did not prepare")
	var ids := {}
	var positions := {}
	for actor: LocalAreaExeActor in area.get_field_exes():
		ids[actor.field_unit_id] = actor.get_instance_id()
		positions[actor.field_unit_id] = actor.global_position
	check(ids.size() == 4 and EcologyService.population(zone.ecology_zone_id, "rattildus") == 5, "Visible actors were equated with ecological Population Units")
	for index: int in range(3):
		EcologyService.apply_operation({"operation_id": "projection.purge.%d" % index, "zone_id": zone.ecology_zone_id, "species_line_id": "rattildus", "operation": "PURGE", "source": "protagonist", "formal_result": true})
	await settle(0.1)
	check(area.get_field_exes().size() == 2, "Guaranteed spawns bypassed gradual ecological density reduction 5 => 2")
	for actor: LocalAreaExeActor in area.get_field_exes():
		check(actor.get_instance_id() == ids[actor.field_unit_id] and actor.global_position == positions[actor.field_unit_id], "Ecological refresh rebuilt/displaced unaffected surviving actors")
	var catalog := ContentRegistry.catalog.duplicate() as GameContentCatalog
	var independent := EcologyZoneData.new()
	independent.ecology_zone_id = "fixture.local_absence"
	independent.location_ids = PackedStringArray(["fixture.ecology_subarea"])
	independent.presentation = zone.presentation
	var rattildus := EcologySpeciesData.new()
	rattildus.species_line_id = "rattildus"
	rattildus.population_base = 1
	rattildus.population_capacity = 1
	var novire := EcologySpeciesData.new()
	novire.species_line_id = "novire"
	novire.population_base = 2
	novire.population_capacity = 2
	independent.species = [rattildus, novire]
	var other := location.duplicate() as MapLocation
	other.location_id = "fixture.ecology_subarea"
	other.show_on_world_map = false
	other.ecology_zone = independent
	catalog.locations = catalog.locations.duplicate()
	catalog.locations.append(other)
	catalog.ecology_zones = [zone, independent]
	check(ContentRegistry.configure_catalog(catalog).is_empty(), "Independent zone fixture was rejected")
	await settle(0.1)
	var before := area.population_controller.get_population_state()
	EcologyService.apply_operation({"operation_id": "local.absence", "zone_id": independent.ecology_zone_id, "species_line_id": "rattildus", "operation": "PURGE", "source": "protagonist", "formal_result": true})
	await settle(0.1)
	check(not bool(EcologyService.snapshot(independent.ecology_zone_id).collapsed) and EcologyService.population(independent.ecology_zone_id, "rattildus") == 0, "Species absence collapsed a zone with another surviving species")
	check(area.population_controller.get_population_state() == before, "Unrelated zone mutation invalidated this area's projections")
	var second := other.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(second)
	second.setup_local_area(other.local_area, "", Vector2.ZERO, false, {}, other)
	await settle(0.1)
	check(second.get_field_exes().is_empty() and EcologyService.population(zone.ecology_zone_id, "rattildus") == 2, "Zero species reappeared through guarantees or affected another zone")
	var remaining := area.get_field_exes()
	for index: int in range(remaining.size()):
		var actor := remaining[index]
		actor.behavior_profile = actor.behavior_profile.duplicate() as FieldBehaviorProfileData
		actor.behavior_profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE
		actor.behavior_profile.modifiers = []
		actor.behavior_profile.speed = 0
		actor.refresh_field_context()
		actor.global_position = Vector2(500 + index * 48, 700)
		actor.motor.global_position = actor.global_position
	area.player.global_position = remaining[0].global_position - Vector2(0, 22)
	area.set_area_active(true)
	check(area.field_calls.begin(remaining[0]), "Ecologically available main contact was rejected")
	var encounter := await area.field_calls.build_encounter()
	check(encounter != null and encounter.enemy_slots.size() == 2, "Combat Call exceeded the two remaining ecological signatures")
	area.field_calls.cancel(true)
	area.queue_free()
	second.queue_free()
	await get_tree().process_frame
	ContentRegistry.reset_to_default_catalog()
	finish("ECOLOGY_PROJECTION_TEST")
