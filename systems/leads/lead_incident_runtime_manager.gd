extends "res://core/autoloads/lead_incident_manager.gd"


## Concrete runtime boundary for Lead/Incident campaign state.
##
## Older Phase-12 Social content activated Leads directly in CampaignState.
## That stored the active Lead ID but skipped its initial stage, which made the
## Navigator badge appear while the Incident actor itself could never spawn.
## This runtime repairs that malformed state and keeps all future activation
## routed through LeadIncidentManager.activate_lead().

var _is_repairing_active_leads: bool = false


func _ready() -> void:
	super._ready()

	if not CampaignState.campaign_created.is_connected(
		_on_campaign_created_runtime
	):
		CampaignState.campaign_created.connect(
			_on_campaign_created_runtime
		)

	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_changed_runtime
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_changed_runtime
		)

	call_deferred("_repair_active_lead_progress")


func activate_lead(
	lead_id: String,
	source_id: String = ""
) -> bool:
	var activated: bool = super.activate_lead(lead_id, source_id)

	if activated:
		_repair_active_lead_progress()

	return activated


func get_active_leads_for_location(
	location_id: String
) -> Array[LeadData]:
	_repair_active_lead_progress()
	return super.get_active_leads_for_location(location_id)


func get_available_incidents_for_location(
	location_id: String
) -> Array[IncidentData]:
	_repair_active_lead_progress()
	return super.get_available_incidents_for_location(location_id)


func find_lead_for_incident(incident_id: String) -> LeadData:
	_repair_active_lead_progress()
	return super.find_lead_for_incident(incident_id)


func _on_campaign_created_runtime(_campaign_id: String) -> void:
	call_deferred("_repair_active_lead_progress")


func _on_campaign_changed_runtime(section: StringName) -> void:
	if section not in [&"campaign", &"leads"]:
		return

	call_deferred("_repair_active_lead_progress")


func _repair_active_lead_progress() -> void:
	if _is_repairing_active_leads or not CampaignState.has_campaign():
		return

	_is_repairing_active_leads = true
	var repaired_ids := PackedStringArray()

	for lead_id: String in CampaignState.active_lead_ids:
		var lead: LeadData = ContentRegistry.get_lead(lead_id)

		if lead == null:
			continue

		var progress: Dictionary = CampaignState.get_lead_progress(lead_id)
		var stage_id: String = str(
			progress.get("stage_id", "")
		).strip_edges()

		if lead.get_stage(stage_id) != null:
			continue

		var initial_stage: LeadStageData = lead.get_initial_stage()

		if initial_stage == null:
			continue

		var repaired_progress: Dictionary = progress.duplicate(true)
		repaired_progress["stage_id"] = initial_stage.get_display_id()

		if str(repaired_progress.get("source_id", "")).strip_edges().is_empty():
			repaired_progress["source_id"] = "legacy.phase12.social"

		if not repaired_progress.has("activated_action_index"):
			repaired_progress["activated_action_index"] = (
				TimeManager.get_total_action_index()
			)

		CampaignState.set_lead_progress(lead_id, repaired_progress)
		repaired_ids.append(lead_id)

	_is_repairing_active_leads = false

	if repaired_ids.is_empty():
		return

	for lead_id: String in repaired_ids:
		lead_state_changed.emit(lead_id)

	SaveManager.request_checkpoint(
		&"leads.repair_active_progress",
		false
	)
