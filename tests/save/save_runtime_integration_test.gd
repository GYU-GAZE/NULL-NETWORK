extends Node


const BOOTSTRAP_SCENE: PackedScene = preload(
	"res://core/bootstrap/bootstrap.tscn"
)

var _failures := PackedStringArray()
var _test_root: String


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/save_runtime_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var errors := SaveManager.create_campaign(
		"runtime_restore",
		CampaignState.SaveMode.SAFE,
		"Runtime Restore"
	)
	_check(errors.is_empty(), "Could not create runtime campaign: %s" % errors)

	var first_boot := await _boot_campaign("runtime_restore")

	if first_boot.is_empty():
		_finish_test()
		return

	var first_bootstrap: Node = first_boot["bootstrap"]
	var first_main: Node = first_boot["main"]
	var first_window_manager := _get_window_manager(first_main)
	_check(first_window_manager != null, "First boot has no WindowManager.")

	if first_window_manager == null:
		first_bootstrap.queue_free()
		_finish_test()
		return

	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("browser"))
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("navigator"))
	await _wait_frames(4)

	var browser_window: Node = first_window_manager.open_windows.get("browser")
	var navigator_window: Node = first_window_manager.open_windows.get("navigator")
	var browser: Node = _get_window_app(browser_window)
	var navigator := _get_window_app(navigator_window) as NavigatorApp
	_check(browser != null, "Browser did not open.")
	_check(navigator != null, "Navigator did not open.")

	if browser == null or navigator == null:
		first_bootstrap.queue_free()
		_finish_test()
		return

	var thread_id := _get_first_thread_id()
	var thread_url := "null.net/forums/thread/%s" % thread_id
	browser.call("_create_tab", thread_url)
	await _wait_frames(2)
	var browser_before: Dictionary = browser.call("get_app_session_state")
	_check(
		(browser_before.get("tabs", []) as Array).size() == 2,
		"Browser did not preserve exactly two tabs."
	)
	_check(
		_current_browser_url(browser_before) == thread_url,
		"Browser did not enter the selected forum thread."
	)

	var work_rect: Rect2 = first_window_manager.get_work_area_rect()
	var browser_valid_size: Vector2 = browser_window.size
	var max_browser_position := work_rect.end - browser_valid_size
	browser_window.position = Vector2(
		clamp(work_rect.position.x + 40.0, work_rect.position.x, max_browser_position.x),
		clamp(work_rect.position.y + 24.0, work_rect.position.y, max_browser_position.y)
	)
	await _wait_frames(2)
	var browser_position_before: Vector2 = browser_window.position
	var browser_size_before: Vector2 = browser_window.size

	var akihabara := ContentRegistry.get_location("akihabara")
	_check(akihabara != null, "Akihabara is missing from ContentRegistry.")

	if akihabara == null:
		first_bootstrap.queue_free()
		_finish_test()
		return

	navigator.restore_app_session_state({
		"version": NavigatorApp.SESSION_STATE_VERSION,
		"mode": int(NavigatorApp.NavigatorMode.LOCAL_AREA),
		"selected_location_id": akihabara.get_display_id(),
		"current_location_id": akihabara.get_display_id(),
		"current_local_area_id": akihabara.local_area.get_display_id(),
		"current_entry_id": akihabara.local_area.default_entry_id,
		"has_player_position": true,
		"player_position": {"x": 222.0, "y": 144.0},
		"local_area_runtime_state": {}
	})
	var exe_actor := (
		navigator.local_area_view.find_interactable_by_id("akihabara_test_exe")
		as LocalAreaExeActor
	)
	_check(exe_actor != null, "Rattildus EXE was not restored in Akihabara.")

	if exe_actor == null:
		first_bootstrap.queue_free()
		_finish_test()
		return

	navigator.call(
		"_start_exe_encounter",
		exe_actor,
		"runtime_transaction",
		"akihabara_rattildus_fight"
	)
	_check(CombatManager.is_encounter_active(), "Combat did not start.")
	CombatManager.execute_cycle(false)
	await _wait_frames(3)
	_check(CombatManager.current_cycle == 1, "Combat did not complete one cycle.")
	_check(
		CombatManager.is_encounter_active(),
		"The persistence fixture combat ended before a resumable boundary."
	)

	var navigator_before := navigator.export_save_data()
	var combat_before := CombatManager.export_save_data()
	_check(
		SaveManager.save_checkpoint(&"runtime_integration"),
		"Could not write the runtime integration checkpoint."
	)
	await _wait_frames(2)

	first_bootstrap.queue_free()
	await _wait_frames(4)
	var second_boot := await _boot_campaign("runtime_restore")

	if second_boot.is_empty():
		_finish_test()
		return

	var second_bootstrap: Node = second_boot["bootstrap"]
	var second_main: Node = second_boot["main"]
	var second_window_manager := _get_window_manager(second_main)
	await _wait_frames(6)
	_check(second_window_manager != null, "Reloaded desktop has no WindowManager.")

	if second_window_manager != null:
		_check(
			second_window_manager.open_windows.has("browser")
			and second_window_manager.open_windows.has("navigator"),
			"Reload did not reopen Browser and Navigator."
		)
		var restored_browser_window: Node = (
			second_window_manager.open_windows.get("browser")
		)
		var restored_navigator_window: Node = (
			second_window_manager.open_windows.get("navigator")
		)
		var restored_browser: Node = _get_window_app(restored_browser_window)
		var restored_navigator := (
			_get_window_app(restored_navigator_window) as NavigatorApp
		)

		if restored_browser != null:
			var browser_after: Dictionary = restored_browser.call(
				"get_app_session_state"
			)
			_check(
				(browser_after.get("tabs", []) as Array).size() == 2
				and _current_browser_url(browser_after) == thread_url,
				"Browser tabs or active thread were not restored."
			)
		else:
			_check(false, "Reloaded Browser instance is missing.")

		if restored_browser_window != null:
			_check(
				restored_browser_window.position == browser_position_before
				and restored_browser_window.size == browser_size_before,
				"Browser window geometry was not restored."
			)

		if restored_navigator != null:
			var navigator_after := restored_navigator.export_save_data()
			_check(
				int(navigator_after.get("mode", -1))
				== NavigatorApp.NavigatorMode.ENCOUNTER,
				"Navigator did not reopen in ENCOUNTER mode."
			)
			_check(
				_vector_data_equal(
					navigator_before.get("player_position", {}),
					navigator_after.get("player_position", {})
				),
				"Navigator player position was not restored."
			)
		else:
			_check(false, "Reloaded Navigator instance is missing.")

	var combat_after := CombatManager.export_save_data()

	_check(
		CombatManager.is_encounter_active()
		and int(combat_after.get("cycle_index", -1)) == 1,
		"CombatSession did not restore the between-cycle boundary."
	)
	_check(
		combat_after.get("ally_team", []) == combat_before.get("ally_team", [])
		and combat_after.get("enemy_team", []) == combat_before.get("enemy_team", []),
		"Combat actors, HP, Stability, statuses or Modules changed on reload."
	)

	second_bootstrap.queue_free()
	await _wait_frames(3)
	_finish_test()


func _boot_campaign(campaign_id: String) -> Dictionary:
	var bootstrap := BOOTSTRAP_SCENE.instantiate()
	add_child(bootstrap)
	await _wait_frames(2)
	var runtime_root: Node = bootstrap.get_node("RuntimeRoot")
	_check(
		runtime_root.get_child_count() == 0,
		"Bootstrap instantiated the desktop before campaign selection."
	)
	bootstrap.call("_on_campaign_load_requested", campaign_id, "")
	await _wait_frames(5)

	if runtime_root.get_child_count() != 1:
		_check(false, "Bootstrap did not instantiate one desktop after load.")
		bootstrap.queue_free()
		return {}

	return {
		"bootstrap": bootstrap,
		"main": runtime_root.get_child(0)
	}


func _get_window_manager(main: Node) -> WindowManager:
	if main == null:
		return null

	return main.get_node_or_null("WindowManagerLayer/WindowManager") as WindowManager


func _get_window_app(window: Node) -> Node:
	if window == null:
		return null

	var container := window.get("content_container") as Node

	if container == null or container.get_child_count() == 0:
		return null

	return container.get_child(0)


func _get_first_thread_id() -> String:
	for thread_data: ThreadButtonData in ForumThreadDatabase.get_all_thread_data():
		if thread_data != null and thread_data.thread_ref != null:
			var thread_id: String = thread_data.thread_ref.thread_id.strip_edges()

			if not thread_id.is_empty():
				return thread_id

	_check(false, "No forum thread fixture is available.")
	return "missing-thread"


func _current_browser_url(state: Dictionary) -> String:
	var tabs: Variant = state.get("tabs", [])
	var index: int = int(state.get("current_tab_index", -1))

	if tabs is not Array or index < 0 or index >= tabs.size():
		return ""

	var tab: Variant = tabs[index]
	return str(tab.get("current_url", tab.get("url", ""))) if tab is Dictionary else ""


func _vector_data_equal(first: Variant, second: Variant) -> bool:
	if first is not Dictionary or second is not Dictionary:
		return false

	return (
		is_equal_approx(float(first.get("x", 0.0)), float(second.get("x", 0.0)))
		and is_equal_approx(float(first.get("y", 0.0)), float(second.get("y", 0.0)))
	)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()
	AppSessionStore.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("SAVE_RUNTIME_INTEGRATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("SAVE_RUNTIME_INTEGRATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()

	while not entry.is_empty():
		var child_path := "%s/%s" % [path, entry]

		if directory.current_is_dir():
			_remove_directory_recursive(child_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))

		entry = directory.get_next()

	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
