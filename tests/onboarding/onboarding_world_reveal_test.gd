extends Node


const NAVIGATOR_SCENE: PackedScene = preload(
	"res://apps/navigator/app_navigator.tscn"
)
const REGISTRATION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/operator_succession_registration.tscn"
)

var _failures := PackedStringArray()
var _test_root: String


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/onboarding_world_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var registry_errors := ContentRegistry.reset_to_default_catalog()
	_check(registry_errors.is_empty(), "Default catalog failed: %s" % registry_errors)

	await _test_registration_handoff_relay()
	await _test_navigator_blackout_and_world_reveal()
	_finish_test()


func _test_registration_handoff_relay() -> void:
	var page := REGISTRATION_SCENE.instantiate() as OperatorCreationRevampedPage
	_check(page != null, "Registration scene did not instantiate the revamped result page.")
	if page == null:
		return
	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.size = Vector2(832, 393)
	add_child(page)
	await _wait_frames(2)

	_check(
		page.find_child("OnboardingHandoffRelay", true, false) != null,
		"Registration scene is missing its decoupled onboarding handoff relay."
	)

	var relayed_operator_id := ""
	var relay_callback := func(operator_id: String) -> void:
		relayed_operator_id = operator_id
	GlobalSignals.onboarding_handoff_requested.connect(relay_callback, CONNECT_ONE_SHOT)
	page.onboarding_handoff_requested.emit("operator.test")
	await get_tree().process_frame
	_check(
		relayed_operator_id == "operator.test",
		"Registration completion did not relay the onboarding handoff globally."
	)
	_check(
		not page.open_channel_button.visible and page.open_channel_button.disabled,
		"Legacy OPEN NULL CHANNEL fallback became visible during world handoff."
	)

	page.queue_free()
	await _wait_frames(2)


func _test_navigator_blackout_and_world_reveal() -> void:
	CampaignState.reset_campaign()
	_check(
		CampaignState.create_campaign(
			"onboarding-world-test",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.PROLOGUE
		),
		"Could not create onboarding test campaign."
	)

	var safehouse := ContentRegistry.get_location("operator_safehouse")
	_check(safehouse != null, "Operator safehouse is not registered in ContentRegistry.")
	_check(
		safehouse != null and safehouse.local_area != null and safehouse.local_area.is_valid(),
		"Operator safehouse does not resolve a valid LocalAreaData scene."
	)

	var navigator := NAVIGATOR_SCENE.instantiate() as OperatorLossNavigator
	_check(navigator != null, "Navigator scene is not using OperatorLossNavigator.")
	if navigator == null:
		return

	var presentation := navigator.onboarding_presentation_data.duplicate(true) as PrologueOnboardingPresentationData
	presentation.reveal_duration_seconds = 0.05
	navigator.onboarding_presentation_data = presentation
	navigator.set_anchors_preset(Control.PRESET_TOP_LEFT)
	navigator.size = Vector2(832, 393)
	add_child(navigator)
	await _wait_frames(3)

	_check(
		navigator.is_onboarding_blackout_active(),
		"Navigator must remain completely black before first synchronization."
	)
	_check(
		navigator.onboarding_blackout.mouse_filter == Control.MOUSE_FILTER_STOP,
		"Pre-onboarding Navigator blackout must block interaction."
	)

	navigator._set_app_active(true)
	await navigator.reveal_onboarding_world()
	await _wait_frames(2)

	_check(
		GameState.get_flag(presentation.world_revealed_flag, false),
		"World reveal did not persist its completion flag."
	)
	_check(
		CampaignState.current_location_id == "operator_safehouse",
		"World reveal did not move the Operator into the safehouse."
	)
	_check(
		navigator.local_area_view.get_current_area_data() != null
		and navigator.local_area_view.get_current_area_data().get_display_id() == "operator_safehouse_room",
		"Navigator did not load the Operator room as the first Local Area."
	)
	_check(
		not navigator.is_onboarding_blackout_active(),
		"Navigator blackout did not clear after the radial reveal."
	)
	_check(
		navigator.local_area_view.get_current_area_instance() != null,
		"Operator room did not instantiate a playable local-area scene."
	)
	if navigator.local_area_view.get_current_area_instance() != null:
		_check(
			navigator.local_area_view.get_current_player_position() == Vector2(320, 238),
			"Safehouse reveal is not centered on the authored player entry point."
		)

	navigator.queue_free()
	CampaignState.reset_campaign()
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("ONBOARDING_WORLD_REVEAL_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	print("ONBOARDING_WORLD_REVEAL_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
