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
		_check(
			profiles[0].has("occupation_id"),
			"Startup preview no longer exposes the saved Operator occupation ID."
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

		var account_surface := menu.get_node_or_null(
			"MenuArea/RightColumn/AccountSurface"
		) as PanelContainer
		_check(
			account_surface != null,
			"Startup account list and New User flow no longer share one visual surface."
		)

		var user_panel := menu.get_node_or_null(
			"MenuArea/RightColumn/UserPanel"
		) as PanelContainer
		_check(
			user_panel != null
			and user_panel.get_theme_stylebox("panel") is StyleBoxEmpty,
			"Startup user content regained a second permanent panel background."
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
				var delete_button := entry.get_node_or_null(
					"SelectionPanel/DeleteButton"
				) as Button
				_check(
					username_label != null and username_label.text == "Preview User",
					"Startup account row did not render the user identity."
				)
				_check(
					description_label != null
					and description_label.text == "SAFE MODE · Day 1",
					"Startup account row did not preserve fallback mode/day description."
				)
				_check(
					avatar_frame != null,
					"Startup account row lost its avatar slot."
				)
				_check(entry.can_delete(), "Saved account unexpectedly disabled deletion.")

				menu.campaign_load_requested.connect(_on_campaign_load_requested)
				menu._input_enabled = true
				entry._on_click_target_pressed()
				_check(
					entry.is_selected(),
					"First account press did not highlight the account row."
				)
				_check(
					delete_button != null and delete_button.visible,
					"Selected account did not expose its delete action."
				)

				if delete_button != null:
					var delete_style := delete_button.get_theme_stylebox("normal") as StyleBoxFlat
					_check(
						delete_style != null
						and delete_style.border_width_left > 0
						and delete_style.bg_color.r > delete_style.bg_color.b,
						"Delete action is no longer a bordered red system button."
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
				_check(not new_entry.can_delete(), "New User pseudo-profile became deletable.")
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

				while menu._surface_transitioning:
					await get_tree().process_frame

				_check(
					_load_request_count == 1,
					"New User second press incorrectly requested campaign load."
				)
				_check(
					menu.get_node("MenuArea/RightColumn/ModePanel").visible,
					"New User second single press did not open save-mode selection."
				)
				_check(
					account_surface != null and account_surface.visible,
					"Shared account background disappeared during New User flow."
				)
				var new_user_title := menu.get_node_or_null(
					"MenuArea/RightColumn/ModePanel/Margin/ModeContentRoot/Header/NewUserTitle"
				) as Label
				_check(
					new_user_title != null
					and new_user_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
					"New User identity is not centered in the shared account surface."
				)

				var safe_option := menu.get_node_or_null(
					"MenuArea/RightColumn/ModePanel/Margin/ModeContentRoot/ModeOptions/SafeModeOption"
				) as StartupModeOption
				var commit_option := menu.get_node_or_null(
					"MenuArea/RightColumn/ModePanel/Margin/ModeContentRoot/ModeOptions/CommitModeOption"
				) as StartupModeOption
				_check(safe_option != null, "SAFE mode expandable option is missing.")
				_check(commit_option != null, "COMMIT mode expandable option is missing.")
				_check(
					menu.get_node_or_null(
						"MenuArea/RightColumn/ModePanel/Margin/ModeContentRoot/ModeDetailsClip"
					) == null,
					"Legacy detached mode details box still exists."
				)

				if safe_option != null:
					safe_option._on_header_pressed()

					while menu._surface_transitioning:
						await get_tree().process_frame

					_check(
						safe_option.is_expanded(),
						"SAFE mode button did not expand into its own details menu."
					)
					_check(
						safe_option.custom_minimum_size.y >= safe_option.expanded_height - 1.0,
						"SAFE mode button did not reach its expanded height."
					)
					var safe_start := safe_option.get_node_or_null(
						"ContentRoot/Body/Margin/VBox/StartButton"
					) as Button
					_check(
						safe_start != null and not safe_start.disabled,
						"Expanded SAFE mode does not contain an enabled START action."
					)
					_check(
						commit_option == null or not commit_option.is_expanded(),
						"Expanding SAFE mode also expanded COMMIT mode."
					)

					safe_option._on_header_pressed()

					while menu._surface_transitioning:
						await get_tree().process_frame

					_check(
						not safe_option.is_expanded()
						and is_equal_approx(
							safe_option.custom_minimum_size.y,
							safe_option.collapsed_height
						),
						"Pressing an expanded SAFE mode did not collapse it back into a button."
					)

		_check(
			menu.get_node_or_null("MenuArea/Divider") != null,
			"Startup menu lost the XP-style center divider."
		)
		_check(
			menu.get_node_or_null("TopBand") == null,
			"Startup menu unexpectedly restored the removed top band."
		)
		_check(
			menu.get_node_or_null("NullBrand") == null,
			"Startup menu duplicated NULL NETWORK branding instead of leaving it in StartupPresentation."
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
