extends RefCounted
class_name PartnerLossService


const DEFAULT_INFESTATION_INCREASE: int = 1
const ENCYCLOPEDIA_ENTRY_CATEGORY: StringName = &"encyclopedia_entries"


static func resolve_after_combat(
	_outcome: CombatResult.Outcome,
	encounter_id: String
) -> Dictionary:
	var errors := PackedStringArray()
	var metadata: Dictionary = {
		"partner_lost": false,
		"lost_apk_id": "",
		"turd_assigned": false,
		"operator_loss_required": false,
		"infestation_increase": 0,
		"irreversible": false
	}

	if not CampaignState.has_campaign() \
		or CampaignState.partner == null \
		or CampaignState.partner.is_empty() \
		or CampaignState.partner.current_hp > 0:
		return {"errors": errors, "metadata": metadata}

	if PartnerContinuityService.is_turd_active():
		metadata["operator_loss_required"] = true
		metadata["irreversible"] = true
		return {"errors": errors, "metadata": metadata}

	var lost_apk_id: String = CampaignState.partner.apk_id
	var loss_record: Dictionary = (
		PartnerContinuityService.resolve_primary_partner_loss(
			"combat_hp_zero",
			CampaignState.current_location_id,
			TimeManager.days_passed,
			TimeManager.get_total_action_index(),
			encounter_id
		)
	)

	if loss_record.is_empty():
		errors.append("Could not archive the defeated primary partner.")
		return {"errors": errors, "metadata": metadata}

	metadata["partner_lost"] = true
	metadata["lost_apk_id"] = lost_apk_id
	metadata["turd_assigned"] = PartnerContinuityService.is_turd_active()
	metadata["irreversible"] = true

	var location_id: String = CampaignState.current_location_id.strip_edges()

	if not location_id.is_empty():
		var previous_infestation: int = CampaignState.world_state.get_infestation(
			location_id
		)
		CampaignState.world_state.set_infestation(
			location_id,
			previous_infestation + DEFAULT_INFESTATION_INCREASE
		)
		CampaignState.campaign_changed.emit(&"world_infestation")
		metadata["infestation_increase"] = DEFAULT_INFESTATION_INCREASE

	_mark_apk_lost_in_encyclopedia(
		lost_apk_id,
		"partner_loss.%s.%d" % [
			encounter_id.strip_edges(),
			TimeManager.get_total_action_index()
		]
	)
	return {"errors": errors, "metadata": metadata}


static func _mark_apk_lost_in_encyclopedia(
	apk_id: String,
	observation_id: String
) -> void:
	var clean_apk_id: String = apk_id.strip_edges()

	if clean_apk_id.is_empty():
		return

	for resource: Resource in ContentRegistry.get_all(
		ENCYCLOPEDIA_ENTRY_CATEGORY
	):
		var entry := resource as EncyclopediaEntryData

		if entry == null \
			or entry.subject_apk_id.strip_edges() != clean_apk_id:
			continue

		EncyclopediaService.mark_lost(
			entry.get_display_id(),
			observation_id
		)
		return
