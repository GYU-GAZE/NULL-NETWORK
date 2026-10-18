extends FieldIntegrationHarness

func run() -> void:
	seed(722)
	await boot("field_actions_aggro")
	var actor := area.get_field_exes()[0]
	await _test_actions(actor)
	# Occupation is the existing authority that can deny all voluntary hours at
	# an occupied block. This controlled Operator fixture uses its real schedule.
	CampaignState.operator.operator_id = "qa.field.occupied"
	CampaignState.operator.profile.first_name = "Field"
	CampaignState.operator.profile.last_name = "QA"
	CampaignState.operator.occupation_id = "high_school_student"
	TimeManager.current_action_block = 2
	check(TimeManager.current_weekday_index in [1, 2, 3, 4, 5], "Occupied-hours fixture is not on a school weekday")
	var profile := actor.encounter_profile
	check(not ActivityManager.create_preview(profile.voluntary_activity, "navigator").can_start, "Actual occupation schedule did not deny voluntary combat during occupied hours")
	check(ActivityManager.create_preview(profile.forced_activity, "navigator").can_start, "Forced-free environmental policy was incorrectly blocked by occupied hours")
	var actors := configure_call_actors(false)
	actor = actors[0]
	for index: int in range(1, actors.size()):
		position_actor(actors[index], Vector2(1300 + index * 50, 800))
	actor.behavior_profile.behavior = FieldBehaviorProfileData.Behavior.AGGRESSIVE
	actor.behavior_profile.speed = 100
	actor.behavior_profile.perception_radius = 180
	actor.refresh_field_context()
	position_actor(actor, Vector2(500, 700))
	area.player.global_position = area.to_global(Vector2(600, 700))
	GlobalSignals.workspace_activated.emit("navigator")
	var initial := TimeManager.get_total_action_index()
	var starts: Array[String] = []
	var observe := func(transaction: String, _activity: String, source: String, _request: String) -> void:
		if source == "navigator":
			starts.append(transaction)
	ActivityManager.activity_started.connect(observe)
	check(await until(func() -> bool: return navigator.combat_app.is_encounter_active() and navigator.can_save_now(), 10), "Real aggressive contact did not start forced-free combat during occupied hours")
	check(not confirmation.visible and starts.size() == 1, "Environmental contact opened duplicate activities or an unintended paid confirmation")
	check(TimeManager.get_total_action_index() == initial and int(ActivityManager.get_active_transaction(navigator._active_combat_transaction_id).get("action_cost", -1)) == 0, "Forced contact charged additional time")
	var denied := await TimeManager.advance_development_hours(1)
	check(not bool(denied.ok), "QA time advanced during combat")
	for attempt: int in range(100):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.run_away_btn.pressed.emit()
		await get_tree().process_frame
	check(CombatManager.get_pending_outcome() == CombatResult.Outcome.ESCAPED, "Forced contact could not reach its Run Away boundary")
	await return_from_fight()
	await settle(0.7)
	check(TimeManager.get_total_action_index() == initial and starts.size() == 1 and not CombatManager.is_encounter_active(), "Forced escape charged time or immediately reentered aggro")
	check(ActivityManager.export_save_data().transactions.is_empty(), "Forced encounter left an orphan activity transaction")
	# Alternative authored policy offers voluntary combat. At this occupied
	# hour it must decline and release contact, rather than looping or charging.
	actor.encounter_profile = actor.encounter_profile.duplicate() as FieldEncounterProfileData
	actor.encounter_profile.aggro_policy = FieldEncounterProfileData.AggroPolicy.OFFER_VOLUNTARY
	actor.motor.grace_seconds = 0
	actor.motor.needs_separation = false
	area.player.global_position = actor.global_position - Vector2(0, 20)
	actor.request_field_contact()
	await settle(0.2)
	check(not CombatManager.is_encounter_active() and not area.field_calls.busy and not ActivityManager.has_pending_requests(), "Denied voluntary aggro policy kept an orphan contact/confirmation")
	check(TimeManager.get_total_action_index() == initial and starts.size() == 1, "Denied optional contact charged time or started an activity")
	actor.encounter_profile.aggro_policy = FieldEncounterProfileData.AggroPolicy.DISABLED
	actor._contact_queued = false
	actor.request_field_contact()
	await settle(0.05)
	check(not actor._contact_queued and starts.size() == 1, "Disabled aggro policy still emitted automatic contact")
	ActivityManager.activity_started.disconnect(observe)
	CampaignState.operator.reset()
	await dispose()
	finish("FIELD_ACTIONS_AGGRO_TEST")

func _test_actions(actor: LocalAreaExeActor) -> void:
	var original_id := actor.population_unit_id
	for action: String in ["scan", "purge", "tame"]:
		CombatManager.reset_encounter()
		var partner := APKProgressionService.create_partner_state("novire_init", "Field action acceptance", 0, 0)
		partner.level = 90
		partner.current_exp = APKProgressionService.get_total_exp_for_level(90)
		partner.allocation_points = 89
		partner.current_hp = int(APKProgressionService.calculate_partner_stats(partner).get("max_hp", 1))
		CampaignState.set_partner_state(partner)
		var recipe := {"version": 1, "call_id": "field.action." + action, "profile_path": actor.encounter_profile.resource_path, "location_id": "akihabara", "members": [{"unit_id": original_id, "apk_id": actor.environmental_apk.apk_id, "level": 2, "reward_path": actor.encounter_profile.reward_profile.resource_path}]}
		var encounter := FieldCombatEncounterFactory.create(recipe)
		check(encounter != null and CombatManager.load_encounter(encounter), "Field action fixture could not use the existing runtime")
		var enemy: Dictionary = CombatManager.enemy_team[0]
		check(str(enemy.get("field_unit_id", "")) == original_id, "Player Action target lost its individual field identity")
		for index: int in range(4):
			check(CombatManager.set_player_action(index, action, int(enemy.uid)).is_empty(), "Existing Player Action rejected a dynamic catalog target")
		CombatManager.execute_cycle(false)
		var progress := PlayerActionService.get_progress(CombatManager.player_action_progress, action, int(enemy.uid))
		check(progress != null and progress.completed, "Field %s did not complete through timeline Player Actions" % action)
		if action == "scan":
			check(CombatManager.select_player_action_reward("heavy_attack").is_empty(), "SCAN could not select an active Module from field reward data")
		if action != "tame":
			for index: int in range(4):
				CombatManager.set_player_module(index, ContentRegistry.get_module("basic_attack"))
			for cycle: int in range(3):
				if CombatManager.is_awaiting_resolution():
					break
				CombatManager.execute_cycle(false)
		check(CombatManager.is_awaiting_resolution() and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY, "Field action fight did not reach real victory")
		check(CombatManager.resolve_encounter(CombatResult.Outcome.VICTORY).is_empty(), "Field action could not commit its existing resolution contract")
		var metadata := CombatManager.get_result_metadata()
		var units: Array = metadata.get("field_units", [])
		check(units.size() == 1 and str(units[0].unit_id) == original_id, "Field resolution did not preserve per-unit Player Action results")
		if action == "scan":
			check(CampaignState.known_module_ids.has("heavy_attack"), "Field SCAN did not grant the selected Module")
		elif action == "purge":
			check(bool(units[0].purged) and int(metadata.get("experience", 0)) >= 30, "Field PURGE lost its extraction/EXP contract")
		else:
			check(bool(units[0].tamed) and CampaignState.partner.apk_id == actor.environmental_apk.apk_id, "Field TAME did not adopt the actual catalog APK")
		var inventory := CampaignState.inventory.to_save_data()
		check(CombatManager.resolve_encounter(CombatResult.Outcome.VICTORY).is_empty() and CampaignState.inventory.to_save_data() == inventory, "Field resolution duplicated rewards")
		CombatManager.finalize_resolved_encounter()
	# Restore the test partner before exercising a real hostile contact.
	var partner := APKProgressionService.create_partner_state("novire_init", "Field aggro acceptance", 0, 0)
	partner.level = 90
	partner.current_exp = APKProgressionService.get_total_exp_for_level(90)
	partner.current_hp = int(APKProgressionService.calculate_partner_stats(partner).get("max_hp", 1))
	CampaignState.set_partner_state(partner)
	CombatManager.reset_encounter()
