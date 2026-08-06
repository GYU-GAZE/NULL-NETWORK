extends "res://core/autoloads/operator_service.gd"


func register_operator(
	profile: OperatorProfileData,
	appearance: AppearanceData,
	tendency_values: Dictionary
) -> PackedStringArray:
	var is_successor_registration: bool = (
		CampaignState.campaign_phase
		== CampaignState.CampaignPhase.OPERATOR_LOSS
	)
	var errors: PackedStringArray = super.register_operator(
		profile,
		appearance,
		tendency_values
	)

	if not errors.is_empty() or not is_successor_registration:
		return errors

	CampaignState.campaign_phase = CampaignState.CampaignPhase.OPERATOR_CREATION
	CampaignState.campaign_changed.emit(&"campaign")
	SaveManager.request_checkpoint(
		&"operator.successor_registered",
		true
	)
	return errors
