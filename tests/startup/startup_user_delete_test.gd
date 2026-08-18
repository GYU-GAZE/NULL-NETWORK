extends Node


const STARTUP_MENU_SCENE: PackedScene = preload(
	"res://systems/startup/startup_menu.tscn"
)

var _failures := PackedStringArray()
var _test_root: String = ""
var _delete_request_count: int = 0
var _last_delete_campaign_id: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/startup_delete_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"delete_fixture",
		CampaignState.SaveMode.SAFE,
		"Delete Me"
	)
	_check(create_errors.is_empty(), "Could not create delete fixture campaign.")
	_check(SaveManager.campaign_exists("delete_fixture"), "Delete fixture save is missing.")

	var menu := STARTUP_MENU_SCENE.instantiate() as StartupMenu
	_check(menu != null, "Startup menu scene failed to instantiate.")

	if menu != null:
		add_child(menu)
		await get_tree().process_frame
		menu.refresh_profiles()
		menu._input_enabled = true
		menu.campaign_delete_requested.connect(_on_campaign_delete_requested)

		var profile_list := menu.find_child("ProfileList", true, false) as VBoxContainer
		_check(
			profile_list != null and profile_list.get_child_count() == 2,
			"Delete fixture should render one saved user plus New User."
		)

		if profile_list != null and profile_list.get_child_count() == 2:
			var entry := profile_list.get_child(0) as StartupUserEntry
			var new_entry := profile_list.get_child(1) as StartupUserEntry
			_check(entry != null, "Saved user is not a StartupUserEntry.")
			_check(new_entry != null, "New User is not a StartupUserEntry.")

			if entry != null:
				_check(not entry.delete_button.visible, "Delete action must start hidden.")
				entry._on_click_target_pressed()
				_check(entry.is_selected(), "First click did not select saved user.")
				_check(
					entry.delete_button.visible,
					"Selected saved user did not reveal its delete action."
				)
				entry._on_delete_button_pressed()
				_check(
					entry.delete_button.text == "CONFIRM",
					"First delete press did not arm destructive confirmation."
				)
				_check(
					_delete_request_count == 0,
					"Campaign delete was requested before confirmation."
				)
				entry._on_delete_button_pressed()
				_check(
					_delete_request_count == 1
					and _last_delete_campaign_id == "delete_fixture",
					"Confirmed delete did not bubble through StartupMenu."
				)

			if new_entry != null:
				new_entry._on_click_target_pressed()
				_check(new_entry.is_selected(), "New User did not become selected.")
				_check(
					not new_entry.can_delete() and not new_entry.delete_button.visible,
					"New User must never expose campaign deletion."
				)

		menu.queue_free()

	await get_tree().process_frame

	var delete_errors: PackedStringArray = SaveManager.delete_campaign("delete_fixture")
	_check(delete_errors.is_empty(), "SaveManager deletion failed: %s" % delete_errors)
	_check(
		not SaveManager.campaign_exists("delete_fixture"),
		"Deleted campaign still exists on disk."
	)
	_check(
		not CampaignState.has_campaign(),
		"Deleting the active login campaign did not clear campaign runtime state."
	)
	_check(
		SaveManager.get_active_metadata().is_empty(),
		"Deleting the active campaign left stale SaveManager metadata."
	)

	_finish_test()


func _on_campaign_delete_requested(campaign_id: String) -> void:
	_delete_request_count += 1
	_last_delete_campaign_id = campaign_id


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("STARTUP_USER_DELETE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("STARTUP_USER_DELETE_TEST: FAIL (%d)" % _failures.size())
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
