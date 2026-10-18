extends FieldIntegrationHarness

func run() -> void:
	seed(8102)
	await boot("field_end_to_end")
	var positions: Dictionary = {}
	for actor: LocalAreaExeActor in area.get_field_exes():
		positions[actor.population_unit_id] = actor.global_position
	await settle(0.8)
	var moved := false
	for actor: LocalAreaExeActor in area.get_field_exes():
		moved = moved or actor.global_position.distance_to(positions[actor.population_unit_id]) > 2
	check(moved, "Production field projections remained stationary")
	await capture("field_akiba_individuals")
	var actors := configure_call_actors(false)
	var main := actors[0]
	var main_id := main.population_unit_id
	var initial := TimeManager.get_total_action_index()
	await request_fight(main)
	check(CombatManager.get_current_encounter().enemy_slots.size() == 1, "Independent solo contact was not 1v1")
	check(TimeManager.get_total_action_index() == initial, "1v1 charged its time before resolution")
	await win_current_fight()
	await return_from_fight()
	check(TimeManager.get_total_action_index() == initial + 1, "Voluntary 1v1 did not cost exactly one block")
	check(area.find_interactable_by_id(main_id) == null and area.get_field_exes().size() == 3, "1v1 resolution removed unselected field units or restored its spent unit")
	check(ActivityManager.export_save_data().transactions.is_empty(), "Solo field resolution left an orphan reservation")
	# A legitimate new population generation is required before four new units.
	var qa := await TimeManager.advance_development_hours(24)
	check(bool(qa.ok), "Could not prepare next ecological generation through the temporal authority")
	await settle(0.1)
	actors = configure_call_actors(true)
	check(actors.size() == 4, "New ecological generation did not project four individuals")
	main = actors[0]
	var calls := area.field_calls
	calls.call_presented.connect(_capture_call)
	initial = TimeManager.get_total_action_index()
	await request_fight(main)
	check(CombatManager.get_current_encounter().enemy_slots.size() == 4, "Actual UI contact did not produce a dynamic four-enemy formation")
	check(TimeManager.get_total_action_index() == initial, "1v4 charged before resolution")
	await capture("field_dynamic_formation")
	var ids: Array[String] = []
	for slot: CombatSlotData in CombatManager.get_current_encounter().enemy_slots:
		ids.append(slot.field_unit_id)
	var transaction := navigator._active_combat_transaction_id
	var saved_motions := {}
	for unit: LocalAreaExeActor in area.get_field_exes():
		saved_motions[unit.population_unit_id] = unit.motor.to_data()
	check(SaveManager.manual_save(), "Real SaveManager could not save a stable dynamic encounter")
	check(SaveManager.load_campaign("field_end_to_end").is_empty(), "Dynamic encounter could not be restored from disk")
	await settle(0.2)
	area = navigator.local_area_view.get_current_area_instance()
	for unit: LocalAreaExeActor in area.get_field_exes():
		check(unit.motor.to_data().rng == saved_motions[unit.population_unit_id].rng, "Disk JSON changed the individual 64-bit field RNG state")
		check(unit.motor.to_data().position == saved_motions[unit.population_unit_id].position, "Disk load changed a paused field unit's physical position")
	var restored_ids: Array[String] = []
	for slot: CombatSlotData in CombatManager.get_current_encounter().enemy_slots:
		restored_ids.append(slot.field_unit_id)
	check(restored_ids == ids and ActivityManager.has_active_transaction(transaction), "Disk load lost formation identities or the reserved cost")
	var experience := CampaignState.partner.current_exp
	var inventory := CampaignState.inventory.to_save_data()
	var modules := CampaignState.known_module_ids.duplicate()
	for attempt: int in range(100):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.run_away_btn.pressed.emit()
		await get_tree().process_frame
	check(CombatManager.get_pending_outcome() == CombatResult.Outcome.ESCAPED and CombatManager.is_resolution_applied(), "Run Away control did not reach a successful escape")
	await return_from_fight()
	check(TimeManager.get_total_action_index() == initial, "Run Away from a dynamic encounter charged time")
	check(CampaignState.partner.current_exp == experience and CampaignState.inventory.to_save_data() == inventory and CampaignState.known_module_ids == modules, "Run Away granted persistent rewards")
	check(area.get_field_exes().size() == 4 and ActivityManager.export_save_data().transactions.is_empty(), "Escape orphaned units or activity reservations")
	await settle(0.5)
	check(not CombatManager.is_encounter_active() and not area.field_calls.busy, "Return position immediately reopened environmental combat")
	await capture("field_after_escape")
	# Deliberate interaction may provoke a new call during grace; automatic
	# contact remains suppressed. The same four physical identities participate.
	actors = configure_call_actors(true)
	main = actors[0]
	await request_fight(main)
	check(CombatManager.get_current_encounter().enemy_slots.size() == 4, "Reprovoked field call did not use all four eligible units")
	await win_current_fight()
	await return_from_fight()
	check(TimeManager.get_total_action_index() == initial + 1, "Voluntary 1v4 did not cost exactly one block")
	check(area.get_field_exes().is_empty(), "Defeated/tamed participants did not reconcile individually to spent Population Units")
	check(ActivityManager.export_save_data().transactions.is_empty(), "Four-enemy resolution left an orphan transaction")
	await capture("field_after_resolution")
	var position := area.get_player_position()
	check(SaveManager.manual_save(), "Settled field population could not be saved")
	check(SaveManager.load_campaign("field_end_to_end").is_empty(), "Settled field population could not be loaded")
	await settle(0.1)
	area = navigator.local_area_view.get_current_area_instance()
	check(area.get_field_exes().is_empty() and area.get_player_position() == position, "Reload respawned spent units or lost Player position")
	if DisplayServer.get_name() != "headless":
		KubuDisplaySetting.set_windowed_size(Vector2i(1280, 720))
		await settle(0.2)
		check(get_window().content_scale_factor == 2.0 and area.get_player_position() == position, "Display resize changed the 2x world/physical position")
		await capture("field_small_display_after_load")
	await dispose()
	finish("FIELD_EXPLORATION_FLOW_TEST")

func _capture_call(_formation: Dictionary) -> void:
	await capture("field_combat_call_responders")
