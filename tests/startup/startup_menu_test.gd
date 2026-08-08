extends Node


const STARTUP_MENU_SCENE: PackedScene = preload(
	"res://systems/startup/startup_menu.tscn"
)

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/startup_menu_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"startup_menu_fixture",
		CampaignState.SaveMode.SAFE,
		"Preview User"
	)
	_check(create_errors.is_empty(), "Could not create startup preview fixture.")
	TimeManager.current_period = TimeManager.TimePeriod.NIGHT
	_check(
		SaveManager.save_checkpoint(&"startup_menu_preview", false),
		"Could not save NIGHT startup preview fixture."
	)

	var profiles: Array[Dictionary] = CampaignPreviewRepository.list_profiles(
		_test_root
	)
	_check(profiles.size() == 1, "Startup preview repository did not find fixture.")

	if not profiles.is_empty():
		_check(
			int(profiles[0].get("current_period", -1))
			== TimeManager.TimePeriod.NIGHT,
			"Startup preview did not preserve NIGHT period."
		)
		_check(
			str(profiles[0].get("display_name", "")) == "Preview User",
			"Startup preview did not preserve campaign display name."
		)

	var menu := STARTUP_MENU_SCENE.instantiate() as StartupMenu
	_check(menu != null, "Startup menu scene failed to instantiate.")

	if menu != null:
		add_child(menu)
		await get_tree().process_frame
		var period: int = menu.refresh_profiles()
		_check(
			period == TimeManager.TimePeriod.NIGHT,
			"Startup menu did not choose latest save period for backdrop."
		)
		var profile_list := menu.get_node_or_null(
			"MenuArea/RightColumn/UserPanel/Margin/Root/Scroll/ProfileList"
		) as VBoxContainer
		_check(
			profile_list != null and profile_list.get_child_count() == 1,
			"Startup menu did not render the saved user row."
		)
		menu.queue_free()

	await get_tree().process_frame
	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("STARTUP_MENU_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("STARTUP_MENU_TEST: FAIL (%d)" % _failures.size())
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
