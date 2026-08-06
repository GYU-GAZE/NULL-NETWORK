extends Node


const PROFILE_SCENE: PackedScene = preload(
	"res://apps/profile/app_operator_profile.tscn"
)
const CAMPAIGN_ID: String = "phase13_profile_app"

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/profile_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	UniversalNotifications.clear_history()
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected Profile content: %s" % catalog_errors
	)

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 13 Profile"
	)
	_check(
		create_errors.is_empty(),
		"Could not create Profile fixture campaign: %s" % create_errors
	)
	_check(
		not CampaignState.has_installed_app("profile"),
		"Profile installed before the Operator received a partner."
	)

	var registration_errors: PackedStringArray = (
		OperatorService.register_operator(
			_make_profile(),
			_make_appearance(),
			{"valour": 4, "logic": 4, "sync": 4, "self": 3}
		)
	)
	_check(
		registration_errors.is_empty(),
		"Could not register Profile fixture Operator: %s"
		% registration_errors
	)
	_check(
		not CampaignState.has_installed_app("profile"),
		"Profile installed before starter selection."
	)

	var starter_errors: PackedStringArray = (
		APKProgressionService.select_starter(
			"novire_init",
			"Novi",
			0,
			0
		)
	)
	_check(
		starter_errors.is_empty(),
		"Could not select Profile fixture starter: %s" % starter_errors
	)
	await _wait_frames(8)
	_check(
		CampaignState.has_installed_app("profile"),
		"Partner condition did not auto-install Profile."
	)

	CampaignState.partner.affinity = 7
	CampaignState.notify_partner_changed()
	_check(
		CampaignState.grant_item("healing_patch", 2) == 2,
		"Could not grant Profile fixture inventory."
	)
	var exp_errors: PackedStringArray = APKProgressionService.grant_experience(20)
	_check(
		exp_errors.is_empty() and CampaignState.partner.level == 2,
		"Profile fixture partner did not reach level 2."
	)
	await _wait_frames(5)

	var app := PROFILE_SCENE.instantiate() as OperatorProfileApp
	_check(app != null, "Profile scene did not instantiate OperatorProfileApp.")

	if app == null:
		_finish_test()
		return

	add_child(app)
	app.size = Vector2(720, 600)
	await _wait_frames(8)
	_assert_profile_projection(app, "initial")

	CampaignState.modify_tendency(TendencyStateData.Tendency.LOGIC, 2)
	CampaignState.grant_item("healing_patch", 1)
	CampaignState.partner.affinity = 9
	CampaignState.notify_partner_changed()
	await _wait_frames(6)
	var live_snapshot: Dictionary = app.get_snapshot()
	var live_partner: Dictionary = live_snapshot.get("partner", {}) as Dictionary
	var live_tendencies: Array = live_snapshot.get("tendencies", []) as Array
	var logic_value: int = _find_tendency_value(live_tendencies, "logic")
	_check(
		logic_value == 6
		and int(live_partner.get("affinity", 0)) == 9
		and CampaignState.inventory.get_item_count("healing_patch") == 3,
		"Profile did not refresh from live campaign mutations."
	)

	_check(
		SaveManager.save_checkpoint(&"phase13.profile", true),
		"Could not save Profile checkpoint."
	)
	app.queue_free()
	await _wait_frames(3)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	var load_errors: PackedStringArray = SaveManager.load_campaign(CAMPAIGN_ID)
	_check(
		load_errors.is_empty(),
		"Profile campaign reload failed: %s" % load_errors
	)
	await _wait_frames(6)
	_check(
		CampaignState.has_installed_app("profile"),
		"Profile installation did not survive campaign reload."
	)

	var reopened_app := PROFILE_SCENE.instantiate() as OperatorProfileApp
	_check(reopened_app != null, "Profile could not be reopened after reload.")

	if reopened_app != null:
		add_child(reopened_app)
		reopened_app.size = Vector2(720, 600)
		await _wait_frames(8)
		_assert_profile_projection(reopened_app, "restored")
		var restored_snapshot: Dictionary = reopened_app.get_snapshot()
		var restored_partner: Dictionary = (
			restored_snapshot.get("partner", {}) as Dictionary
		)
		_check(
			int(restored_partner.get("affinity", 0)) == 9
			and CampaignState.inventory.get_item_count("healing_patch") == 3
			and _find_tendency_value(
				restored_snapshot.get("tendencies", []) as Array,
				"logic"
			) == 6,
			"Profile projection did not preserve live updates across reload."
		)
		reopened_app.queue_free()

	await _wait_frames(2)
	_finish_test()


func _assert_profile_projection(
	app: OperatorProfileApp,
	boundary: String
) -> void:
	var snapshot: Dictionary = app.get_snapshot()
	var operator_data: Dictionary = snapshot.get("operator", {}) as Dictionary
	var partner_data: Dictionary = snapshot.get("partner", {}) as Dictionary
	var inventory: Array = snapshot.get("inventory", []) as Array

	_check(
		bool(snapshot.get("has_campaign", false))
		and str(operator_data.get("username", "")) == "profile_operator"
		and str(operator_data.get("occupation_id", "")) == "neet"
		and app.get_operator_name_text() == "Operator",
		"%s Profile did not project Operator identity and occupation."
		% boundary.capitalize()
	)
	_check(
		str(partner_data.get("apk_id", "")) == "novire_init"
		and int(partner_data.get("level", 0)) == 2
		and app.get_partner_level_text() == "LEVEL 2",
		"%s Profile did not project partner identity and level."
		% boundary.capitalize()
	)
	_check(
		(snapshot.get("tendencies", []) as Array).size() == 4,
		"%s Profile did not project all four Operator tendencies."
		% boundary.capitalize()
	)
	_check(
		app.get_rendered_equipped_module_count() == 4,
		"%s Profile did not render four equipped Module slots."
		% boundary.capitalize()
	)
	_check(
		inventory.size() == 1
		and app.get_rendered_inventory_count() == 1
		and str((inventory[0] as Dictionary).get("item_id", "")) \
		== "healing_patch",
		"%s Profile did not project the typed inventory entry."
		% boundary.capitalize()
	)


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Gyu"
	profile.last_name = "Profile"
	profile.nickname = "Operator"
	profile.username = "profile_operator"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_profile"
	appearance.face_id = "face_profile"
	appearance.eye_id = "eyes_profile"
	appearance.outer_layer_id = "outer_profile"
	appearance.middle_layer_id = "middle_profile"
	appearance.lower_layer_id = "lower_profile"
	appearance.hat_id = "hat_profile"
	appearance.facial_accessory_id = "accessory_profile"
	return appearance


func _find_tendency_value(entries: Array, tendency_id: String) -> int:
	for entry_value: Variant in entries:
		if entry_value is Dictionary \
			and str((entry_value as Dictionary).get("id", "")) \
			== tendency_id:
			return int((entry_value as Dictionary).get("value", 0))

	return -1


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	UniversalNotifications.clear_history()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("OPERATOR_PROFILE_APP_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("OPERATOR_PROFILE_APP_TEST: FAIL (%d)" % _failures.size())
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
