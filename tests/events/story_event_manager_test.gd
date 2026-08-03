extends Node


const MAIN_SCENE: PackedScene = preload("res://core/main.tscn")
const EVENT_ID: String = "story.prologue.null_network_welcome"
const DIALOGUE_STEP_ID: String = "start_welcome_dialogue"

var _failures := PackedStringArray()
var _dispatch_counts: Dictionary = {}
var _dialogue_request_count: int = 0
var _test_root: String


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/story_events_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	UniversalNotifications.clear_history()
	_connect_observers()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"story_event_gate",
		CampaignState.SaveMode.SAFE,
		"StoryEvent Gate"
	)
	_check(create_errors.is_empty(), "Campaign creation failed: %s" % create_errors)

	var first_main: Node = MAIN_SCENE.instantiate()
	add_child(first_main)
	await _wait_frames(5)
	GameState.set_flag("story.prologue.account_ready", true)
	await _wait_frames(24)

	_check(
		CampaignState.active_story_event_id == EVENT_ID,
		"The eligible StoryEvent did not become active."
	)
	_check(
		CampaignState.active_story_event_step_id == DIALOGUE_STEP_ID
		and CampaignState.active_story_event_waiting,
		"The StoryEvent did not stop at the external dialogue boundary."
	)
	_check(
		_dialogue_request_count == 1,
		"START_DIALOGUE did not emit exactly one typed intent."
	)
	_check_each_completed_step_dispatched_once()
	_check(
		CampaignState.has_installed_app("navigator"),
		"INSTALL_APP did not install Navigator."
	)
	_check(
		UniversalNotifications.get_history().size() == 2,
		"The event notification and Navigator installation notification were not both emitted."
	)
	_check_browser_open_and_navigated(first_main)

	await _wait_frames(6)
	_check(
		SaveManager.save_checkpoint(&"phase6.waiting_dialogue", true),
		"The waiting StoryEvent state could not be saved."
	)

	var counts_before_reload: Dictionary = _dispatch_counts.duplicate(true)
	var notifications_before_reload: int = UniversalNotifications.get_history().size()
	first_main.queue_free()
	await _wait_frames(5)

	var load_errors: PackedStringArray = SaveManager.load_campaign(
		"story_event_gate"
	)
	_check(load_errors.is_empty(), "Campaign reload failed: %s" % load_errors)
	var second_main: Node = MAIN_SCENE.instantiate()
	add_child(second_main)
	await _wait_frames(12)

	_check(
		CampaignState.active_story_event_id == EVENT_ID
		and CampaignState.active_story_event_step_id == DIALOGUE_STEP_ID
		and CampaignState.active_story_event_waiting,
		"Reload did not restore the exact StoryEvent step boundary."
	)
	_check(
		_dispatch_counts == counts_before_reload,
		"Reload redispatched one or more completed StoryEvent steps."
	)
	_check(
		_dialogue_request_count == 1,
		"Reload duplicated the already-started dialogue intent."
	)
	_check(
		UniversalNotifications.get_history().size() == notifications_before_reload,
		"Reload duplicated a completed notification or app installation effect."
	)

	GlobalSignals.story_event_step_completed.emit(
		EVENT_ID,
		DIALOGUE_STEP_ID,
		true
	)
	await _wait_frames(18)

	_check(
		CampaignState.active_story_event_id.is_empty()
		and CampaignState.has_completed_story_event(EVENT_ID),
		"Acknowledging the dialogue did not complete the StoryEvent."
	)
	_check(
		GameState.get_flag("story.prologue.welcome_sequence_applied")
		and GameState.get_flag("story.prologue.welcome_complete"),
		"Step or completion effects were not applied."
	)
	_check(
		int(CampaignState.get_story_event_repeat_state(EVENT_ID).get(
			"completion_count",
			0
		)) == 1,
		"StoryEvent repeat state did not record one completion."
	)

	var dispatches_after_completion: Dictionary = _dispatch_counts.duplicate(true)
	GameState.set_flag("story.prologue.account_ready", false)
	GameState.set_flag("story.prologue.account_ready", true)
	await _wait_frames(12)
	_check(
		_dispatch_counts == dispatches_after_completion,
		"An ONCE StoryEvent was queued again after completion."
	)

	_check(
		SaveManager.save_checkpoint(&"phase6.completed", true),
		"The completed StoryEvent state could not be saved."
	)
	second_main.queue_free()
	await _wait_frames(4)
	load_errors = SaveManager.load_campaign("story_event_gate")
	_check(load_errors.is_empty(), "Final campaign reload failed: %s" % load_errors)
	_check(
		CampaignState.has_completed_story_event(EVENT_ID)
		and int(CampaignState.get_story_event_repeat_state(EVENT_ID).get(
			"completion_count",
			0
		)) == 1,
		"Completion and repeat state did not survive the final round-trip."
	)

	_finish_test()


func _connect_observers() -> void:
	if not StoryEventManager.step_dispatched.is_connected(_on_step_dispatched):
		StoryEventManager.step_dispatched.connect(_on_step_dispatched)

	if not GlobalSignals.request_story_dialogue.is_connected(
		_on_dialogue_requested
	):
		GlobalSignals.request_story_dialogue.connect(_on_dialogue_requested)


func _on_step_dispatched(
	event_id: String,
	step_id: String,
	_step_type: StoryEventStepData.StepType,
	_payload: Dictionary
) -> void:
	if event_id != EVENT_ID:
		return

	_dispatch_counts[step_id] = int(_dispatch_counts.get(step_id, 0)) + 1


func _on_dialogue_requested(
	dialogue_id: String,
	event_id: String,
	step_id: String
) -> void:
	if event_id != EVENT_ID or step_id != DIALOGUE_STEP_ID:
		return

	_check(
		dialogue_id == "dialogue.prologue.null_network_welcome",
		"START_DIALOGUE emitted the wrong stable dialogue ID."
	)
	_dialogue_request_count += 1


func _check_each_completed_step_dispatched_once() -> void:
	for step_id: String in [
		"open_browser",
		"navigate_null_network",
		"show_welcome_alert",
		"show_welcome_notification",
		"install_navigator",
		DIALOGUE_STEP_ID
	]:
		_check(
			int(_dispatch_counts.get(step_id, 0)) == 1,
			"Step '%s' was not dispatched exactly once." % step_id
		)


func _check_browser_open_and_navigated(main: Node) -> void:
	var window_manager := main.get_node_or_null(
		"WindowManagerLayer/WindowManager"
	) as WindowManager
	_check(window_manager != null, "Main has no WindowManager.")

	if window_manager == null:
		return

	var browser_window: Node = window_manager.open_windows.get("browser")
	_check(browser_window != null, "OPEN_APP did not open Browser.")

	if browser_window == null:
		return

	var content_container: Node = browser_window.get("content_container") as Node

	if content_container == null or content_container.get_child_count() == 0:
		_check(false, "Browser window contains no BrowserApp instance.")
		return

	var browser: Node = content_container.get_child(0)
	var state: Dictionary = browser.call("get_app_session_state")
	var tabs: Variant = state.get("tabs", [])
	var current_index: int = int(state.get("current_tab_index", -1))
	var current_url: String = ""

	if tabs is Array and current_index >= 0 and current_index < tabs.size():
		var current_tab: Variant = tabs[current_index]

		if current_tab is Dictionary:
			current_url = str(current_tab.get("current_url", ""))

	_check(
		current_url == "null.net",
		"NAVIGATE_BROWSER did not navigate the active Browser tab to null.net."
	)


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	UniversalNotifications.clear_history()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("STORY_EVENT_MANAGER_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("STORY_EVENT_MANAGER_TEST: FAIL (%d)" % _failures.size())
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
