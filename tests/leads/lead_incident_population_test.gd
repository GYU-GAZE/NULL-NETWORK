extends Node


const LEAD_ID: String = "aquarium_signal"
const SOURCE_THREAD_ID: String = "aquarium_signal_rumour"
const INCIDENT_ID: String = "akihabara_aquarium_relay"
const LOCATION_ID: String = "akihabara"

var _failures := PackedStringArray()
var _confirmation_count: int = 0
var _confirmed_cost: int = -1
var _encounter_request: Dictionary = {}


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_connect_signals()
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(catalog_errors.is_empty(), "Default catalog failed: %s" % catalog_errors)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	GameState.set_flag("incident.akihabara_aquarium_relay.resolved", false)
	_check(
		CampaignState.create_campaign(
			"phase11_lead_incident",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the Phase 11 fixture campaign."
	)

	_test_forum_lead_and_badge()
	await _test_population_and_restart()
	await _test_paid_incident_pipeline()
	await _wait_frames(4)
	_finish_test()


func _test_forum_lead_and_badge() -> void:
	_check(
		LeadIncidentManager.try_handle_forum_url(
			"lead://%s" % LEAD_ID,
			SOURCE_THREAD_ID
		),
		"Forum link did not activate its cataloged Lead."
	)
	_check(
		CampaignState.active_lead_ids.has(LEAD_ID)
		and CampaignState.get_lead_progress(LEAD_ID).get(
			"stage_id",
			""
		) == "investigate_relay",
		"Lead activation did not persist its stable stage ID."
	)
	var location: MapLocation = ContentRegistry.get_location(LOCATION_ID)
	var runtime_state: NavigatorLocationRuntimeState = (
		NavigatorLocationStateResolver.resolve(location)
	)
	_check(
		location != null
		and runtime_state != null
		and runtime_state.activity_badge != null
		and runtime_state.activity_badge.badge_id == "rumour_lead",
		"Active Lead did not project its badge into Navigator."
	)


func _test_population_and_restart() -> void:
	var location: MapLocation = ContentRegistry.get_location(LOCATION_ID)
	var first_area: NavigatorLocalAreaScene = await _open_area(location)

	if first_area == null:
		return

	var first_controller: LocalAreaPopulationController = (
		first_area.population_controller
	)
	var first_state: Dictionary = first_controller.get_population_state()
	var first_actor_ids: PackedStringArray = _get_actor_ids(first_state)
	_check(
		_has_population_kind(
			first_state,
			LocalAreaSpawnPoint.SpawnKind.COMMON_ENCOUNTER
		),
		"SpawnTable did not produce a common Local Area encounter."
	)
	_check(
		_has_population_content(first_state, INCIDENT_ID),
		"Active Lead did not add its Incident to the Local Area population."
	)

	var campaign_snapshot: Dictionary = CampaignState.export_save_data()
	var time_snapshot: Dictionary = TimeManager.export_save_data()
	first_area.queue_free()
	await _wait_frames(3)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	var restore_errors: PackedStringArray = CampaignState.restore_save_data(
		campaign_snapshot
	)
	TimeManager.import_save_data(time_snapshot)
	_check(restore_errors.is_empty(), "Campaign restart failed: %s" % restore_errors)

	var second_area: NavigatorLocalAreaScene = await _open_area(location)

	if second_area == null:
		return

	var restored_state: Dictionary = (
		second_area.population_controller.get_population_state()
	)
	_check(
		_get_actor_ids(restored_state) == first_actor_ids,
		"Restart rerolled the population within the same location/day/period."
	)
	second_area.queue_free()
	await _wait_frames(3)


func _test_paid_incident_pipeline() -> void:
	var initial_action_index: int = TimeManager.get_total_action_index()
	var request_id: String = LeadIncidentManager.request_incident(INCIDENT_ID)
	_check(not request_id.is_empty(), "Incident activity request was rejected.")
	await _wait_frames(8)
	_check(
		_confirmation_count == 1 and _confirmed_cost == 2,
		"Incident did not expose one transparent two-block confirmation."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 2,
		"Paid Incident did not charge exactly two action blocks."
	)
	_check(
		DialogueManager.active_dialogue_id
		== "incident.akihabara_aquarium_relay",
		"Confirmed Incident did not enter its cataloged dialogue."
	)

	_check(DialogueManager.advance(), "Incident dialogue could not advance.")
	_check(DialogueManager.advance(), "Incident dialogue could not complete.")
	await _wait_frames(3)
	_check(
		str(_encounter_request.get("incident_id", "")) == INCIDENT_ID
		and _encounter_request.get("encounter") is CombatEncounter
		and str(_encounter_request.get("transaction_id", "")) != "",
		"Dialogue completion did not cross the real Incident combat boundary."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 2,
		"Included dialogue or combat charged the paid Incident twice."
	)

	var transaction_id: String = str(
		_encounter_request.get("transaction_id", "")
	)
	_check(
		LeadIncidentManager.resolve_incident(
			INCIDENT_ID,
			CombatResult.create(
				CombatResult.Outcome.VICTORY,
				"akihabara_rattildus_1v1"
			)
		),
		"Victory did not resolve the Incident through its typed branch."
	)
	await _wait_frames(3)
	_check(
		CampaignState.has_completed_incident(INCIDENT_ID)
		and CampaignState.completed_lead_ids.has(LEAD_ID)
		and not CampaignState.active_lead_ids.has(LEAD_ID),
		"Incident victory did not complete both Incident and Lead."
	)
	_check(
		GameState.get_flag("incident.akihabara_aquarium_relay.resolved"),
		"Incident resolution effects were not applied."
	)
	_check(
		not ActivityManager.has_active_transaction(transaction_id),
		"Incident activity remained active after authoritative resolution."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 2,
		"Incident resolution duplicated its time cost."
	)

	ForumThreadDatabase.reload_threads()
	var reaction_visible: bool = false

	for data: ThreadButtonData in ForumThreadDatabase.get_all_thread_data():
		if data.thread_ref != null \
			and data.thread_ref.thread_id == "aquarium_signal_confirmed":
			reaction_visible = data.is_visible()
			break

	_check(reaction_visible, "Forum did not react to the resolved Incident flag.")
	var location: MapLocation = ContentRegistry.get_location(LOCATION_ID)
	var runtime_state: NavigatorLocationRuntimeState = (
		NavigatorLocationStateResolver.resolve(location)
	)
	_check(
		runtime_state.activity_badge == null
		or runtime_state.activity_badge.badge_id != "rumour_lead",
		"Completed Lead left a stale Navigator badge."
	)


func _open_area(location: MapLocation) -> NavigatorLocalAreaScene:
	if location == null or location.local_area == null \
		or location.local_area.area_scene == null:
		_check(false, "Akihabara Local Area content is unavailable.")
		return null

	var area := (
		location.local_area.area_scene.instantiate()
		as NavigatorLocalAreaScene
	)
	add_child(area)
	await _wait_frames(2)
	_check(
		area != null and area.setup_local_area(
			location.local_area,
			location.local_area.default_entry_id,
			Vector2.ZERO,
			false,
			{},
			location
		),
		"Akihabara population scene failed to initialize."
	)
	return area


func _get_actor_ids(state: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()

	for actor_value: Variant in state.get("actors", []):
		if actor_value is Dictionary:
			result.append(str(actor_value.get("actor_id", "")))

	result.sort()
	return result


func _has_population_kind(state: Dictionary, kind: int) -> bool:
	for actor_value: Variant in state.get("actors", []):
		if actor_value is Dictionary and int(actor_value.get("kind", -1)) == kind:
			return true

	return false


func _has_population_content(state: Dictionary, content_id: String) -> bool:
	for actor_value: Variant in state.get("actors", []):
		if actor_value is Dictionary \
			and str(actor_value.get("content_id", "")) == content_id:
			return true

	return false


func _connect_signals() -> void:
	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_activity_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_activity_confirmation_requested
		)

	if not LeadIncidentManager.incident_encounter_requested.is_connected(
		_on_incident_encounter_requested
	):
		LeadIncidentManager.incident_encounter_requested.connect(
			_on_incident_encounter_requested
		)


func _on_activity_confirmation_requested(
	request_id: String,
	definition: ActivityDefinitionData,
	preview: ActivityPreviewData,
	source_id: String
) -> void:
	if source_id != LeadIncidentManager.SOURCE_ID:
		return

	_confirmation_count += 1
	_confirmed_cost = preview.charged_action_cost
	_check(
		definition != null
		and definition.get_display_id()
		== "incident.akihabara_aquarium_relay",
		"Incident requested the wrong ActivityDefinitionData."
	)
	call_deferred("_confirm_activity", request_id)


func _confirm_activity(request_id: String) -> void:
	GlobalSignals.activity_confirmation_resolved.emit(request_id, true)


func _on_incident_encounter_requested(
	incident_id: String,
	encounter: CombatEncounter,
	transaction_id: String,
	activity_id: String
) -> void:
	_encounter_request = {
		"incident_id": incident_id,
		"encounter": encounter,
		"transaction_id": transaction_id,
		"activity_id": activity_id
	}


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()

	if _failures.is_empty():
		print("LEAD_INCIDENT_POPULATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("LEAD_INCIDENT_POPULATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
