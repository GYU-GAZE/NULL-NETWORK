extends Node


const REGISTRATION_SCENE: PackedScene = preload(
	"res://apps/browser/sites/null_network/register/operator_creation.tscn"
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
	_test_root = "user://null_network/tests/initial_starter_selection_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected initial starter selection content: %s"
		% catalog_errors
	)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"phase15_initial_starter_selection",
		CampaignState.SaveMode.SAFE,
		"Initial Starter Selection"
	)
	_check(
		create_errors.is_empty(),
		"Could not create initial starter selection campaign: %s" % create_errors
	)
	CampaignState.campaign_phase = CampaignState.CampaignPhase.PROLOGUE

	var registration_page := (
		REGISTRATION_SCENE.instantiate()
		as OperatorCreationPage
	)
	_check(
		registration_page != null,
		"Could not instantiate the initial Operator registration page."
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
		"Could not register the first Operator fixture: %s"
		% registration_errors
	)
	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE,
		"Initial registration unexpectedly left PROLOGUE."
	)

	if registration_page != null:
		registration_page.registration_completed.emit(
			CampaignState.operator.operator_id
		)
		await get_tree().process_frame
		await get_tree().process_frame

	_check(
		_captured_navigation_url == "null.net/select-starter",
		"First Operator registration did not navigate to starter selection."
	)

	var selection_page := (
		STARTER_SELECTION_SCENE.instantiate()
		as StarterSelectionPage
	)
	_check(
		selection_page != null,
		"Could not instantiate the generic starter selection page."
	)

	if selection_page != null:
		add_child(selection_page)
		await get_tree().process_frame
		var intro := selection_page.get_node_or_null(
			"MasterScroll/PageMargin/Page/Intro"
		) as Label
		var state := selection_page.get_node_or_null(
			"MasterScroll/PageMargin/Page/StateLabel"
		) as Label
		var navigator_button := selection_page.get_node_or_null(
			"MasterScroll/PageMargin/Page/Actions/OpenNavigatorButton"
		) as Button
		var visible_copy: String = (
			("%s %s" % [intro.text, state.text]).to_lower()
			if intro != null and state != null
			else ""
		)
		_check(
			intro != null and state != null
			and not visible_copy.contains("successor")
			and not visible_copy.contains("previous operator"),
			"Starter selection still exposes succession-specific copy."
		)
		_check(
			selection_page.get_available_starter_ids().has("novire_init"),
			"Initial PROLOGUE selection did not expose cataloged starters."
		)
		_check(
			selection_page.select_starter_entry("novire_init"),
			"Initial PROLOGUE selection could not select NOVIRE."
		)
		var selection_errors: PackedStringArray = (
			selection_page.confirm_selected_starter(
				"First Novi",
				0,
				0
			)
		)
		_check(
			selection_errors.is_empty(),
			"Initial PROLOGUE starter confirmation failed: %s"
			% selection_errors
		)
		_check(
			CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE
			and CampaignState.partner.apk_id == "novire_init"
			and CampaignState.partner.nickname == "First Novi",
			"Initial starter selection did not preserve PROLOGUE and create the partner."
		)
		_check(
			not CampaignState.has_installed_app("navigator")
			and navigator_button != null
			and not navigator_button.visible,
			"Initial starter selection exposed Navigator before the Prologue installs it."
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
	profile.first_name = "First"
	profile.last_name = "Operator"
	profile.nickname = "First"
	profile.username = "initial_starter_page_test"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_initial"
	appearance.face_id = "face_initial"
	appearance.eye_id = "eyes_initial"
	appearance.outer_layer_id = "outer_initial"
	appearance.middle_layer_id = "middle_initial"
	appearance.lower_layer_id = "lower_initial"
	appearance.hat_id = "hat_initial"
	appearance.facial_accessory_id = "accessory_initial"
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
		print("INITIAL_STARTER_SELECTION_PAGE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"INITIAL_STARTER_SELECTION_PAGE_TEST: FAIL (%d)"
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
