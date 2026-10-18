extends EcologyIntegrationHarness

func run() -> void:
	seed(5125)
	await boot("ecology_collapse")
	var zone := area.map_location.ecology_zone
	await capture("ecology_healthy_field")
	var actors := configure_call_actors(false)
	await request_fight(actors[0])
	await complete_action("purge", CombatManager.enemy_team[0])
	await win_current_fight()
	check(EcologyService.population(zone.ecology_zone_id, "rattildus") == 4, "First real field PURGE did not remove one ecological signature")
	check((CombatManager.get_result_metadata().get("module_ids", []) as Array).is_empty() and (CombatManager.get_result_metadata().get("items", []) as Array).is_empty(), "PURGE granted conventional extraction/drops")
	await return_from_fight()
	await next_day()
	actors = configure_call_actors(true)
	check(actors.size() == 4, "Reduced 4/5 ecology did not support a legitimate four-member call")
	await request_fight(actors[0])
	var enemies := CombatManager.enemy_team.duplicate()
	for enemy: Variant in enemies:
		if enemy is Dictionary: await complete_action("purge", enemy)
	var initial_exp := CampaignState.partner.current_exp
	var initial_time := TimeManager.get_total_action_index()
	if DisplayServer.get_name() != "headless":
		KubuDisplaySetting.set_windowed_size(Vector2i(1280, 720))
		await settle(0.1)
	# Drive real Modules via the UI. This terminal fight must stop at consent.
	for index: int in range(4): CombatManager.set_player_module(index, ContentRegistry.get_module("basic_attack"))
	for cycle: int in range(6):
		if CombatManager.is_awaiting_resolution(): break
		navigator.combat_app.execute_btn.pressed.emit()
		check(await until(func() -> bool: return not navigator.combat_app.execute_btn.disabled or CombatManager.is_awaiting_resolution(), 15), "Final PURGE timeline did not settle")
	check(await until(func() -> bool: return is_instance_valid(navigator.combat_app.ecology_confirmation_dialog) and navigator.combat_app.ecology_confirmation_dialog.visible, 15), "Simultaneous final PURGEs bypassed the mandatory warning")
	check(not CombatManager.is_resolution_applied() and EcologyService.population(zone.ecology_zone_id, "rattildus") == 4 and CampaignState.partner.current_exp == initial_exp and TimeManager.get_total_action_index() == initial_time, "Unconfirmed collapse committed ecology/rewards/time")
	check(navigator.combat_app.ecology_confirmation_dialog.size.x <= get_viewport().get_visible_rect().size.x, "Collapse confirmation exceeds the 2x viewport")
	await capture("ecology_collapse_warning_context")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		navigator.combat_app.ecology_confirmation_dialog.get_texture().get_image().save_png(capture_directory.path_join("ecology_collapse_warning.png"))
	check(SaveManager.manual_save(), "Consent boundary could not save")
	check(SaveManager.load_campaign("ecology_collapse").is_empty(), "Consent boundary could not load")
	await settle(0.2)
	area = navigator.local_area_view.get_current_area_instance()
	check(await until(func() -> bool: return is_instance_valid(navigator.combat_app.ecology_confirmation_dialog) and navigator.combat_app.ecology_confirmation_dialog.visible), "Reload treated an unconfirmed warning as consent")
	if not is_instance_valid(navigator.combat_app.ecology_confirmation_dialog):
		finish("ECOLOGY_COLLAPSE_PREDATOR_TEST")
		return
	navigator.combat_app.ecology_confirmation_dialog.get_ok_button().pressed.emit()
	check(await until(func() -> bool: return CombatManager.is_resolution_applied()), "Explicit final PURGE consent did not resolve the battle")
	check(bool(EcologyService.snapshot(zone.ecology_zone_id).collapsed) and EcologyService.population(zone.ecology_zone_id, "rattildus") == 0, "Confirmed simultaneous PURGEs did not collapse the zone")
	var predator_id := str(EcologyService.predator_state().get("id", ""))
	check(not predator_id.is_empty(), "First collapse did not activate the persistent Predator")
	# Saving after formal resolution must preserve physical tombstones too.
	check(SaveManager.manual_save() and SaveManager.load_campaign("ecology_collapse").is_empty(), "Post-resolution ecological checkpoint could not restore")
	await settle(0.2)
	await return_from_fight()
	check(TimeManager.get_total_action_index() == initial_time + 1 and ordinary_exes().is_empty(), "Collapsed field respawned ordinary fauna or charged the wrong cost")
	check(await until(func() -> bool: return is_instance_valid(area.ecology_projection.predator)), "Predator was not physically projected into the area")
	var predator := area.ecology_projection.predator
	var before := predator.global_position
	await settle(0.25)
	check(predator.global_position.distance_to(before) > 2 and predator.motor.state == FieldEXEMotor.State.CHASING, "Predator did not pursue using real field physics")
	await capture("ecology_predator_chasing")
	Input.action_press("local_area_move_left")
	var player_before := area.player.global_position
	await settle(0.4)
	Input.action_release("local_area_move_left")
	check(area.player.global_position.distance_to(player_before) > 5 and not CombatManager.is_encounter_active(), "Player could not evade the Predator through physical movement")
	await capture("ecology_predator_evasion")
	# Real automatic contact invokes the free forced policy.
	position_actor(predator, area.to_local(area.player.global_position) + Vector2(20, 0))
	check(await until(func() -> bool: return CombatManager.is_encounter_active() and navigator.can_save_now()), "Predator contact did not trigger forced combat")
	check(TimeManager.get_total_action_index() == initial_time + 1, "Forced Predator contact charged time")
	await capture("ecology_predator_encounter")
	for attempt: int in range(100):
		if navigator.combat_app.resolution_panel.visible: break
		navigator.combat_app.run_away_btn.pressed.emit()
		await get_tree().process_frame
	await return_from_fight()
	check(bool(EcologyService.snapshot(zone.ecology_zone_id).collapsed) and EcologyService.predator_state().id == predator_id and EcologyService.predator_state().status == "ACTIVE", "Escape restored ecology or replaced/deactivated the Predator")
	check(TimeManager.get_total_action_index() == initial_time + 1, "Predator escape cost time")
	predator = area.ecology_projection.predator
	var inventory := CampaignState.inventory.to_save_data()
	var modules := CampaignState.known_module_ids.duplicate()
	var experience := CampaignState.partner.current_exp
	await request_fight(predator)
	await win_current_fight()
	check(int(CombatManager.get_result_metadata().experience) == 0 and CampaignState.partner.current_exp == experience and CampaignState.inventory.to_save_data() == inventory and CampaignState.known_module_ids == modules, "Predator became an EXP/Module/item farm")
	await return_from_fight()
	check(EcologyService.predator_state().status == "RECOMPILING" and bool(EcologyService.snapshot(zone.ecology_zone_id).collapsed), "Predator victory restored ecology or lost recompilation state")
	await capture("ecology_collapsed_after_predator")
	check(SaveManager.manual_save() and SaveManager.load_campaign("ecology_collapse").is_empty(), "Predator recompilation did not survive save/load")
	await settle(0.1)
	area = navigator.local_area_view.get_current_area_instance()
	if DisplayServer.get_name() != "headless":
		KubuDisplaySetting.set_windowed_size(Vector2i(1280, 720))
		await settle(0.15)
		check(get_window().content_scale_factor == 2.0, "Ecological presentation lost fixed 2x scaling")
		await capture("ecology_collapsed_1280")
	await dispose()
	finish("ECOLOGY_COLLAPSE_PREDATOR_TEST")
