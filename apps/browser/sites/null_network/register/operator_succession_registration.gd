extends OperatorCreationPage
class_name OperatorSuccessionRegistrationPage


const STARTER_SELECTION_URL: String = "null.net/select-starter"


func _ready() -> void:
	super._ready()

	if not registration_completed.is_connected(
		_on_registration_completed
	):
		registration_completed.connect(_on_registration_completed)


func _on_registration_completed(_operator_id: String) -> void:
	if CampaignState.campaign_phase \
		!= CampaignState.CampaignPhase.OPERATOR_CREATION \
		or CampaignState.operator_history.is_empty() \
		or CampaignState.operator.is_empty() \
		or not CampaignState.partner.is_empty():
		return

	call_deferred("_open_starter_selection")


func _open_starter_selection() -> void:
	GlobalSignals.request_browser_navigation.emit(
		STARTER_SELECTION_URL,
		"operator_registration",
		"successor_starter_selection"
	)
