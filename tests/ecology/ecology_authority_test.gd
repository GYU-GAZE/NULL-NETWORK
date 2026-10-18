extends NavigatorTestHarness

func run() -> void:
	SaveManager.configure_storage_root("user://ecology_authority_%d" % Time.get_ticks_usec())
	check(SaveManager.create_campaign("ecology_authority", CampaignState.SaveMode.SAFE).is_empty(), "Could not create ecological disk campaign")
	prepare_campaign("ecology_authority")
	var catalog := ContentRegistry.catalog.duplicate() as GameContentCatalog
	var a := ContentRegistry.get_ecology_zone("akiba.electric_town")
	var b := EcologyZoneData.new()
	b.ecology_zone_id = "fixture.independent_zone"
	b.location_ids = PackedStringArray(["fixture.only_not_explorable"])
	b.presentation = a.presentation
	var species := EcologySpeciesData.new()
	species.species_line_id = "rattildus"
	species.population_base = 3
	species.population_capacity = 3
	species.weekly_recovery = 0
	b.species = [species]
	catalog.ecology_zones = [a, b]
	check(ContentRegistry.configure_catalog(catalog).is_empty(), "Ecology catalog was rejected")
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 5 and EcologyService.population(b.ecology_zone_id, "rattildus") == 3, "Same species did not have independent authored base populations")
	check(EcologyService.projection_context(a, 2).ecology_limits.rattildus == 2, "Five Population Units cannot project only two visible representatives")
	check(_operation(a, "purge.1", "PURGE"), "Formal PURGE not accepted")
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 4 and EcologyService.population(b.ecology_zone_id, "rattildus") == 3, "PURGE did not remove exactly one unit locally")
	check(not _operation(a, "purge.1", "PURGE"), "Duplicate ecological operation applied")
	for index: int in range(4): _operation(a, "purify.%d" % index, "PURIFY")
	check(EcologyService.resonance(a.ecology_zone_id, "rattildus") == 3 and EcologyService.population(a.ecology_zone_id, "rattildus") == 4, "PURIFY did not cap resonance at three while preserving population")
	check(EcologyService.eligible_variants(a, "rattildus").size() == 3, "Resonance did not unlock the authored compatible Node pool")
	CampaignState.world_state.persistent_objects["field_resolution.legacy_pending"] = {"call_id": "legacy_pending", "location_id": "akihabara", "ecology_requests": [{"operation": "PURGE", "field_unit_id": "legacy.target", "species_line_id": "rattildus", "population_delta": -1}]}
	check(SaveManager.manual_save(), "Pending receipt could not be persisted")
	check(SaveManager.load_campaign("ecology_authority").is_empty(), "Pending receipt could not reload")
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 3, "Persistent Phase 04 receipt was not consumed after reload")
	EcologyService.consume_pending_receipts()
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 3, "Acknowledgement replay duplicated a PURGE")
	_operation(a, "npc.1", "PURGE", "npc")
	_operation(a, "npc.2", "PURGE", "npc")
	check(not _operation(a, "npc.last", "PURGE", "npc") and EcologyService.population(a.ecology_zone_id, "rattildus") == 1, "NPC caused the final collapse")
	check(not _operation(a, "unconfirmed.last", "PURGE"), "Final PURGE bypassed consent")
	check(EcologyService.projection_context(a, 4).ecology_limits.rattildus == 1, "Critical population did not reduce field density")
	# The real calendar reaches the first Monday on game day 5.
	TimeManager.advance_action(24 * 4)
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 3 and EcologyService.resonance(a.ecology_zone_id, "rattildus") == 2, "Micro-Update did not recover 1/5 +2 => 3/5 and decay 3 => 2")
	TimeManager._emit_time_signal()
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 3, "Same weekly boundary applied twice")
	var migration := EcologyMigrationData.new()
	migration.migration_id = "fixture.allowed_migration"
	migration.source_zone_id = a.ecology_zone_id
	migration.species_line_id = "rattildus"
	b.migrations = [migration]
	_operation(b, "b.purge.1", "PURGE")
	_operation(b, "b.purge.2", "PURGE")
	TimeManager.advance_action(24 * 7)
	check(EcologyService.population(b.ecology_zone_id, "rattildus") == 2, "Authored migration did not transfer into an available independent zone")
	# Infestation modifies recovery only through the authored pressure rule.
	while EcologyService.population(a.ecology_zone_id, "rattildus") > 1: _operation(a, "reduce.%d" % EcologyService.population(a.ecology_zone_id, "rattildus"), "PURGE")
	CampaignState.world_state.set_infestation("akihabara", 3)
	b.migrations.clear()
	TimeManager.advance_action(24 * 7)
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 4, "Authored Infestation pressure did not add recovery")
	while EcologyService.population(a.ecology_zone_id, "rattildus") > 1: _operation(a, "last.reduce.%d" % EcologyService.population(a.ecology_zone_id, "rattildus"), "PURGE")
	check(_operation(a, "confirmed.last", "PURGE", "protagonist", true), "Explicitly confirmed final PURGE failed")
	check(bool(EcologyService.snapshot(a.ecology_zone_id).collapsed) and EcologyService.resonance(a.ecology_zone_id, "rattildus") == 0, "Collapse did not persist world state/clear resonance")
	var predator_id := str(CampaignState.world_state.ecology_route.get("predator", {}).get("id", ""))
	check(not predator_id.is_empty(), "First collapse did not register one persistent Predator")
	TimeManager.advance_action(24 * 7)
	check(EcologyService.population(a.ecology_zone_id, "rattildus") == 0 and EcologyService.projection_context(a, 4).ecology_limits.rattildus == 0, "Collapsed zone recovered or allowed ordinary projection")
	check(SaveManager.manual_save() and SaveManager.load_campaign("ecology_authority").is_empty(), "Collapsed world could not save/load")
	check(bool(EcologyService.snapshot(a.ecology_zone_id).collapsed) and CampaignState.world_state.ecology_route.predator.id == predator_id, "Collapse/predator identity changed after load")
	# A second deliberate collapse evolves the same persistent identity.
	b.predator = a.predator
	while EcologyService.population(b.ecology_zone_id, "rattildus") > 1:
		_operation(b, "second.reduce.%d" % EcologyService.population(b.ecology_zone_id, "rattildus"), "PURGE")
	_operation(b, "second.confirmed.last", "PURGE", "protagonist", true)
	check(EcologyService.predator_state().id == predator_id and int(EcologyService.predator_state().collapse_count) == 2 and not (EcologyService.predator_state().assimilated_module_ids as Array).is_empty(), "Second collapse replaced the Predator or failed authored Module assimilation")
	var profile := EcologyService.predator_profile()
	var recipe := {"version": 1, "call_id": "fixture.predator.evolved", "profile_path": profile.encounter_profile.resource_path, "predator_id": predator_id, "members": [{"unit_id": predator_id, "apk_id": profile.apk_id, "level": profile.level, "reward_path": profile.encounter_profile.reward_profile.resource_path, "module_ids": EcologyService.predator_state().assimilated_module_ids}]}
	var evolved := FieldCombatEncounterFactory.create(recipe)
	check(evolved != null and CombatManager.load_encounter(evolved), "Evolved Predator could not use the existing battle runtime")
	check(str((CombatManager.enemy_team[0].modules[0] as ModuleData).module_id) == "heavy_attack", "Authored Predator evolution did not change its actual equipped Module")
	CombatManager.reset_encounter()
	# Real Operator Loss retains the authoritative world and extinction route.
	CampaignState.operator.operator_id = "ecology.origin.operator"
	CampaignState.operator.display_name = "Ecology acceptance"
	CampaignState.set_current_location("akihabara")
	var destroyed_turd := TurdPartnerFactory.create_state()
	check(destroyed_turd != null, "Could not create a valid TURD for world-persistence validation")
	if destroyed_turd != null:
		destroyed_turd.current_hp = 0
		var loss := OperatorLossService.resolve_after_combat(destroyed_turd, "ecology.loss")
		check((loss.errors as PackedStringArray).is_empty() and bool(EcologyService.snapshot(a.ecology_zone_id).collapsed) and EcologyService.predator_state().id == predator_id, "Operator Loss reset ecological world history")
	ContentRegistry.reset_to_default_catalog()
	finish("ECOLOGY_AUTHORITY_TEST")

func _operation(zone: EcologyZoneData, id: String, kind: String, source: String = "protagonist", authorized: bool = false) -> bool:
	return EcologyService.apply_operation({"operation_id": id, "zone_id": zone.ecology_zone_id, "species_line_id": "rattildus", "operation": kind, "source": source, "target_id": id, "formal_result": true, "collapse_authorized": authorized, "provenance": "acceptance.contract"})
