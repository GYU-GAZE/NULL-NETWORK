extends NavigatorTestHarness


func run() -> void:
	prepare_campaign("navigator_population_acceptance")
	var location := ContentRegistry.get_location("akihabara")
	var area := location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	check(area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, location), "Production area could not populate")
	var population := area.population_controller
	var npc := population.get_population_actor("akihabara.npc.ganbarekun.0") as LocalAreaNPCActor
	check(npc != null and npc.npc == ContentRegistry.get_npc("ganbarekun"), "Scheduled NPC was not projected using NPCData")
	var first := population.get_population_state()
	var common_id := str((first.get("common_slots", []) as Array)[0])
	var exe := population.get_population_actor(common_id) as LocalAreaExeActor
	check(exe != null, "Production SpawnTable did not create an EXE")
	var exe_instance := exe.get_instance_id() if exe != null else 0
	var npc_instance := npc.get_instance_id() if npc != null else 0
	population.populate(location)
	check(population.get_population_actor(common_id).get_instance_id() == exe_instance, "Unchanged refresh recreated the EXE")
	check(population.get_population_actor("akihabara.npc.ganbarekun.0").get_instance_id() == npc_instance, "Unchanged refresh recreated the NPC")
	GameState.set_flag("test.navigator.irrelevant", true)
	await settle(0.05)
	check(population.get_population_actor(common_id).get_instance_id() == exe_instance, "Unrelated state recreated the EXE")
	TimeManager.advance_action(1)
	await settle(0.05)
	check(population.get_population_actor(common_id).get_instance_id() == exe_instance, "Same-period block change rerolled the whole population")
	if exe != null:
		exe.apply_combat_result(CombatResult.create(CombatResult.Outcome.VICTORY))
	population.populate(location)
	check(population.get_population_actor(common_id) == null, "Resolved EXE immediately respawned")
	var saved_world := CampaignState.get_location_population_state("akihabara")
	var saved_actor_ids := _ids(saved_world)
	area.queue_free()
	await get_tree().process_frame
	area = location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, location)
	population = area.population_controller
	check(population.get_population_actor(common_id) == null and _ids(population.get_population_state()) == saved_actor_ids, "Returning rerolled a spent generation")
	TimeManager.advance_action(11)
	await settle(0.08)
	check(population.get_population_actor("akihabara.npc.ganbarekun.0") == null, "NPC remained physically present in its offline NIGHT routine")
	check(str(population.get_population_state().generation_key) != str(saved_world.generation_key), "Period refresh policy did not advance generation")
	area.queue_free()
	await get_tree().process_frame
	# Conditions determine eligibility; refresh policy determines generation.
	var conditional := location.duplicate() as MapLocation
	conditional.location_id = "population_conditions"
	conditional.spawn_table = location.spawn_table.duplicate() as SpawnTable
	conditional.spawn_table.entries = []
	var entry := location.spawn_table.entries[0].duplicate() as SpawnEntry
	var flag := FlagConditionData.new()
	flag.flag_name = "test.navigator.spawn_eligible"
	entry.conditions = flag
	conditional.spawn_table.entries.append(entry)
	GameState.set_flag(flag.flag_name, false)
	area = location.local_area.area_scene.instantiate() as NavigatorLocalAreaScene
	add_child(area)
	area.setup_local_area(location.local_area, "", Vector2.ZERO, false, {}, conditional)
	population = area.population_controller
	check(_common_count(population) == 0, "Ineligible EXE was physically spawned")
	GameState.set_flag(flag.flag_name, true)
	await settle(0.08)
	check(_common_count(population) == 1, "Flag change did not add newly eligible EXE")
	var eligible_id := str(population.get_population_state().common_slots[0])
	GameState.set_flag(flag.flag_name, false)
	await settle(0.08)
	check(population.get_population_actor(eligible_id) == null, "EXE remained visible outside its availability condition")
	GameState.set_flag(flag.flag_name, true)
	await settle(0.08)
	check(_common_count(population) == 1, "Restoring eligibility duplicated the EXE")
	conditional.spawn_table.refresh_policy = SpawnTable.RefreshPolicy.ACTION_BLOCK
	population.populate(conditional)
	var block_actor := population.get_population_actor(str(population.get_population_state().common_slots[0])) as LocalAreaExeActor
	block_actor.apply_combat_result(CombatResult.create(CombatResult.Outcome.VICTORY))
	TimeManager.advance_action(1)
	await settle(0.08)
	var next_block_actor := population.get_population_actor(str(population.get_population_state().common_slots[0])) as LocalAreaExeActor
	check(next_block_actor != null and next_block_actor.can_interact(), "Explicit action-block generation retained the previous generation's resolved runtime state")
	area.queue_free()
	await get_tree().process_frame
	await _test_npc_dialogue()
	finish("NAVIGATOR_POPULATION_TEST")


func _test_npc_dialogue() -> void:
	prepare_campaign("npc_physical_dialogue")
	var original: GameContentCatalog = ContentRegistry.catalog
	var catalog := original.duplicate() as GameContentCatalog
	var npcs := original.get("npc_catalog").duplicate() as NPCCatalog
	npcs.npcs = npcs.npcs.duplicate()
	var npc := npcs.npcs[0].duplicate() as NPCData
	npc.default_dialogue_id = "test.physical_npc"
	npcs.npcs[0] = npc
	catalog.set("npc_catalog", npcs)
	var dialogue := DialogueData.new()
	dialogue.dialogue_id = npc.default_dialogue_id
	dialogue.initial_node_id = "hello"
	var speaker := DialogueSpeakerData.new()
	speaker.speaker_id = "npc"
	speaker.display_name = npc.get_display_name()
	dialogue.speakers.assign([speaker])
	var node := DialogueNodeData.new()
	node.node_id = "hello"
	node.speaker_id = "npc"
	node.text = "Physical NPC dialogue fixture."
	dialogue.nodes.assign([node])
	catalog.dialogues = catalog.dialogues.duplicate()
	catalog.dialogues.append(dialogue)
	check(ContentRegistry.configure_catalog(catalog).is_empty(), "Physical NPC fixture catalog is invalid")
	var navigator := (load("res://apps/navigator/app_navigator.tscn") as PackedScene).instantiate() as NavigatorApp
	add_child(navigator)
	GlobalSignals.workspace_activated.emit("navigator")
	check(navigator._enter_location(ContentRegistry.get_location("akihabara")), "Physical NPC test could not open its area")
	await settle(0.1)
	var area := navigator.local_area_view.get_current_area_instance()
	var actor := area.population_controller.get_population_actor("akihabara.npc.ganbarekun.0") as LocalAreaNPCActor
	check(actor != null and await interact(area, actor), "Player sensor could not interact with the NPC")
	check(DialogueManager.is_dialogue_active() and navigator._current_mode == NavigatorApp.NavigatorMode.DIALOGUE, "Physical NPC did not start its configured DialogueData")
	await capture("npc_dialogue")
	for attempt: int in range(4):
		navigator.dialogue_player.try_advance_from_navigator_input()
		await settle(0.03)
	check(not DialogueManager.is_dialogue_active() and navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA, "NPC dialogue did not return to the previous local area")
	navigator.queue_free()
	await get_tree().process_frame
	ContentRegistry.configure_catalog(original)


func _ids(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for actor: Dictionary in state.get("actors", []):
		result.append(str(actor.actor_id))
	return result


func _common_count(population: LocalAreaPopulationController) -> int:
	var count := 0
	for child: Node in population.get_node(population.population_actors_path).get_children():
		if child is LocalAreaExeActor:
			count += 1
	return count
