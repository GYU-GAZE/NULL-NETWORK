extends NavigatorTestHarness

func run() -> void:
	SaveManager.configure_storage_root("user://ecology_npc_%d" % Time.get_ticks_usec())
	check(SaveManager.create_campaign("ecology_npc", CampaignState.SaveMode.SAFE).is_empty(), "NPC ecological campaign could not be created")
	prepare_campaign("ecology_npc")
	var zone := ContentRegistry.get_ecology_zone("akiba.electric_town").duplicate(true) as EcologyZoneData
	zone.danger_number_key = "fixture.actual_danger"
	zone.recompile_on_micro_update = false
	var activities: Array[EcologyNPCActivityData] = []
	for operation: EcologyNPCActivityData.Operation in [EcologyNPCActivityData.Operation.PURGE, EcologyNPCActivityData.Operation.PURIFY, EcologyNPCActivityData.Operation.CONTAIN_SWARM, EcologyNPCActivityData.Operation.WORLD_PRESSURE]:
		var activity := EcologyNPCActivityData.new()
		activity.activity_id = "fixture.npc.%d" % operation
		activity.npc_id = "ganbarekun"
		activity.species_line_id = "rattildus"
		activity.operation = operation
		activity.interval_blocks = 2 if operation == EcologyNPCActivityData.Operation.WORLD_PRESSURE else 1
		activity.infestation_delta = -1 if operation == EcologyNPCActivityData.Operation.CONTAIN_SWARM else 0
		activity.danger_delta = 1 if operation == EcologyNPCActivityData.Operation.WORLD_PRESSURE else 0
		activities.append(activity)
	zone.npc_activities = activities
	var catalog := ContentRegistry.catalog.duplicate() as GameContentCatalog
	catalog.ecology_zones = [zone]
	check(ContentRegistry.configure_catalog(catalog).is_empty(), "NPC ecological catalog rejected authored rules")
	EcologyService.ensure_zone(zone)
	GameState.set_number(zone.danger_number_key, 5)
	CampaignState.world_state.set_infestation("akihabara", 5)
	CampaignState.campaign_changed.emit(&"world_infestation")
	TimeManager.advance_action(1)
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 4 and EcologyService.resonance(zone.ecology_zone_id, "rattildus") == 1 and CampaignState.world_state.get_infestation("akihabara") == 4, "NPC PURGE/PURIFY/containment did not process the first canonical temporal boundary")
	TimeManager._emit_time_signal()
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 4 and CampaignState.world_state.get_infestation("akihabara") == 4, "Repeated time signal duplicated NPC effects")
	TimeManager.advance_action(1)
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 3 and GameState.get_number(zone.danger_number_key) == 6, "Authored NPC world pressure did not update its existing Danger key")
	TimeManager.advance_action(10)
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 1 and not bool(EcologyService.snapshot(zone.ecology_zone_id).collapsed), "Abstract NPC simulation caused final collapse")
	check(EcologyService.resonance(zone.ecology_zone_id, "rattildus") == 3 and CampaignState.world_state.get_infestation("akihabara") == 0, "NPC resonance/Infestation exceeded bounds")
	check(SaveManager.manual_save() and SaveManager.load_campaign("ecology_npc").is_empty(), "NPC ecological ledger did not save/load")
	TimeManager._emit_time_signal()
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 1 and EcologyService.resonance(zone.ecology_zone_id, "rattildus") == 3, "Loading rerolled/reapplied committed NPC history")
	zone.npc_activities.clear()
	var protected_saves: Array[bool] = []
	var observe := func(id: String, _species: PackedStringArray, reason: String) -> void:
		if id == zone.ecology_zone_id and reason == "micro_update": protected_saves.append(not EcologyService.can_save_now() and not SaveManager.manual_save())
	EcologyService.zone_changed.connect(observe)
	check(SaveManager.manual_save(), "Pre-weekly save was not stable")
	TimeManager.advance_action(24 * 4)
	check(protected_saves == [true], "Save was not protected during atomic Micro-Update")
	check(int(EcologyService.snapshot(zone.ecology_zone_id).projection_epoch) == 0, "Disabled weekly recompilation still rerolled field generations")
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 3 and EcologyService.resonance(zone.ecology_zone_id, "rattildus") == 2, "Weekly partial recovery/resonance decay failed after NPC activity")
	check(SaveManager.manual_save() and SaveManager.load_campaign("ecology_npc").is_empty(), "Post-weekly save/load failed")
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 3, "Post-weekly load duplicated recovery")
	EcologyService.zone_changed.disconnect(observe)
	var document := CampaignState.export_save_data()
	document.world_state.ecology_zones[zone.ecology_zone_id].species.rattildus.population_current = -1
	check(not CampaignState.validate_save_data(document).is_empty(), "Save validation accepted a negative ecological population")
	document = CampaignState.export_save_data()
	document.world_state.ecology_zones[zone.ecology_zone_id].species.rattildus.purify_resonance = 4
	check(not CampaignState.validate_save_data(document).is_empty(), "Save validation accepted resonance above three")
	ContentRegistry.reset_to_default_catalog()
	finish("ECOLOGY_WEEKLY_NPC_TEST")
