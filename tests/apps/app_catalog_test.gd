extends Node


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")
const INSTALL_NAVIGATOR: UnlockAppEffectData = preload(
	"res://tests/apps/fixtures/install_navigator.tres"
)

var _failures := PackedStringArray()
var _test_root: String


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/apps_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	UniversalNotifications.clear_history()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"app_catalog_gate",
		CampaignState.SaveMode.SAFE,
		"App Catalog Gate"
	)
	_check(create_errors.is_empty(), "Campaign creation failed: %s" % create_errors)
	_check(
		CampaignState.has_installed_app("browser"),
		"Browser was not installed from installed_by_default."
	)
	_check(
		CampaignState.has_installed_app("social"),
		"Social was not installed from installed_by_default."
	)
	_check(
		not CampaignState.has_installed_app("navigator"),
		"Navigator was installed before its unlock effect."
	)

	var first_main: Node = MAIN_SCENE.instantiate()
	add_child(first_main)
	await _wait_frames(4)

	var first_dock := _get_dock(first_main)
	var first_workspace := _get_workspace_manager(first_main)
	var first_windows := _get_window_manager(first_main)
	_check(first_dock != null, "Main scene has no KubuBottomDock.")
	_check(first_workspace != null, "Main scene has no WorkspaceManager.")
	_check(first_windows != null, "Main scene has no WindowManager.")

	if first_dock == null or first_workspace == null or first_windows == null:
		first_main.queue_free()
		_finish_test()
		return

	_check(
		first_dock.get_visible_app_ids()
		== PackedStringArray(["browser", "social"]),
		"Dock did not project the installed default Browser and Social apps."
	)

	var context := GameEffectContext.create("test.phase5.starter_selected")
	_check(
		INSTALL_NAVIGATOR.apply(context),
		"Navigator installation effect was rejected."
	)
	await _wait_frames(3)

	_check(
		first_dock.get_visible_app_ids()
		== PackedStringArray(["browser", "navigator", "social"]),
		"Dock did not add Navigator live in catalog order."
	)
	_check(
		GameState.get_flag("kubu_os.app.navigator_installed"),
		"Navigator installation effects were not applied."
	)
	_check(
		UniversalNotifications.get_history().size() == 1,
		"Navigator installation did not publish exactly one notification."
	)

	var navigator: AppResource = ContentRegistry.get_app("navigator")
	GlobalSignals.request_activate_workspace.emit(navigator)
	await _wait_frames(3)
	var first_navigator_instance: Control = (
		first_workspace.get_active_workspace_instance()
	)
	GlobalSignals.request_activate_workspace.emit(navigator)
	await _wait_frames(2)
	_check(
		first_navigator_instance != null
		and first_workspace.get_active_workspace_instance()
		== first_navigator_instance,
		"Repeated Navigator activation created a second workspace instance."
	)

	var browser: AppResource = ContentRegistry.get_app("browser")
	GlobalSignals.request_open_app.emit(browser)
	GlobalSignals.request_open_app.emit(browser)
	await _wait_frames(3)
	_check(
		first_windows.open_windows.size() == 1
		and first_windows.open_windows.has("browser"),
		"Repeated Browser activation created more than one window instance."
	)

	var social: AppResource = ContentRegistry.get_app("social")
	GlobalSignals.request_open_app.emit(social)
	GlobalSignals.request_open_app.emit(social)
	await _wait_frames(3)
	_check(
		first_windows.open_windows.size() == 2
		and first_windows.open_windows.has("social"),
		"Repeated Social activation created more than one window instance."
	)

	_check(
		SaveManager.save_checkpoint(&"phase5.app_installed", true),
		"Could not save the installed app state."
	)
	first_main.queue_free()
	await _wait_frames(4)

	var load_errors: PackedStringArray = SaveManager.load_campaign(
		"app_catalog_gate"
	)
	_check(load_errors.is_empty(), "Campaign reload failed: %s" % load_errors)

	var second_main: Node = MAIN_SCENE.instantiate()
	add_child(second_main)
	await _wait_frames(5)
	var second_dock := _get_dock(second_main)
	_check(second_dock != null, "Reloaded main scene has no KubuBottomDock.")

	if second_dock != null:
		_check(
			second_dock.get_visible_app_ids()
			== PackedStringArray(["browser", "navigator", "social"]),
			"Save/load did not preserve installed apps in Dock order."
		)

	second_main.queue_free()
	await _wait_frames(2)
	_finish_test()


func _get_dock(main: Node) -> KubuBottomDock:
	return main.get_node_or_null(
		"OSChromeLayer/KubuBottomDock"
	) as KubuBottomDock


func _get_workspace_manager(main: Node) -> WorkspaceManager:
	return main.get_node_or_null(
		"WorkspaceLayer/WorkspaceManager"
	) as WorkspaceManager


func _get_window_manager(main: Node) -> WindowManager:
	return main.get_node_or_null(
		"WindowManagerLayer/WindowManager"
	) as WindowManager


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	UniversalNotifications.clear_history()

	if _failures.is_empty():
		print("APP_CATALOG_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("APP_CATALOG_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
