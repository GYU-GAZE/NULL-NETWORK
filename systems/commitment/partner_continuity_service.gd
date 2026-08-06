extends RefCounted
class_name PartnerContinuityService


static func is_turd_active() -> bool:
	return (
		CampaignState.partner != null
		and not CampaignState.partner.is_empty()
		and CampaignState.partner.integrity_state \
		== PartnerStateData.IntegrityState.TURD
	)


static func has_turd_reserve() -> bool:
	return (
		not CampaignState.operator.is_empty()
		and CampaignState.operator.partner_continuity.has_turd_reserve()
	)


static func stash_turd_snapshot(state: PartnerStateData) -> bool:
	if CampaignState.operator.is_empty():
		return false

	var stashed: bool = CampaignState.operator.partner_continuity.stash_turd(
		state
	)

	if stashed:
		CampaignState.campaign_changed.emit(&"operator")

	return stashed


static func replace_partner_from_tame(
	new_partner: PartnerStateData
) -> bool:
	if CampaignState.operator.is_empty() \
		or new_partner == null \
		or new_partner.is_empty() \
		or new_partner.integrity_state == PartnerStateData.IntegrityState.TURD \
		or not APKProgressionService.validate_partner_state(new_partner).is_empty():
		return false

	var previous_partner: PartnerStateData = (
		CampaignState.partner.duplicate_state()
		if CampaignState.partner != null and not CampaignState.partner.is_empty()
		else null
	)

	if not CampaignState.set_partner_state(new_partner):
		return false

	if previous_partner != null \
		and previous_partner.integrity_state \
		== PartnerStateData.IntegrityState.TURD:
		if not stash_turd_snapshot(previous_partner):
			CampaignState.set_partner_state(previous_partner)
			return false

	return true


static func resolve_primary_partner_loss(
	reason: String,
	location_id: String,
	game_day: int,
	action_index: int,
	encounter_id: String = ""
) -> Dictionary:
	if CampaignState.partner == null \
		or CampaignState.partner.is_empty():
		return {}

	return resolve_primary_partner_loss_from_snapshot(
		CampaignState.partner.duplicate_state(),
		true,
		reason,
		location_id,
		game_day,
		action_index,
		encounter_id
	)


static func resolve_primary_partner_loss_from_snapshot(
	lost_partner: PartnerStateData,
	activate_fallback: bool,
	reason: String,
	location_id: String,
	game_day: int,
	action_index: int,
	encounter_id: String = ""
) -> Dictionary:
	if CampaignState.operator.is_empty() \
		or lost_partner == null \
		or lost_partner.is_empty() \
		or lost_partner.integrity_state == PartnerStateData.IntegrityState.TURD:
		return {}

	var continuity: PartnerContinuityStateData = (
		CampaignState.operator.partner_continuity
	)
	var fallback: PartnerStateData = null
	var used_reserve: bool = false

	if activate_fallback:
		fallback = continuity.take_turd()
		used_reserve = fallback != null

		if fallback == null:
			fallback = TurdPartnerFactory.create_state()

		if fallback == null or not CampaignState.set_partner_state(fallback):
			if used_reserve and fallback != null:
				continuity.stash_turd(fallback)
			return {}
	elif not continuity.has_turd_reserve():
		fallback = TurdPartnerFactory.create_state()

		if fallback == null or not continuity.stash_turd(fallback):
			return {}

	var record: Dictionary = continuity.archive_lost_partner(
		lost_partner,
		reason,
		location_id,
		game_day,
		action_index,
		encounter_id
	)
	CampaignState.campaign_changed.emit(&"operator")
	return record


static func get_turd_state_snapshot() -> PartnerStateData:
	if is_turd_active():
		return CampaignState.partner.duplicate_state()

	if has_turd_reserve():
		var continuity: PartnerContinuityStateData = (
			CampaignState.operator.partner_continuity
		)
		return continuity.turd_reserve.duplicate_state()

	return null


static func get_lost_partner_history() -> Array[Dictionary]:
	if CampaignState.operator.is_empty():
		return []

	return CampaignState.operator.partner_continuity.get_lost_partner_history()
