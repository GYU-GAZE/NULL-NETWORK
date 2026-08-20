extends Node


const NAVIGATOR_SCENE: PackedScene = preload(
	"res://apps/navigator/app_navigator.tscn"
)
const REGISTRATION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/operator_succession_registration.tscn"
)
const WORKSPACE_MANAGER_SCENE: PackedScene = preload(
	"res://systems/workspace/workspace_manager.tscn"
)
const WINDOW_MANAGER_SCENE: PackedScene = preload(
	"res://systems/window_manager/window_manager.tscn"
)
const HANDOFF_SCENE: PackedScene = preload(
	"res://systems/onboarding/prologue_onboarding_handoff_controller.tscn"
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
	await _test_complete_browser_to_navigator_handoff()
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

	var relay := page.find_child(
		"OnboardingHandoffRelay",
		true,
		false
	) as OperatorRegistrationHandoffRelay
	_check(
		relay != null,
		"Registration scene is missing its decoupled onboarding handoff relay."
	)
	_check(
		is_instance_valid(page.open_channel_button),
		"Registration page did not resolve OpenChannelButton after parent ready."
	)
	_check(
		relay != null and relay.is_bound_to_page(),
		"Onboarding handoff relay did not wait for the registration page ready boundary before binding controls."
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


func _test_complete_browser_to_navigator_handoff() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	GameState.reset_save_data()
	var create_errors := SaveManager.create_campaign(
		"onboarding-handoff-test",
		CampaignState.SaveMode.SAFE,
		"Onboarding Handoff"
	)
	_check(create_errors.is_empty(), "Handoff campaign creation failed: %s" % create_errors)

	var registration_errors := OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(registration_errors.is_empty(), "Handoff Operator registration failed: %s" % registration_errors)
	var starter_errors := APKProgressionService.select_starter("novire_init", "Novi", 0, 0)
	_check(starter_errors.is_empty(), "Handoff starter selection failed: %s" % starter_errors)
	await _wait_frames(5)
	_check(
		not GameState.get_flag("story.prologue.account_ready", false),
		"Legacy showcase account-ready flag still fires during the new synchronization flow."
	)

	var runtime := Control.new()
	runtime.name = "Runtime"
	runtime.set_anchors_preset(Control.PRESET_TOP_LEFT)
	runtime.size = Vector2(832, 393)
	add_child(runtime)

	var workspace_manager := WORKSPACE_MANAGER_SCENE.instantiate() as WorkspaceManager
	workspace_manager.name = "WorkspaceManager"
	workspace_manager.set_anchors_preset(Control.PRESET_FULL_RECT)
	runtime.add_child(workspace_manager)

	var window_manager := WINDOW_MANAGER_SCENE.instantiate() as WindowManager
	window_manager.name = "WindowManager"
	window_manager.set_anchors_preset(Control.PRESET_FULL_RECT)
	runtime.add_child(window_manager)

	var handoff := HANDOFF_SCENE.instantiate() as PrologueOnboardingHandoffController
	handoff.name = "Handoff"
	handoff.workspace_manager_path = NodePath("../WorkspaceManager")
	handoff.window_manager_path = NodePath("../WindowManager")
	runtime.add_child(handoff)
	await _wait_frames(4)

	_check(
		workspace_manager.get_active_workspace_id() == "navigator",
		"Prologue controller did not stage the black Navigator workspace before handoff."
	)
	var navigator := workspace_manager.get_active_workspace_instance() as OperatorLossNavigator
	_check(navigator != null, "Staged Navigator workspace has the wrong runtime type.")
	if navigator != null:
		var presentation := navigator.onboarding_presentation_data.duplicate(true) as PrologueOnboardingPresentationData
		presentation.reveal_duration_seconds = 0.05
		navigator.onboarding_presentation_data = presentation
		_check(
			navigator.is_onboarding_blackout_active(),
			"Staged Navigator was visible before synchronization handoff."
		)

	if not CampaignState.has_installed_app("browser"):
		_check(
			AppInstallationManager.install_app("browser", null, false, true),
			"Could not install Browser for handoff integration test."
		)
	var browser_app := ContentRegistry.get_app("browser")
	_check(browser_app != null, "Browser AppResource is missing in handoff test.")
	if browser_app != null:
		GlobalSignals.request_open_app.emit(browser_app)
	await _wait_frames(4)
	_check(
		window_manager.open_windows.has("browser"),
		"Browser did not open before onboarding handoff."
	)

	GlobalSignals.onboarding_handoff_requested.emit(
		CampaignState.operator.operator_id
	)
	await get_tree().create_timer(0.9).timeout
	await _wait_frames(4)

	_check(
		not window_manager.open_windows.has("browser"),
		"Browser did not close as part of onboarding handoff."
	)
	_check(
		workspace_manager.get_active_workspace_id() == "navigator",
		"Navigator stopped being the active workspace during Browser close."
	)
	_check(
		GameState.get_flag("prologue.onboarding_world_revealed", false),
		"Integrated onboarding handoff never completed the world reveal."
	)
	_check(
		CampaignState.current_location_id == "operator_safehouse",
		"Integrated onboarding handoff did not finish inside the safehouse."
	)

	runtime.queue_free()
	CampaignState.reset_campaign()
	await _wait_frames(3)


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Onboarding"
	profile.last_name = "Test"
	profile.nickname = "Operator"
	profile.username = "onboarding_test"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_test"
	appearance.face_id = "face_test"
	appearance.eye_id = "eyes_test"
	appearance.outer_layer_id = "outer_test"
	appearance.middle_layer_id = "middle_test"
	appearance.lower_layer_id = "lower_test"
	appearance.hat_id = "hat_test"
	appearance.facial_accessory_id = "accessory_test"
	return appearance


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	GameState.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("ONBOARDING_WORLD_REVEAL_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	print("ONBOARDING_WORLD_REVEAL_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
