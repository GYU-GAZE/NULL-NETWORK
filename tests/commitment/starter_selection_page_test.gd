extends Node


const REGISTRATION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/operator_succession_registration.tscn"
)
const STARTER_SELECTION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/starter_selection/starter_selection.tscn"
)

var _failures := PackedStringArray()
var _captured_navigation_url: String = ""
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/starter_selection_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected starter selection content: %s"
		% catalog_errors
	)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"phase14_starter_selection_page",
		CampaignState.SaveMode.SAFE,
		"Successor Starter Selection"
	)
	_check(
		create_errors.is_empty(),
		"Could not create starter selection campaign: %s" % create_errors
	)
	CampaignState.operator_history.append({
		"operator": {"operator_id": "archived_operator"},
		"legacy_site_id": "legacy.archived_operator.0.0"
	})
	CampaignState.campaign_phase = CampaignState.CampaignPhase.OPERATOR_LOSS

	var registration_page := (
		REGISTRATION_SCENE.instantiate()
		as OperatorSuccessionRegistrationPage
	)
	_check(
		registration_page != null,
		"Could not instantiate the succession registration page."
	)

	if registration_page != null:
		add_child(registration_page)
		await get_tree().process_frame

	if not GlobalSignals.request_browser_navigation.is_connected(
		_on_browser_navigation_requested
	):
		GlobalSignals.request_browser_navigation.connect(
			_on_browser_navigation_requested
		)

	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register the successor fixture: %s"
		% registration_errors
	)
	_check(
		CampaignState.campaign_phase
		== CampaignState.CampaignPhase.OPERATOR_CREATION,
		"Successor registration did not enter OPERATOR_CREATION."
	)

	if registration_page != null:
		registration_page.registration_completed.emit(
			CampaignState.operator.operator_id
		)
		await get_tree().process_frame
		await get_tree().process_frame

	_check(
		_captured_navigation_url == "null.net/select-starter",
		"Successor registration did not navigate to the starter selection route."
	)
	_check(
		SimulatedDNS.fetch_page("null.net/select-starter") != null,
		"SimulatedDNS does not resolve the starter selection route."
	)

	var selection_page := (
		STARTER_SELECTION_SCENE.instantiate()
		as StarterSelectionPage
	)
	_check(
		selection_page != null,
		"Could not instantiate the starter selection page."
	)

	if selection_page != null:
		add_child(selection_page)
		await get_tree().process_frame
		var available_ids: PackedStringArray = (
			selection_page.get_available_starter_ids()
		)
		_check(
			available_ids.has("novire_init")
			and not available_ids.has("rattildus_init")
			and not available_ids.has("turd_init"),
			"Starter page did not filter catalog APKs by starter eligibility."
		)
		_check(
			selection_page.select_starter_entry("novire_init"),
			"Starter page could not select cataloged NOVIRE."
		)
		var selection_errors: PackedStringArray = (
			selection_page.confirm_selected_starter(
				"Second Novi",
				1,
				0
			)
		)
		_check(
			selection_errors.is_empty(),
			"Starter page could not confirm NOVIRE: %s" % selection_errors
		)

	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.MAIN_CAMPAIGN
		and CampaignState.partner.apk_id == "novire_init"
		and CampaignState.partner.nickname == "Second Novi"
		and CampaignState.has_installed_app("navigator"),
		"Starter page did not complete succession and install Navigator."
	)

	if registration_page != null:
		registration_page.queue_free()

	if selection_page != null:
		selection_page.queue_free()

	await get_tree().process_frame
	_finish_test()


func _on_browser_navigation_requested(
	url: String,
	_source_id: String,
	_request_id: String
) -> void:
	_captured_navigation_url = url.strip_edges()


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Successor"
	profile.last_name = "Operator"
	profile.nickname = "Second"
	profile.username = "successor_page_test"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_successor"
	appearance.face_id = "face_successor"
	appearance.eye_id = "eyes_successor"
	appearance.outer_layer_id = "outer_successor"
	appearance.middle_layer_id = "middle_successor"
	appearance.lower_layer_id = "lower_successor"
	appearance.hat_id = "hat_successor"
	appearance.facial_accessory_id = "accessory_successor"
	return appearance


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if GlobalSignals.request_browser_navigation.is_connected(
		_on_browser_navigation_requested
	):
		GlobalSignals.request_browser_navigation.disconnect(
			_on_browser_navigation_requested
		)

	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("STARTER_SELECTION_PAGE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"STARTER_SELECTION_PAGE_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)


func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()

	while not entry.is_empty():
		var child_path: String = "%s/%s" % [path, entry]

		if directory.current_is_dir():
			_remove_directory_recursive(child_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))

		entry = directory.get_next()

	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
