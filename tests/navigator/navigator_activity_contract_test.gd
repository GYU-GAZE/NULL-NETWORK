extends NavigatorTestHarness


func run() -> void:
	seed(312)
	SaveManager.configure_storage_root("user://navigator_activity_acceptance")
	check(SaveManager.create_campaign("navigator_activity", CampaignState.SaveMode.SAFE).is_empty(), "Could not create activity campaign")
	prepare_campaign("navigator_activity", 90)
	var navigator := (load("res://apps/navigator/app_navigator.tscn") as PackedScene).instantiate() as NavigatorApp
	add_child(navigator)
	GlobalSignals.workspace_activated.emit("navigator")
	var confirmation := (load("res://systems/ui/activity_confirmation_dialog.tscn") as PackedScene).instantiate() as ActivityConfirmationDialog
	add_child(confirmation)
	await settle(0.1)
	var location := ContentRegistry.get_location("akihabara")
	navigator.world_map_view.select_location_by_id(location.location_id)
	navigator.world_map_view.enter_area_button.pressed.emit()
	await until(func() -> bool: return confirmation.visible)
	confirmation.confirm_button.pressed.emit()
	check(await until(func() -> bool: return not navigator._travel_pending and navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA), "Travel did not complete")
	var initial := TimeManager.get_total_action_index()
	check(initial == 1, "Initial trip did not cost one action")
	var area := navigator.local_area_view.get_current_area_instance()
	var exe: LocalAreaExeActor
	for child: Node in area.get_node("PopulationController/PopulationActors").get_children():
		if child is LocalAreaExeActor:
			exe = child
	check(exe != null and await interact(area, exe), "Player could not request voluntary encounter")
	await until(func() -> bool: return confirmation.visible)
	confirmation.confirm_button.pressed.emit()
	check(await until(func() -> bool: return navigator.combat_app.is_encounter_active() and navigator.can_save_now()), "Voluntary encounter did not start")
	check(TimeManager.get_total_action_index() == initial, "Voluntary encounter charged before escape could release the reservation")
	var transaction := navigator._active_combat_transaction_id
	check(ActivityManager.has_active_transaction(transaction), "Encounter has no owning activity transaction")
	await settle()
	check(SaveManager.manual_save(), "Could not save active encounter at stable boundary")
	check(SaveManager.load_campaign("navigator_activity").is_empty(), "Could not restore active encounter")
	await settle()
	check(navigator._current_mode == NavigatorApp.NavigatorMode.ENCOUNTER and ActivityManager.has_active_transaction(transaction), "Save/load orphaned the encounter reservation")
	check(TimeManager.get_total_action_index() == initial, "Load charged the pending activity")
	var experience := CampaignState.partner.current_exp
	var inventory := CampaignState.inventory.to_save_data()
	var modules := CampaignState.known_module_ids.duplicate()
	for attempt: int in range(100):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.run_away_btn.pressed.emit()
		await get_tree().process_frame
	check(navigator.combat_app.resolution_panel.visible and CombatManager.get_pending_outcome() == CombatResult.Outcome.ESCAPED, "Real Run Away control did not reach a successful escape")
	check(CampaignState.partner.current_exp == experience and CampaignState.inventory.to_save_data() == inventory and CampaignState.known_module_ids == modules, "Run Away granted persistent rewards")
	navigator.combat_app.resolution_panel.continue_button.pressed.emit()
	await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.can_save_now())
	check(TimeManager.get_total_action_index() == initial and not ActivityManager.has_active_transaction(transaction), "Successful escape charged voluntary combat time or left an orphan reservation")
	area = navigator.local_area_view.get_current_area_instance()
	exe = area.population_controller.get_population_actor(exe.get_interaction_id()) as LocalAreaExeActor if is_instance_valid(exe) else null
	if exe == null:
		for child: Node in area.get_node("PopulationController/PopulationActors").get_children():
			if child is LocalAreaExeActor:
				exe = child
	check(exe != null and await interact(area, exe), "Returning from escape lost the unresolved EXE")
	await until(func() -> bool: return confirmation.visible)
	confirmation.confirm_button.pressed.emit()
	await until(func() -> bool: return navigator.combat_app.is_encounter_active() and navigator.can_save_now())
	transaction = navigator._active_combat_transaction_id
	for cycle: int in range(6):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.execute_btn.pressed.emit()
		await until(func() -> bool: return not navigator.combat_app.execute_btn.disabled or navigator.combat_app.resolution_panel.visible, 15)
	check(CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY, "Voluntary combat did not resolve through real timeline execution")
	navigator.combat_app.resolution_panel.continue_button.pressed.emit()
	await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.can_save_now())
	check(TimeManager.get_total_action_index() == initial + 1, "Paid voluntary resolution did not charge exactly one block")
	check(not ActivityManager.complete_activity(transaction) and TimeManager.get_total_action_index() == initial + 2, "Activity completion charged twice")
	check(ActivityManager.export_save_data().transactions.is_empty(), "Resolution left an orphan transaction")
	navigator.queue_free()
	confirmation.queue_free()
	await get_tree().process_frame
	finish("NAVIGATOR_ACTIVITY_CONTRACT_TEST")
