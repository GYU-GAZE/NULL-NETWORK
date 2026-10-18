extends NavigatorTestHarness

func run() -> void:
	prepare_campaign("field_call_contract")
	_test_responses()
	var location := ContentRegistry.get_location("akihabara")
	var area := location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, location)
	check(await until(func() -> bool: return area.field_navigation.ready), "Call test could not prepare production geometry")
	var actors := area.get_field_exes()
	var main := actors[0]
	for index: int in range(actors.size()):
		var actor := actors[index]
		actor.behavior_profile = actor.behavior_profile.duplicate() as FieldBehaviorProfileData
		actor.behavior_profile.speed = 0
		actor.behavior_profile.behavior = FieldBehaviorProfileData.Behavior.SOLITARY
		actor.refresh_field_context()
		_place(area, actor, Vector2(400 + index * 45, 700))
	area.player.global_position = main.global_position - Vector2(0, 22)
	area.set_area_active(true)
	check(area.field_calls.begin(main), "Valid main interaction did not acquire call ownership")
	check(not area.field_calls.begin(main), "A duplicate contact acquired another call")
	var solo := await area.field_calls.build_encounter()
	check(solo != null and solo.enemy_slots.size() == 1 and solo.enemy_slots[0].field_unit_id == main.population_unit_id, "No-response call was not an individual 1v1 with the main EXE")
	check(solo.enemy_slots[0].participant_source == CombatSlotData.ParticipantSource.CATALOG_APK, "Dynamic encounter bypassed catalog APK progression")
	area.field_calls.cancel()
	# A real fifth actor is eligible, but the formation still cannot exceed four.
	var extra := (load("res://apps/navigator/local_area/actors/local_area_exe_actor.tscn") as PackedScene).instantiate() as LocalAreaExeActor
	extra.configure_population_actor("field_test.extra", main.spawn_entry)
	area.get_node("PopulationController/PopulationActors").add_child(extra)
	extra.bind_field(area, 123)
	actors.append(extra)
	for index: int in range(actors.size()):
		var actor := actors[index]
		actor.behavior_profile = actor.behavior_profile.duplicate() as FieldBehaviorProfileData
		actor.behavior_profile.speed = 0
		actor.behavior_profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE
		actor.refresh_field_context()
		_place(area, actor, Vector2(400 + index * 35, 700))
	await get_tree().physics_frame
	area.field_navigation.rebuild(area)
	area.player.global_position = main.global_position - Vector2(0, 22)
	check(area.field_calls.begin(main), "Multiple call could not begin")
	var multiple := await area.field_calls.build_encounter()
	check(multiple != null and multiple.enemy_slots.size() == 4, "Eligible visible responders did not produce a four-enemy formation")
	check(multiple.enemy_slots[0].field_unit_id == main.population_unit_id, "Responder displaced the main EXE")
	var original := FileAccess.get_file_as_bytes("res://data/content/combat/3v1.tres")
	check(CombatManager.load_encounter(multiple), "Existing CombatManager rejected the dynamic field formation")
	check(CombatManager.enemy_team.filter(func(value: Variant) -> bool: return value != null).size() == 4, "CATALOG_APK slots did not instantiate four real combatants")
	var saved := CombatManager.export_save_data()
	check(CombatManager.validate_save_data(saved).is_empty(), "Dynamic formation save recipe failed validation")
	var expected_id := str(CombatManager.enemy_team[0].field_unit_id)
	CombatManager.reset_encounter()
	CombatManager.import_save_data(saved)
	check(CombatManager.is_encounter_active() and str(CombatManager.enemy_team[0].field_unit_id) == expected_id, "Combat load lost individual field identity")
	check(CombatManager.enemy_team[0].icon != null, "Catalog APK combat icon disappeared on load")
	var corrupt := saved.duplicate(true)
	corrupt.field_formation.members[1].unit_id = corrupt.field_formation.members[0].unit_id
	check(not CombatManager.validate_save_data(corrupt).is_empty(), "Duplicate field identities were accepted in a saved formation")
	CombatManager.reset_encounter()
	check(FileAccess.get_file_as_bytes("res://data/content/combat/3v1.tres") == original, "Runtime formation mutated an authored encounter on disk")
	# Individual reconciliation: only the defeated participant is spent. This
	# is a coordinator contract fixture; the UI suite executes real terminal fights.
	var members: Array = multiple.field_formation.members
	var defeated_id := str(members[1].unit_id)
	area.field_calls.apply_result(CombatResult.create(CombatResult.Outcome.DEFEAT, multiple.encounter_id, {"field_units": [{"unit_id": defeated_id, "hp": 0.0, "max_hp": 10.0, "defeated": true}]}))
	check(not (area.find_interactable_by_id(defeated_id) as LocalAreaExeActor).available, "Defeated participant was not individually spent")
	check(main.available and extra.available, "Resolving one participant removed healthy/unselected EXEs")
	var all_ids := actors.map(func(value: LocalAreaExeActor) -> String: return value.population_unit_id)
	area.population_controller.sync_population_state()
	area.population_controller.populate(location)
	check(area.find_interactable_by_id(defeated_id) == null, "Resolved field unit respawned in the same generation")
	check(area.get_field_exes().size() == 3, "Unselected extra was kept as an unregistered population duplicate")
	# Out-of-range real actors cannot answer, even with aggressive profiles.
	var remaining := area.get_field_exes()
	main = remaining[0]
	for actor: LocalAreaExeActor in remaining:
		_place(area, actor, Vector2(1300, 900) if actor != main else Vector2(400, 700))
	area.player.global_position = main.global_position - Vector2(0, 22)
	check(area.field_calls.begin(main), "Isolated call did not begin")
	var isolated := await area.field_calls.build_encounter()
	check(isolated != null and isolated.enemy_slots.size() == 1, "Far-away responders joined a local call")
	area.field_calls.cancel(true)
	area.queue_free()
	await get_tree().process_frame
	finish("FIELD_COMBAT_CALL_TEST")

func _test_responses() -> void:
	var profile := FieldBehaviorProfileData.new()
	profile.profile_id = "test.responses"
	var expected := [1, 0, 4, 3, 3, 5, 0, 1, 4, 0, 0, 1]
	var context := {"distance": 40.0, "same_species": true, "caller_in_territory": true, "player_hp_fraction": 0.1}
	for behavior: int in range(12):
		var result := FieldResponseEvaluator.evaluate(profile, behavior, context, 314)
		check(int(result.response) == expected[behavior], "Behavior %s returned the wrong individual call decision" % FieldBehaviorProfileData.Behavior.keys()[behavior])
	var rule := FieldCallResponseRule.new()
	rule.response = FieldCallResponseRule.Response.HESITATE
	rule.join_after_hesitation = true
	rule.minimum_danger = 2
	rule.minimum_infestation = 3
	rule.variant_node_ids = PackedStringArray(["alpha"])
	profile.response_rules = [rule]
	check(int(FieldResponseEvaluator.evaluate(profile, 0, context, 1).response) == FieldCallResponseRule.Response.IGNORE, "Missing Danger/Variant authorities were fabricated to satisfy a response rule")
	context.merge({"danger": 2, "infestation": 3, "variant_node_id": "alpha"})
	var hesitant := FieldResponseEvaluator.evaluate(profile, 0, context, 1)
	check(int(hesitant.response) == FieldCallResponseRule.Response.HESITATE and bool(hesitant.join) and float(hesitant.delay) > 0, "Authored conditional hesitation was not respected")
	check(hesitant == FieldResponseEvaluator.evaluate(profile, 0, context, 1), "Seeded response changed on reevaluation")

func _place(area: NavigatorLocalAreaScene, actor: LocalAreaExeActor, position: Vector2) -> void:
	actor.global_position = area.to_global(position)
	actor.motor.global_position = actor.global_position
	actor.motor.home = position
	actor.motor._path_left = 0
