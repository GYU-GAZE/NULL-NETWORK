extends RefCounted
class_name PartnerLossService


const DEFAULT_INFESTATION_INCREASE: int = 1
const ENCYCLOPEDIA_ENTRY_CATEGORY: StringName = &"encyclopedia_entries"


static func resolve_after_combat(
	_outcome: CombatResult.Outcome,
	encounter_id: String
) -> Dictionary:
	if not CampaignState.has_campaign() \
		or CampaignState.partner == null \
		or CampaignState.partner.is_empty() \
		or CampaignState.partner.current_hp > 0:
		return _empty_result()

	if PartnerContinuityService.is_turd_active():
		var operator_loss_result: Dictionary = _empty_result()
		var operator_loss_metadata: Dictionary = (
			operator_loss_result.get("metadata", {}) as Dictionary
		)
		operator_loss_metadata["operator_loss_required"] = true
		operator_loss_metadata["irreversible"] = true
		return operator_loss_result

	return resolve_captured_primary_loss(
		CampaignState.partner.duplicate_state(),
		true,
		encounter_id
	)


static func resolve_captured_primary_loss(
	lost_partner: PartnerStateData,
	activate_fallback: bool,
	encounter_id: String
) -> Dictionary:
	var result: Dictionary = _empty_result()
	var errors: PackedStringArray = result.get(
		"errors",
		PackedStringArray()
	)
	var metadata: Dictionary = result.get("metadata", {}) as Dictionary

	if not CampaignState.has_campaign() \
		or lost_partner == null \
		or lost_partner.is_empty() \
		or lost_partner.current_hp > 0 \
		or lost_partner.integrity_state == PartnerStateData.IntegrityState.TURD:
		return result

	var lost_apk_id: String = lost_partner.apk_id
	var loss_record: Dictionary = (
		PartnerContinuityService.resolve_primary_partner_loss_from_snapshot(
			lost_partner,
			activate_fallback,
			"combat_hp_zero",
			CampaignState.current_location_id,
			TimeManager.days_passed,
			TimeManager.get_total_action_index(),
			encounter_id
		)
	)

	if loss_record.is_empty():
		errors.append("Could not archive the defeated primary partner.")
		return result

	metadata["partner_lost"] = true
	metadata["lost_apk_id"] = lost_apk_id
	metadata["turd_assigned"] = (
		PartnerContinuityService.is_turd_active()
		or PartnerContinuityService.has_turd_reserve()
	)
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
	return result


static func _empty_result() -> Dictionary:
	return {
		"errors": PackedStringArray(),
		"metadata": {
			"partner_lost": false,
			"lost_apk_id": "",
			"turd_assigned": false,
			"operator_loss_required": false,
			"infestation_increase": 0,
			"irreversible": false
		}
	}


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
