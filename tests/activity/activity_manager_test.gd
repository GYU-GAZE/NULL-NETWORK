extends Node


const CONFIRMATION_SCENE: PackedScene = preload(
	"res://systems/ui/activity_confirmation_dialog.tscn"
)
const NAVIGATOR_SCENE: PackedScene = preload(
	"res://apps/navigator/app_navigator.tscn"
)


var _failures: PackedStringArray = PackedStringArray()
var _confirmation_request_ids: Array[String] = []
var _started_events: Array[Dictionary] = []
var _cancelled_request_ids: Array[String] = []
var _rejected_request_ids: Array[String] = []

var _saved_day: int
var _saved_period: int
var _saved_block: int


func _ready() -> void:
	_saved_day = TimeManager.days_passed
	_saved_period = int(TimeManager.current_period)
	_saved_block = TimeManager.current_action_block
	_connect_signals()

	await _run_tests()

	ActivityManager.reset_runtime_state()
	TimeManager.days_passed = _saved_day
	TimeManager.current_period = _saved_period
	TimeManager.current_action_block = _saved_block

	if _failures.is_empty():
		print("ACTIVITY_MANAGER_TEST: PASS")
		get_tree().quit(0)
		return

	for failure in _failures:
		push_error(failure)

	print(
		"ACTIVITY_MANAGER_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)


func _connect_signals() -> void:
	GlobalSignals.activity_confirmation_requested.connect(
		_on_confirmation_requested
	)
	ActivityManager.activity_started.connect(
		_on_activity_started
	)
	ActivityManager.activity_cancelled.connect(
		_on_activity_cancelled
	)
	ActivityManager.activity_rejected.connect(
		_on_activity_rejected
	)


func _run_tests() -> void:
	_test_definition_validation()
	_test_condition_blocks_six_through_eleven()
	_test_preview_crosses_day_to_night()
	_test_preview_rejects_period_crossing()
	_test_preview_rejects_day_overrun()
	_test_last_block_may_end_at_next_day_boundary()
	await _test_confirmation_charges_once()
	await _test_cancellation_charges_nothing()
	await _test_included_activity_reuses_transaction()
	await _test_source_cancellation_closes_dialog()
	await _test_navigator_travel_and_voluntary_combat()
	_test_availability_provider()


func _test_definition_validation() -> void:
	var invalid_definition := ActivityDefinitionData.new()
	invalid_definition.allow_cross_day = true
	invalid_definition.allow_cross_period = false
	var errors: PackedStringArray = (
		invalid_definition.validate_data()
	)
	_check(
		errors.size() == 3,
		"ActivityDefinitionData did not reject missing IDs, "
		+ "missing names and invalid crossing policy."
	)


func _test_condition_blocks_six_through_eleven() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 10)
	var condition := TimeConditionData.new()
	condition.min_action_block = 10
	condition.max_action_block = 11
	_check(
		condition.is_met(),
		"TimeConditionData could not match action blocks 6–11."
	)


func _test_preview_crosses_day_to_night() -> void:
	_reset_state(3, TimeManager.TimePeriod.DAY, 11)
	var definition: ActivityDefinitionData = _make_activity(
		"test.cross_period",
		2,
		true,
		false,
		false
	)
	var preview: ActivityPreviewData = (
		ActivityManager.create_preview(definition, "test")
	)
	_check(preview.is_valid(), "DAY→NIGHT preview was rejected.")
	_check(
		preview.crosses_period and not preview.crosses_day,
		"DAY→NIGHT crossing flags are incorrect."
	)
	_check(
		preview.final_day == 3
		and preview.final_period == TimeManager.TimePeriod.NIGHT
		and preview.final_action_block == 1,
		"DAY block 11 + 2 did not preview NIGHT block 1."
	)


func _test_preview_rejects_period_crossing() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 11)
	var definition: ActivityDefinitionData = _make_activity(
		"test.no_cross_period",
		2,
		false,
		false,
		false
	)
	var preview: ActivityPreviewData = (
		ActivityManager.create_preview(definition, "test")
	)
	_check(
		not preview.is_valid()
		and preview.denial_reason.contains("current period"),
		"Period-locked activity did not reject crossing."
	)


func _test_preview_rejects_day_overrun() -> void:
	_reset_state(4, TimeManager.TimePeriod.NIGHT, 11)
	var definition: ActivityDefinitionData = _make_activity(
		"test.no_cross_day",
		2,
		true,
		false,
		false
	)
	var preview: ActivityPreviewData = (
		ActivityManager.create_preview(definition, "test")
	)
	_check(
		not preview.is_valid(),
		"Activity incorrectly consumed blocks from the next day."
	)
	_check(
		preview.denial_reason.contains("Required: 2")
		and preview.denial_reason.contains("Available: 1"),
		"End-of-day rejection does not explain required/available blocks."
	)


func _test_last_block_may_end_at_next_day_boundary() -> void:
	_reset_state(7, TimeManager.TimePeriod.NIGHT, 11)
	var definition: ActivityDefinitionData = _make_activity(
		"test.day_boundary",
		1,
		true,
		false,
		false
	)
	var preview: ActivityPreviewData = (
		ActivityManager.create_preview(definition, "test")
	)
	_check(
		preview.is_valid()
		and preview.final_day == 8
		and preview.final_period == TimeManager.TimePeriod.DAY
		and preview.final_action_block == 0,
		"The final available block should end at next DAY block 0."
	)


func _test_confirmation_charges_once() -> void:
	_reset_state(2, TimeManager.TimePeriod.DAY, 11)
	var definition: ActivityDefinitionData = _make_activity(
		"test.confirmed",
		2,
		true,
		false,
		true
	)
	var request_id: String = ActivityManager.request_activity(
		definition,
		"test"
	)
	await get_tree().process_frame

	_check(
		_confirmation_request_ids.has(request_id),
		"Paid activity did not request confirmation."
	)
	_check(
		TimeManager.current_action_block == 11
		and TimeManager.current_period == TimeManager.TimePeriod.DAY,
		"Activity charged time before confirmation."
	)

	GlobalSignals.activity_confirmation_resolved.emit(
		request_id,
		true
	)
	var event: Dictionary = _find_started_event(request_id)
	_check(
		not event.is_empty(),
		"Confirmed activity did not start."
	)
	_check(
		TimeManager.current_period == TimeManager.TimePeriod.NIGHT
		and TimeManager.current_action_block == 1,
		"Confirmed activity did not charge exactly two blocks."
	)

	GlobalSignals.activity_confirmation_resolved.emit(
		request_id,
		true
	)
	_check(
		TimeManager.current_action_block == 1,
		"Duplicate confirmation charged the same request twice."
	)
	ActivityManager.complete_activity(
		str(event.get("transaction_id", ""))
	)


func _test_cancellation_charges_nothing() -> void:
	_reset_state(5, TimeManager.TimePeriod.DAY, 4)
	var definition: ActivityDefinitionData = _make_activity(
		"test.cancelled",
		2,
		true,
		false,
		true
	)
	var request_id: String = ActivityManager.request_activity(
		definition,
		"test"
	)
	await get_tree().process_frame
	GlobalSignals.activity_confirmation_resolved.emit(
		request_id,
		false
	)
	_check(
		TimeManager.days_passed == 5
		and TimeManager.current_period == TimeManager.TimePeriod.DAY
		and TimeManager.current_action_block == 4,
		"Cancelled activity changed the clock."
	)
	_check(
		_cancelled_request_ids.has(request_id),
		"Cancelled request did not emit activity_cancelled."
	)


func _test_included_activity_reuses_transaction() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 0)
	var parent: ActivityDefinitionData = _make_activity(
		"test.parent",
		2,
		true,
		false,
		false
	)
	var parent_request_id: String = (
		ActivityManager.request_activity(parent, "test")
	)
	await get_tree().process_frame
	var parent_event: Dictionary = _find_started_event(
		parent_request_id
	)
	var transaction_id: String = str(
		parent_event.get("transaction_id", "")
	)

	var child: ActivityDefinitionData = _make_activity(
		"test.child_combat",
		2,
		true,
		false,
		true
	)
	var child_request_id: String = (
		ActivityManager.request_activity(
			child,
			"test",
			transaction_id
		)
	)
	await get_tree().process_frame
	var child_event: Dictionary = _find_started_event(
		child_request_id
	)
	_check(
		str(child_event.get("transaction_id", ""))
		== transaction_id,
		"Included activity created a second transaction."
	)
	_check(
		TimeManager.current_action_block == 2,
		"Included activity charged its own time cost."
	)
	var transaction: Dictionary = (
		ActivityManager.get_active_transaction(transaction_id)
	)
	_check(
		(transaction.get("included_activity_ids", []) as Array).has(
			"test.child_combat"
		),
		"Parent transaction did not record included activity."
	)
	ActivityManager.complete_activity(
		transaction_id,
		"test.child_combat"
	)
	_check(
		ActivityManager.has_active_transaction(transaction_id),
		"Completing a child incorrectly completed its parent."
	)
	ActivityManager.complete_activity(transaction_id)


func _test_source_cancellation_closes_dialog() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 3)
	var dialog := (
		CONFIRMATION_SCENE.instantiate()
		as ActivityConfirmationDialog
	)
	add_child(dialog)
	await get_tree().process_frame

	var definition: ActivityDefinitionData = _make_activity(
		"test.source_close",
		1,
		true,
		false,
		true
	)
	var request_id: String = ActivityManager.request_activity(
		definition,
		"navigator"
	)
	await get_tree().process_frame
	var rendered_cost_label := (
		dialog.get_node("%CostLabel") as Label
	)
	var rendered_available_label := (
		dialog.get_node("%AvailableTimeLabel") as Label
	)
	_check(dialog.visible, "Confirmation dialog did not open.")
	_check(
		rendered_cost_label != null
		and rendered_cost_label.text == "Time Cost: 1 block",
		"Confirmation dialog did not render activity cost."
	)
	_check(
		rendered_available_label != null
		and rendered_available_label.text
		== "Available Today: 21 blocks",
		"Confirmation dialog did not render available time."
	)

	ActivityManager.cancel_requests_for_source(
		"navigator",
		"Source closed."
	)
	await get_tree().process_frame
	_check(
		not dialog.visible,
		"Closing the source did not dismiss confirmation."
	)
	_check(
		TimeManager.current_action_block == 3,
		"Closing confirmation source charged time."
	)
	_check(
		_cancelled_request_ids.has(request_id),
		"Source cancellation did not cancel its request."
	)
	dialog.queue_free()


func _test_navigator_travel_and_voluntary_combat() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 0)
	CampaignState.reset_campaign(false)
	CampaignState.create_campaign(
		"activity_partner_fixture",
		CampaignState.SaveMode.SAFE,
		CampaignState.CampaignPhase.MAIN_CAMPAIGN
	)
	var partner: PartnerStateData = APKProgressionService.create_partner_state(
		"novire_init",
		"Activity NOVIRE",
		0,
		0
	)
	_check(
		partner != null and CampaignState.set_partner_state(partner),
		"Could not create the ActivityManager partner fixture."
	)
	var navigator := (
		NAVIGATOR_SCENE.instantiate() as NavigatorApp
	)
	add_child(navigator)
	await get_tree().process_frame
	await get_tree().process_frame

	var location: MapLocation = (
		navigator.world_map_view.get_location_by_id(
			"akihabara"
		)
	)
	_check(
		location != null
		and location.travel_activity != null
		and location.travel_activity.action_cost == 1,
		"Akihabara does not use a one-block travel activity."
	)

	if location == null or location.travel_activity == null:
		navigator.queue_free()
		return

	navigator._on_world_map_enter_area_requested(location)
	await get_tree().process_frame
	var travel_request_id: String = (
		_confirmation_request_ids.back()
		if not _confirmation_request_ids.is_empty()
		else ""
	)
	GlobalSignals.activity_confirmation_resolved.emit(
		travel_request_id,
		true
	)
	var navigator_state: Dictionary = (
		navigator.get_app_session_state()
	)
	_check(
		TimeManager.current_action_block == 1,
		"Navigator travel did not charge exactly one block."
	)
	_check(
		str(navigator_state.get("current_location_id", ""))
		== "akihabara"
		and int(navigator_state.get("mode", -1))
		== NavigatorApp.NavigatorMode.LOCAL_AREA,
		"Confirmed travel did not enter Akihabara Local Area."
	)

	var area_instance: Node = (
		navigator.local_area_view.get_current_area_instance()
	)
	var exe_actor: LocalAreaExeActor

	if area_instance != null:
		exe_actor = (
			area_instance.get_node_or_null(
				"Interactables/TestEXE"
			)
			as LocalAreaExeActor
		)

	_check(
		exe_actor != null
		and exe_actor.interaction_data != null
		and exe_actor.interaction_data.activity != null
		and exe_actor.interaction_data.activity.action_cost == 2,
		"Rattildus does not use a two-block voluntary combat activity."
	)

	if exe_actor == null or exe_actor.interaction_data == null:
		navigator.queue_free()
		return

	navigator._on_local_area_interaction_requested(exe_actor)
	await get_tree().process_frame
	var combat_request_id: String = (
		_confirmation_request_ids.back()
		if not _confirmation_request_ids.is_empty()
		else ""
	)
	GlobalSignals.activity_confirmation_resolved.emit(
		combat_request_id,
		true
	)
	var combat_event: Dictionary = _find_started_event(
		combat_request_id
	)
	var combat_transaction_id: String = str(
		combat_event.get("transaction_id", "")
	)
	_check(
		TimeManager.current_action_block == 3,
		"Voluntary combat did not charge exactly two blocks "
		+ "at confirmation."
	)
	_check(
		navigator.combat_app.is_encounter_active()
		and ActivityManager.has_active_transaction(
			combat_transaction_id
		),
		"Confirmed voluntary combat did not start its transaction."
	)

	var player_actor: Variant = CombatManager.get_player_actor()

	if player_actor is Dictionary:
		player_actor["dodge"] = 1.0

	var escaped: bool = false

	for _attempt: int in range(100):
		if CombatManager.try_escape():
			escaped = true
			break

	_check(escaped, "Voluntary combat could not reach its escape boundary.")
	var resolution_errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.ESCAPED
	)
	_check(
		resolution_errors.is_empty(),
		"Voluntary combat escape resolution failed: %s" % resolution_errors
	)
	navigator.combat_app._finish_encounter(CombatResult.Outcome.ESCAPED)
	_check(
		TimeManager.current_action_block == 3,
		"Combat resolution charged time a second time."
	)
	_check(
		not ActivityManager.has_active_transaction(
			combat_transaction_id
		),
		"Combat resolution did not complete its activity."
	)

	CombatManager.reset_encounter()
	navigator.queue_free()
	await get_tree().process_frame


func _test_availability_provider() -> void:
	_reset_state(1, TimeManager.TimePeriod.DAY, 0)
	ActivityManager.register_availability_provider(
		&"test_schedule",
		_deny_from_schedule
	)
	var definition: ActivityDefinitionData = _make_activity(
		"test.schedule",
		1,
		true,
		false,
		false
	)
	var preview: ActivityPreviewData = (
		ActivityManager.create_preview(definition, "test")
	)
	_check(
		not preview.is_valid()
		and preview.denial_reason == "Schedule is occupied.",
		"Availability provider could not block an activity."
	)
	_check(
		preview.expiration_warnings.has("A Lead may expire."),
		"Availability provider warnings were not added to preview."
	)
	ActivityManager.unregister_availability_provider(
		&"test_schedule"
	)


func _deny_from_schedule(
	_definition: ActivityDefinitionData,
	_preview: ActivityPreviewData
) -> Dictionary:
	return {
		"allowed": false,
		"reason": "Schedule is occupied.",
		"expiration_warnings": PackedStringArray([
			"A Lead may expire."
		])
	}


func _make_activity(
	activity_id: String,
	cost: int,
	allow_cross_period: bool,
	allow_cross_day: bool,
	requires_confirmation: bool
) -> ActivityDefinitionData:
	var definition := ActivityDefinitionData.new()
	definition.activity_id = activity_id
	definition.display_name = activity_id
	definition.action_cost = cost
	definition.allow_cross_period = allow_cross_period
	definition.allow_cross_day = allow_cross_day
	definition.requires_confirmation = requires_confirmation
	return definition


func _reset_state(
	day: int,
	period: TimeManager.TimePeriod,
	block: int
) -> void:
	ActivityManager.reset_runtime_state()
	_confirmation_request_ids.clear()
	_started_events.clear()
	_cancelled_request_ids.clear()
	_rejected_request_ids.clear()
	TimeManager.days_passed = day
	TimeManager.current_period = period
	TimeManager.current_action_block = block


func _find_started_event(request_id: String) -> Dictionary:
	for event in _started_events:
		if str(event.get("request_id", "")) == request_id:
			return event

	return {}


func _on_confirmation_requested(
	request_id: String,
	_definition: ActivityDefinitionData,
	_preview: ActivityPreviewData,
	_source_id: String
) -> void:
	_confirmation_request_ids.append(request_id)


func _on_activity_started(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	request_id: String
) -> void:
	_started_events.append({
		"transaction_id": transaction_id,
		"activity_id": activity_id,
		"source_id": source_id,
		"request_id": request_id
	})


func _on_activity_cancelled(
	request_id: String,
	_activity_id: String,
	_source_id: String,
	_reason: String
) -> void:
	_cancelled_request_ids.append(request_id)


func _on_activity_rejected(
	request_id: String,
	_activity_id: String,
	_source_id: String,
	_reason: String
) -> void:
	_rejected_request_ids.append(request_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
