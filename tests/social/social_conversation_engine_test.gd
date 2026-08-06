extends Node


const CONVERSATION_ID: String = "dm.ganbarekun"
const INTERACTION_ID: String = "social.ganbarekun.field_test_tip"

var _failures := PackedStringArray()
var _completed_interaction_id: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected social conversation content: %s"
		% catalog_errors
	)

	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ActivityManager.reset_runtime_state()
	_check(
		CampaignState.create_campaign(
			"social_conversation_engine",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the social conversation fixture campaign."
	)
	CampaignState.operator.display_name = "TEST OPERATOR"

	_check(
		ContentRegistry.get_chat_profile("chat.ganbarekun") != null,
		"Ganbarekun chat profile was not registered."
	)
	_check(
		ContentRegistry.get_chat_conversation(CONVERSATION_ID) != null,
		"Ganbarekun conversation was not registered."
	)
	_check(
		ContentRegistry.get_social_interaction(INTERACTION_ID) != null,
		"Ganbarekun interaction was not registered."
	)

	_check(
		SocialService.open_conversation(CONVERSATION_ID),
		"SocialService could not open the Ganbarekun conversation."
	)
	_check(
		SocialService.has_contact("ganbarekun"),
		"Opening the conversation did not discover the contact."
	)
	_check(
		SocialService.get_conversation_history(CONVERSATION_ID).size() == 1,
		"Initial message was not delivered exactly once."
	)
	_check(
		SocialService.get_resolved_conversation_history(
			CONVERSATION_ID
		).size() == 1,
		"Saved message ID did not resolve back into chat content."
	)
	_check(
		SocialService.get_available_chat_choices(CONVERSATION_ID).size() == 1,
		"The integration chat choice was not available."
	)

	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_activity_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_activity_confirmation_requested
		)

	if not SocialService.interaction_completed.is_connected(
		_on_interaction_completed
	):
		SocialService.interaction_completed.connect(
			_on_interaction_completed
		)

	var initial_action_index: int = TimeManager.get_total_action_index()
	_check(
		SocialService.select_chat_choice(
			CONVERSATION_ID,
			"ask_about_field_test"
		),
		"SocialService rejected the valid chat choice."
	)

	for _frame: int in range(12):
		await get_tree().process_frame

		if _completed_interaction_id == INTERACTION_ID:
			break

	_check(
		_completed_interaction_id == INTERACTION_ID,
		"The confirmed social interaction did not complete."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 1,
		"The social interaction did not charge exactly one action block."
	)
	_check(
		SocialService.get_conversation_history(CONVERSATION_ID).size() == 3,
		"Operator and NPC response messages were not appended."
	)
	_check(
		SocialService.get_affinity("ganbarekun") == 2,
		"The data-driven affinity effect did not execute."
	)
	_check(
		CampaignState.active_lead_ids.has("integration_field_test"),
		"The data-driven Lead effect did not execute."
	)
	_check(
		SocialService.get_interaction_execution_count(INTERACTION_ID) == 1,
		"The interaction execution count was not recorded."
	)
	_check(
		SocialService.get_available_chat_choices(CONVERSATION_ID).is_empty(),
		"A completed ONCE interaction remained available."
	)
	_check(
		not SocialService.select_chat_choice(
			CONVERSATION_ID,
			"ask_about_field_test"
		),
		"A completed ONCE interaction executed twice."
	)

	var saved_campaign: Dictionary = CampaignState.export_save_data()
	CampaignState.reset_campaign()
	var restore_errors: PackedStringArray = CampaignState.restore_save_data(
		saved_campaign
	)
	_check(
		restore_errors.is_empty(),
		"CampaignState rejected the social conversation round-trip: %s"
		% restore_errors
	)
	_check(
		SocialService.has_contact("ganbarekun")
		and SocialService.get_affinity("ganbarekun") == 2
		and SocialService.get_conversation_history(CONVERSATION_ID).size() == 3
		and SocialService.get_interaction_execution_count(INTERACTION_ID) == 1,
		"Social conversation state did not survive CampaignState restore."
	)

	_finish_test()


func _on_activity_confirmation_requested(
	request_id: String,
	_definition: ActivityDefinitionData,
	_preview: ActivityPreviewData,
	_source_id: String
) -> void:
	call_deferred("_confirm_activity", request_id)


func _confirm_activity(request_id: String) -> void:
	GlobalSignals.activity_confirmation_resolved.emit(request_id, true)


func _on_interaction_completed(
	interaction_id: String,
	_conversation_id: String
) -> void:
	_completed_interaction_id = interaction_id


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	ActivityManager.reset_runtime_state()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("SOCIAL_CONVERSATION_ENGINE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"SOCIAL_CONVERSATION_ENGINE_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
