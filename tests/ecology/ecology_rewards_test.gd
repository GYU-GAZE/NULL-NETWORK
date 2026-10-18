extends NavigatorTestHarness

func run() -> void:
	prepare_campaign("ecology_rewards", 90)
	var encounter := load("res://data/content/combat/1v1.tres") as CombatEncounter
	var reward := (load("res://data/content/combat/rewards/rattildus_reward.tres") as CombatRewardData).duplicate() as CombatRewardData
	reward.base_experience = 500
	var ordinary := reward.duplicate() as CombatRewardData
	ordinary.base_experience = 20
	ordinary.weak_enemy_level_gap = 0
	var purged := {"uid": 10, "level": 1, "hp": 0, "defeated": true, "purged": true, "reward_profile": reward}
	var normal := {"uid": 11, "level": 1, "hp": 0, "defeated": true, "reward_profile": ordinary}
	var records: Array[Dictionary] = [purged, normal]
	var progress: Array[PlayerActionProgressData] = []
	var plan := CombatResolutionService._build_plan(CombatResult.Outcome.VICTORY, encounter, records, progress, CombatTendencyLog.new())
	check(int(plan.experience) == 320, "PURGE must yield floor(500 * 0.2) * 3 plus only the other target's 20 EXP")
	check(plan.module_ids.is_empty() and plan.passive_module_id.is_empty() and plan.items.size() == 1, "PURGE granted a Module/passive/item or suppressed another target's legitimate drop")
	var scan := PlayerActionProgressData.create(encounter.resolution.get_player_action("scan"), purged)
	scan.completed = true
	scan.progress = 100
	scan.selected_reward_id = "heavy_attack"
	progress = [scan]
	plan = CombatResolutionService._build_plan(CombatResult.Outcome.VICTORY, encounter, records, progress, CombatTendencyLog.new())
	check(plan.module_ids == PackedStringArray(["heavy_attack"]), "SCAN before PURGE lost its chosen Module or PURGE added another one")
	var purified := {"uid": 12, "level": 1, "hp": 10, "purified": true, "reward_profile": ordinary}
	var purify := PlayerActionProgressData.create(encounter.resolution.get_player_action("purify"), purified)
	purify.completed = true
	purify.progress = 100
	records = [purified]
	progress = [purify]
	plan = CombatResolutionService._build_plan(CombatResult.Outcome.VICTORY, encounter, records, progress, CombatTendencyLog.new())
	check(plan.passive_module_id == "rattildus_guard", "PURIFY did not select a valid new Installed Passive")
	CampaignState.learn_module("rattildus_guard", false)
	plan = CombatResolutionService._build_plan(CombatResult.Outcome.VICTORY, encounter, records, progress, CombatTendencyLog.new())
	check(plan.passive_module_id.is_empty() and int(plan.experience) == 10, "PURIFY did not use alternative EXP when no new passive remained")
	ordinary.purification_passive_module_ids.clear()
	check(PlayerActionService.validate_assignment(encounter.resolution.get_player_action("purify"), purified.merged({"is_ally": false}), []).is_empty(), "PURIFY with an empty valid passive pool could not use its EXP fallback")
	for outcome: CombatResult.Outcome in [CombatResult.Outcome.ESCAPED, CombatResult.Outcome.CANCELLED]:
		plan = CombatResolutionService._build_plan(outcome, encounter, records, progress, CombatTendencyLog.new())
		check(int(plan.experience) == 0 and plan.module_ids.is_empty() and plan.items.is_empty() and plan.passive_module_id.is_empty(), "Escape/cancellation committed pending Player Action rewards")
	var zone := ContentRegistry.get_ecology_zone("akiba.electric_town")
	for index: int in range(4): EcologyService.apply_operation({"operation_id": "cancel.reduce.%d" % index, "zone_id": zone.ecology_zone_id, "species_line_id": "rattildus", "operation": "PURGE", "source": "protagonist", "formal_result": true})
	var recipe := {"version": 1, "call_id": "fixture.cancel_final_purge", "profile_path": "res://data/content/field/rattildus_field_encounter.tres", "ecology_zone_id": zone.ecology_zone_id, "members": [{"unit_id": "last.signature", "apk_id": "rattildus_init", "level": 2, "reward_path": "res://data/content/combat/rewards/rattildus_reward.tres"}]}
	check(CombatManager.load_encounter(FieldCombatEncounterFactory.create(recipe)), "Could not load final-PURGE cancellation fixture")
	var enemy: Dictionary = CombatManager.enemy_team[0]
	for index: int in range(4): CombatManager.set_player_action(index, "purge", int(enemy.uid))
	CombatManager.execute_cycle(false)
	for index: int in range(4): CombatManager.set_player_module(index, ContentRegistry.get_module("basic_attack"))
	CombatManager.execute_cycle(false)
	check(CombatManager.resolve_encounter(CombatResult.Outcome.VICTORY).has("ECOLOGY_CONFIRMATION_REQUIRED") and not CombatManager.is_resolution_applied(), "Final PURGE bypassed the authority's consent guard")
	CombatManager.confirm_ecological_purge(false)
	check(CombatManager.resolve_encounter(CombatResult.Outcome.VICTORY).is_empty() and EcologyService.population(zone.ecology_zone_id, "rattildus") == 1 and not bool(EcologyService.snapshot(zone.ecology_zone_id).collapsed), "Cancelling PURGE still caused ecological collapse")
	CombatManager.finalize_resolved_encounter()
	finish("ECOLOGY_REWARDS_TEST")
