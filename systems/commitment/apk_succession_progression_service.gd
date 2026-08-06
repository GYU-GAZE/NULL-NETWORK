extends "res://systems/progression/apk_progression_service.gd"


func select_starter(
	apk_id: String,
	nickname: String = "",
	personality_roll: int = -1,
	address_term_roll: int = -1
) -> PackedStringArray:
	var completes_succession: bool = (
		CampaignState.campaign_phase
		== CampaignState.CampaignPhase.OPERATOR_CREATION
		and not CampaignState.operator_history.is_empty()
	)
	var errors: PackedStringArray = super.select_starter(
		apk_id,
		nickname,
		personality_roll,
		address_term_roll
	)

	if not errors.is_empty() or not completes_succession:
		return errors

	if not AppInstallationManager.install_app(
		"navigator",
		null,
		true,
		true
	):
		errors.append("Successor starter selection could not install Navigator.")
		return errors

	CampaignState.campaign_phase = CampaignState.CampaignPhase.MAIN_CAMPAIGN
	CampaignState.campaign_changed.emit(&"campaign")
	SaveManager.request_checkpoint(
		&"operator.succession_completed",
		true
	)
	return errors
