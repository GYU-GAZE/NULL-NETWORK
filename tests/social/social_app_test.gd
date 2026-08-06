extends Node


const SOCIAL_SCENE: PackedScene = preload(
	"res://apps/social/app_social.tscn"
)

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected Social App content: %s"
		% catalog_errors
	)

	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ActivityManager.reset_runtime_state()
	_check(
		CampaignState.create_campaign(
			"social_app_projection",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the Social App fixture campaign."
	)
	CampaignState.operator.display_name = "TEST OPERATOR"

	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_activity_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_activity_confirmation_requested
		)

	var app := SOCIAL_SCENE.instantiate() as SocialApp
	_check(app != null, "Social App scene did not instantiate SocialApp.")

	if app == null:
		_finish_test()
		return

	add_child(app)
	app.size = Vector2(760, 480)
	await _wait_frames(8)

	_check(
		app.get_contact_count() == 1,
		"Social App did not project the unlocked Ganbarekun contact."
	)
	_check(
		app.get_selected_conversation_id() == "dm.ganbarekun",
		"Social App did not select the first available conversation."
	)
	_check(
		app.get_rendered_message_count() == 1,
		"Social App did not render the initial immutable chat message."
	)
	_check(
		app.get_rendered_choice_count() == 1,
		"Social App did not render the available data-driven response."
	)

	var initial_action_index: int = TimeManager.get_total_action_index()
	_check(
		app.press_choice("ask_about_field_test"),
		"Social App could not press the rendered response choice."
	)

	for _frame: int in range(30):
		await get_tree().process_frame

		if app.get_rendered_message_count() == 3:
			break

	_check(
		app.get_rendered_message_count() == 3,
		"Social App did not refresh after the interaction messages arrived."
	)
	_check(
		app.get_rendered_choice_count() == 0,
		"Social App kept an already consumed ONCE response visible."
	)
	_check(
		SocialService.get_affinity("ganbarekun") == 2,
		"Social App flow did not apply the interaction affinity effect."
	)
	_check(
		CampaignState.active_lead_ids.has("integration_field_test"),
		"Social App flow did not activate the interaction Lead."
	)
	_check(
		TimeManager.get_total_action_index() == initial_action_index + 1,
		"Social App flow did not charge exactly one action block."
	)

	app.queue_free()
	await _wait_frames(3)

	var reopened_app := SOCIAL_SCENE.instantiate() as SocialApp
	_check(reopened_app != null, "Social App could not be reopened.")

	if reopened_app != null:
		add_child(reopened_app)
		reopened_app.size = Vector2(760, 480)
		await _wait_frames(8)
		_check(
			reopened_app.get_rendered_message_count() == 3
			and reopened_app.get_rendered_choice_count() == 0,
			"Reopened Social App did not project persistent conversation state."
		)
		reopened_app.queue_free()

	await _wait_frames(2)
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


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	ActivityManager.reset_runtime_state()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("SOCIAL_APP_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("SOCIAL_APP_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
