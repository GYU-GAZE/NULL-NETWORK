extends RefCounted
class_name PartnerLossService


const DEFAULT_INFESTATION_INCREASE: int = 1
const ENCYCLOPEDIA_ENTRY_CATEGORY: StringName = &"encyclopedia_entries"


static func resolve_after_combat(
	_outcome: CombatResult.Outcome,
	encounter_id: String,
	infestation_increase: int = DEFAULT_INFESTATION_INCREASE
) -> Dictionary:
	if not CampaignState.has_campaign() \
		or CampaignState.partner == null \
		or CampaignState.partner.is_empty() \
		or CampaignState.partner.current_hp > 0:
		return _empty_result()

	if PartnerContinuityService.is_turd_active():
		return OperatorLossService.resolve_after_combat(
			CampaignState.partner.duplicate_state(),
			encounter_id,
			maxi(
				OperatorLossService.DEFAULT_INFESTATION_INCREASE,
				infestation_increase
			)
		)

	return resolve_captured_primary_loss(
		CampaignState.partner.duplicate_state(),
		true,
		encounter_id,
		infestation_increase
	)


static func resolve_captured_primary_loss(
	lost_partner: PartnerStateData,
	activate_fallback: bool,
	encounter_id: String,
	infestation_increase: int = DEFAULT_INFESTATION_INCREASE
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
	var applied_infestation: int = maxi(0, infestation_increase)

	if not location_id.is_empty() and applied_infestation > 0:
		var previous_infestation: int = CampaignState.world_state.get_infestation(
			location_id
		)
		CampaignState.world_state.set_infestation(
			location_id,
			previous_infestation + applied_infestation
		)
		CampaignState.campaign_changed.emit(&"world_infestation")
		metadata["infestation_increase"] = applied_infestation

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
			"operator_lost": false,
			"legacy_site_id": "",
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
