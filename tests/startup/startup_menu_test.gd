extends Node


const STARTUP_MENU_SCENE: PackedScene = preload(
	"res://systems/startup/startup_menu.tscn"
)

var _failures := PackedStringArray()
var _test_root: String = ""
var _load_request_count: int = 0
var _last_load_campaign_id: String = ""


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
		_check(
			profiles[0].has("avatar_id"),
			"Startup preview no longer exposes the saved Operator avatar ID."
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
			profile_list != null and profile_list.get_child_count() == 2,
			"Startup menu must render saved users plus the New User pseudo-profile."
		)

		var user_panel := menu.get_node_or_null(
			"MenuArea/RightColumn/UserPanel"
		) as PanelContainer
		_check(
			user_panel != null
			and user_panel.get_theme_stylebox("panel") is StyleBoxEmpty,
			"Startup user list regained a permanent panel background."
		)

		if profile_list != null and profile_list.get_child_count() == 2:
			var entry := profile_list.get_child(0) as StartupUserEntry
			var new_entry := profile_list.get_child(1) as StartupUserEntry
			_check(entry != null, "Startup account row is not a StartupUserEntry.")
			_check(new_entry != null, "New User row is not a StartupUserEntry.")

			if entry != null:
				var username_label := entry.get_node_or_null(
					"SelectionPanel/Margin/Content/Text/UsernameLabel"
				) as Label
				var description_label := entry.get_node_or_null(
					"SelectionPanel/Margin/Content/Text/DescriptionLabel"
				) as Label
				var avatar_frame := entry.get_node_or_null(
					"SelectionPanel/Margin/Content/AvatarFrame"
				) as PanelContainer
				_check(
					username_label != null and username_label.text == "Preview User",
					"Startup account row did not render the user identity."
				)
				_check(
					description_label != null
					and description_label.text == "SAFE MODE · Day 1",
					"Startup account row did not render mode/day description."
				)
				_check(
					avatar_frame != null,
					"Startup account row lost its avatar slot."
				)

				menu.campaign_load_requested.connect(_on_campaign_load_requested)
				menu._input_enabled = true
				entry._on_click_target_pressed()
				_check(
					entry.is_selected(),
					"First account press did not highlight the account row."
				)
				_check(
					_load_request_count == 0,
					"First account press loaded the campaign prematurely."
				)
				entry._on_click_target_pressed()
				_check(
					_load_request_count == 1
					and _last_load_campaign_id == entry.campaign_id,
					"Second single account press did not request campaign load."
				)

			if new_entry != null:
				var new_username := new_entry.get_node_or_null(
					"SelectionPanel/Margin/Content/Text/UsernameLabel"
				) as Label
				var new_description := new_entry.get_node_or_null(
					"SelectionPanel/Margin/Content/Text/DescriptionLabel"
				) as Label
				_check(
					new_username != null and new_username.text == "New User",
					"New User pseudo-profile lost its account-style label."
				)
				_check(
					new_description != null
					and new_description.text == "Create a new KubuOS user",
					"New User pseudo-profile lost its account-style description."
				)
				new_entry._on_click_target_pressed()
				_check(
					new_entry.is_selected(),
					"New User first press did not highlight its row."
				)
				_check(
					not menu.get_node("MenuArea/RightColumn/ModePanel").visible,
					"New User first press opened mode selection prematurely."
				)
				new_entry._on_click_target_pressed()
				_check(
					_load_request_count == 1,
					"New User second press incorrectly requested campaign load."
				)
				_check(
					menu.get_node("MenuArea/RightColumn/ModePanel").visible,
					"New User second single press did not open save-mode selection."
				)

		_check(
			menu.get_node_or_null("MenuArea/Divider") != null,
			"Startup menu lost the XP-style center divider."
		)
		_check(
			menu.get_node_or_null("TopBand") == null,
			"Startup menu unexpectedly restored the removed top band."
		)
		var bottom_bar := menu.get_node_or_null("BottomBarRoot") as Control
		_check(
			bottom_bar != null
			and is_equal_approx(bottom_bar.offset_top, 0.0)
			and is_equal_approx(bottom_bar.offset_bottom, StartupMenu.BOTTOM_BAR_HEIGHT),
			"Startup bottom bar is not staged below its bottom anchor before reveal."
		)
		menu._set_bottom_bar_resting()
		_check(
			is_equal_approx(bottom_bar.offset_top, -StartupMenu.BOTTOM_BAR_HEIGHT)
			and is_equal_approx(bottom_bar.offset_bottom, 0.0),
			"Startup bottom bar resting offsets no longer pin it to the viewport bottom."
		)
		menu.queue_free()

	await get_tree().process_frame
	_finish_test()


func _on_campaign_load_requested(
	campaign_id: String,
	_checkpoint_file_id: String
) -> void:
	_load_request_count += 1
	_last_load_campaign_id = campaign_id


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
