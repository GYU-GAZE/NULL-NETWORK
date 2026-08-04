extends Node


signal lead_activated(lead_id: String)
signal lead_stage_changed(lead_id: String, stage_id: String)
signal lead_completed(lead_id: String)
signal lead_state_changed(lead_id: String)
signal incident_started(incident_id: String, lead_id: String)
signal incident_encounter_requested(
	incident_id: String,
	encounter: CombatEncounter,
	transaction_id: String,
	activity_id: String
)
signal incident_completed(incident_id: String, lead_id: String)
signal incident_state_changed(incident_id: String)


const SOURCE_ID: String = "lead_incident"
const LEAD_URL_PREFIX: String = "lead://"
const STATUS_READY: String = "ready"
const STATUS_DIALOGUE: String = "dialogue"
const STATUS_ENCOUNTER: String = "encounter"

var _pending_incident_requests: Dictionary = {}


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	if not ActivityManager.activity_started.is_connected(
		_on_activity_started
	):
		ActivityManager.activity_started.connect(_on_activity_started)

	if not ActivityManager.activity_rejected.is_connected(
		_on_activity_rejected
	):
		ActivityManager.activity_rejected.connect(_on_activity_rejected)

	if not ActivityManager.activity_cancelled.is_connected(
		_on_activity_cancelled
	):
		ActivityManager.activity_cancelled.connect(_on_activity_cancelled)

	if not DialogueManager.dialogue_completed.is_connected(
		_on_dialogue_completed
	):
		DialogueManager.dialogue_completed.connect(_on_dialogue_completed)

	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)


func try_handle_forum_url(url: String, thread_id: String) -> bool:
	var clean_url: String = url.strip_edges()

	if not clean_url.to_lower().begins_with(LEAD_URL_PREFIX):
		return false

	var lead_id: String = clean_url.substr(LEAD_URL_PREFIX.length()).strip_edges()
	var lead: LeadData = ContentRegistry.get_lead(lead_id)

	if lead == null \
		or lead.source_type != LeadData.SourceType.FORUM_THREAD \
		or lead.source_id.strip_edges() != thread_id.strip_edges():
		return false

	return activate_lead(lead_id, thread_id)


func activate_lead(lead_id: String, source_id: String = "") -> bool:
	var clean_id: String = lead_id.strip_edges()
	var lead: LeadData = ContentRegistry.get_lead(clean_id)

	if lead == null or not lead.validate_data().is_empty():
		return false

	if CampaignState.completed_lead_ids.has(clean_id):
		return false

	if CampaignState.active_lead_ids.has(clean_id):
		return true

	var context := _create_context(
		clean_id,
		source_id,
		lead.location_id,
		""
	)

	if not lead.can_activate(context) or lead.is_expired(context):
		return false

	var initial_stage: LeadStageData = lead.get_initial_stage()

	if initial_stage == null or not initial_stage.is_available(context):
		return false

	if not GameEffectData.apply_all(lead.activation_effects, context).is_empty():
		return false

	if not CampaignState.activate_lead(clean_id):
		return false

	CampaignState.set_lead_progress(clean_id, {
		"stage_id": initial_stage.get_display_id(),
		"source_id": source_id.strip_edges(),
		"activated_action_index": TimeManager.get_total_action_index()
	})

	if lead.discover_location_on_activation:
		CampaignState.discover_location(lead.location_id)
		var location: MapLocation = ContentRegistry.get_location(
			lead.location_id
		)

		if location != null:
			NavigatorLocationStateResolver.discover(location)

	lead_activated.emit(clean_id)
	lead_state_changed.emit(clean_id)
	return true


func get_active_leads_for_location(location_id: String) -> Array[LeadData]:
	var result: Array[LeadData] = []
	var clean_location_id: String = location_id.strip_edges()

	for lead_id: String in CampaignState.active_lead_ids:
		var lead: LeadData = ContentRegistry.get_lead(lead_id)

		if lead == null:
			continue

		var progress: Dictionary = CampaignState.get_lead_progress(lead_id)
		var stage: LeadStageData = lead.get_stage(
			str(progress.get("stage_id", ""))
		)
		var resolved_location_id: String = lead.location_id.strip_edges()

		if stage != null and not stage.location_id.strip_edges().is_empty():
			resolved_location_id = stage.location_id.strip_edges()

		if resolved_location_id == clean_location_id:
			result.append(lead)

	return result


func get_navigator_badge(location_id: String) -> NavigatorMarkerBadge:
	for lead: LeadData in get_active_leads_for_location(location_id):
		if lead.navigator_badge != null and not lead.navigator_badge.is_empty():
			return lead.navigator_badge

	return null


func get_available_incidents_for_location(
	location_id: String
) -> Array[IncidentData]:
	var result: Array[IncidentData] = []

	for lead: LeadData in get_active_leads_for_location(location_id):
		var progress: Dictionary = CampaignState.get_lead_progress(
			lead.get_display_id()
		)
		var stage: LeadStageData = lead.get_stage(
			str(progress.get("stage_id", ""))
		)

		if stage == null or stage.incident_id.strip_edges().is_empty():
			continue

		var incident: IncidentData = ContentRegistry.get_incident(
			stage.incident_id
		)

		if incident == null \
			or CampaignState.has_completed_incident(incident.get_display_id()):
			continue

		var context := _create_context(
			lead.get_display_id(),
			incident.get_display_id(),
			location_id,
			""
		)

		if incident.can_start(context):
			result.append(incident)

	return result


func find_lead_for_incident(incident_id: String) -> LeadData:
	var clean_incident_id: String = incident_id.strip_edges()

	for lead_id: String in CampaignState.active_lead_ids:
		var lead: LeadData = ContentRegistry.get_lead(lead_id)

		if lead == null:
			continue

		var progress: Dictionary = CampaignState.get_lead_progress(lead_id)
		var stage: LeadStageData = lead.get_stage(
			str(progress.get("stage_id", ""))
		)

		if stage != null and stage.incident_id.strip_edges() == clean_incident_id:
			return lead

	return null


func request_incident(incident_id: String) -> String:
	var clean_id: String = incident_id.strip_edges()
	var incident: IncidentData = ContentRegistry.get_incident(clean_id)
	var lead: LeadData = find_lead_for_incident(clean_id)

	if incident == null \
		or lead == null \
		or CampaignState.has_completed_incident(clean_id):
		return ""

	var existing: Dictionary = CampaignState.get_incident_progress(clean_id)

	if not existing.is_empty() \
		and str(existing.get("status", STATUS_READY)) != STATUS_READY:
		return ""

	var request_id: String = ActivityManager.request_activity(
		incident.activity_definition,
		SOURCE_ID
	)
	_pending_incident_requests[request_id] = {
		"incident_id": clean_id,
		"lead_id": lead.get_display_id()
	}
	return request_id


func resolve_incident(
	incident_id: String,
	result: CombatResult
) -> bool:
	var clean_id: String = incident_id.strip_edges()
	var incident: IncidentData = ContentRegistry.get_incident(clean_id)

	if incident == null \
		or result == null \
		or CampaignState.has_completed_incident(clean_id):
		return false

	var progress: Dictionary = CampaignState.get_incident_progress(clean_id)
	var lead_id: String = str(progress.get("lead_id", "")).strip_edges()
	var transaction_id: String = str(
		progress.get("activity_transaction_id", "")
	).strip_edges()
	var activity_id: String = str(progress.get("activity_id", "")).strip_edges()
	var context := _create_context(
		lead_id,
		clean_id,
		incident.location_id,
		transaction_id
	)
	var branch: IncidentResolutionBranchData = incident.get_resolution_branch(
		result.outcome,
		context
	)

	if branch == null:
		_finish_activity(transaction_id, activity_id)
		progress["status"] = STATUS_READY
		progress["activity_transaction_id"] = ""
		CampaignState.set_incident_progress(clean_id, progress)
		incident_state_changed.emit(clean_id)
		return true

	if not GameEffectData.apply_all(branch.effects, context).is_empty():
		return false

	if not branch.completes_incident:
		_finish_activity(transaction_id, activity_id)
		progress["status"] = STATUS_READY
		progress["activity_transaction_id"] = ""
		CampaignState.set_incident_progress(clean_id, progress)
		incident_state_changed.emit(clean_id)
		return true

	if not GameEffectData.apply_all(incident.effects, context).is_empty():
		return false

	var lead: LeadData = ContentRegistry.get_lead(lead_id)
	var stage: LeadStageData

	if lead != null:
		var lead_progress: Dictionary = CampaignState.get_lead_progress(lead_id)
		stage = lead.get_stage(str(lead_progress.get("stage_id", "")))

	if stage != null \
		and not GameEffectData.apply_all(stage.completion_effects, context).is_empty():
		return false

	CampaignState.complete_incident(clean_id)

	if branch.completes_lead and lead != null:
		if not GameEffectData.apply_all(lead.completion_effects, context).is_empty():
			return false
		CampaignState.complete_lead(lead_id)
		lead_completed.emit(lead_id)
		lead_state_changed.emit(lead_id)

	_finish_activity(transaction_id, activity_id)
	incident_completed.emit(clean_id, lead_id)
	incident_state_changed.emit(clean_id)
	return true


func _start_incident_content(
	incident: IncidentData,
	progress: Dictionary
) -> void:
	var incident_id: String = incident.get_display_id()
	var stage: IncidentStageData = incident.get_initial_stage()
	var dialogue: DialogueData = incident.dialogue
	var encounter: CombatEncounter = incident.encounter

	if stage != null:
		progress["stage_id"] = stage.get_display_id()
		if stage.dialogue != null:
			dialogue = stage.dialogue
		if stage.encounter != null:
			encounter = stage.encounter

	if dialogue != null:
		progress["status"] = STATUS_DIALOGUE
		progress["dialogue_id"] = dialogue.get_display_id()
		CampaignState.set_incident_progress(incident_id, progress)

		if not DialogueManager.start_dialogue(dialogue.get_display_id()):
			push_error(
				"LeadIncidentManager: failed to start dialogue '%s'."
				% dialogue.get_display_id()
			)
		return

	if encounter != null:
		_request_incident_encounter(incident, encounter, progress)
		return

	resolve_incident(
		incident_id,
		CombatResult.create(CombatResult.Outcome.VICTORY)
	)


func _request_incident_encounter(
	incident: IncidentData,
	encounter: CombatEncounter,
	progress: Dictionary
) -> void:
	progress["status"] = STATUS_ENCOUNTER
	CampaignState.set_incident_progress(incident.get_display_id(), progress)
	incident_encounter_requested.emit(
		incident.get_display_id(),
		encounter,
		str(progress.get("activity_transaction_id", "")),
		str(progress.get("activity_id", ""))
	)


func _on_activity_started(
	transaction_id: String,
	activity_id: String,
	source_id: String,
	request_id: String
) -> void:
	if source_id != SOURCE_ID or not _pending_incident_requests.has(request_id):
		return

	var request: Dictionary = _pending_incident_requests[request_id]
	_pending_incident_requests.erase(request_id)
	var incident_id: String = str(request.get("incident_id", ""))
	var lead_id: String = str(request.get("lead_id", ""))
	var incident: IncidentData = ContentRegistry.get_incident(incident_id)

	if incident == null:
		ActivityManager.fail_activity(
			transaction_id,
			"Incident content is unavailable.",
			activity_id
		)
		return

	var progress := {
		"lead_id": lead_id,
		"status": STATUS_READY,
		"stage_id": incident.initial_stage_id.strip_edges(),
		"activity_transaction_id": transaction_id,
		"activity_id": activity_id,
		"started_action_index": TimeManager.get_total_action_index()
	}
	CampaignState.set_incident_progress(incident_id, progress)
	incident_started.emit(incident_id, lead_id)
	incident_state_changed.emit(incident_id)
	_start_incident_content(incident, progress)


func _on_dialogue_completed(dialogue_id: String) -> void:
	for raw_incident_id: Variant in CampaignState.incident_progress.keys():
		var incident_id: String = str(raw_incident_id)
		var progress: Dictionary = CampaignState.get_incident_progress(incident_id)

		if str(progress.get("status", "")) != STATUS_DIALOGUE \
			or str(progress.get("dialogue_id", "")) != dialogue_id:
			continue

		var incident: IncidentData = ContentRegistry.get_incident(incident_id)

		if incident == null:
			continue

		var stage: IncidentStageData = incident.get_stage(
			str(progress.get("stage_id", ""))
		)
		var encounter: CombatEncounter = incident.encounter

		if stage != null:
			if not GameEffectData.apply_all(
				stage.effects,
				_create_context(
					str(progress.get("lead_id", "")),
					incident_id,
					incident.location_id,
					str(progress.get("activity_transaction_id", ""))
				)
			).is_empty():
				return

			if stage.encounter != null:
				encounter = stage.encounter

		if encounter != null:
			_request_incident_encounter(incident, encounter, progress)
		else:
			resolve_incident(
				incident_id,
				CombatResult.create(CombatResult.Outcome.VICTORY)
			)

		return


func _on_activity_rejected(
	request_id: String,
	_activity_id: String,
	source_id: String,
	_reason: String
) -> void:
	if source_id == SOURCE_ID:
		_pending_incident_requests.erase(request_id)


func _on_activity_cancelled(
	request_id: String,
	_activity_id: String,
	source_id: String,
	_reason: String
) -> void:
	if source_id == SOURCE_ID:
		_pending_incident_requests.erase(request_id)


func _finish_activity(transaction_id: String, activity_id: String) -> void:
	if transaction_id.strip_edges().is_empty():
		return

	ActivityManager.complete_activity(transaction_id, activity_id)


func _create_context(
	lead_id: String,
	target_id: String,
	location_id: String,
	transaction_id: String
) -> GameEffectContext:
	return GameEffectContext.create(
		lead_id,
		target_id,
		location_id,
		transaction_id,
		target_id
	)


func _on_campaign_reset() -> void:
	_pending_incident_requests.clear()
