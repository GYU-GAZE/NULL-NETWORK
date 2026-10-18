extends NavigatorTestHarness

var focus_requests: int = 0
var flashes: int = 0


func run() -> void:
	var manager := (load("res://systems/window_manager/window_manager.tscn") as PackedScene).instantiate() as WindowManager
	manager.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	manager.size = Vector2(850, 520)
	add_child(manager)
	var app := ContentRegistry.get_app("browser")
	manager._on_request_open_app(app)
	var window := manager.open_windows["browser"] as WindowBase
	await window.wait_until_opened()
	var browser := window.content_container.get_child(0) as BrowserApp
	browser.url_line_edit.text = "null.net/forums"
	browser.go_button.pressed.emit()
	await settle()
	var forum := browser._get_current_site() as ForumApp
	check(forum != null, "Real Forum scene did not load in Browser")
	if forum == null:
		finish("BROWSER_FORUM_FOCUS_TEST")
		return
	var row := _find_row(forum, "welcomenewplayers")
	check(row != null, "Production welcome thread has no clickable row")
	if row != null:
		row.thread_title_button.pressed.emit()
		await settle()
		_check_reader(browser, "welcomenewplayers")
		await capture("forum_welcome_reader")
		browser.browser_back_btn.pressed.emit()
		await settle()
		check((browser._get_current_site() as ForumApp).current_mode == ForumApp.MODE_THREAD_LIST, "Back did not restore Forum list")
		browser.browser_forward_btn.pressed.emit()
		await settle()
		_check_reader(browser, "welcomenewplayers")
		browser.browser_back_btn.pressed.emit()
		await settle()
		row = _find_row(browser._get_current_site() as ForumApp, "welcomenewplayers")
		row.type_icon_button.pressed.emit()
		await settle()
		_check_reader(browser, "welcomenewplayers")
	for id: String in ["aquarium_signal_rumour"]:
		browser.url_line_edit.text = "HTTPS://WWW.NULL.NET/forums/thread/" + id + "/"
		browser.go_button.pressed.emit()
		await settle()
		_check_reader(browser, id)
	forum = browser._get_current_site() as ForumApp
	for url: String in ["null.net/forums/threadspam/welcomenewplayers", "null.net/forums/threads/welcomenewplayers", "null.net/forums/thread", "null.net/forums/thread/welcomenewplayers/extra"]:
		check(forum._extract_thread_id_from_url(url).is_empty(), "Forum accepted a lookalike/nested thread route: %s" % url)
	browser.url_line_edit.text = "null.net/forums/thread/no_such_thread"
	browser.go_button.pressed.emit()
	await settle()
	check((browser._get_current_site() as ForumApp).current_mode == ForumApp.MODE_THREAD_LIST, "Unknown thread did not fall back safely")
	forum = browser._get_current_site() as ForumApp
	GameState.watch_thread("welcomenewplayers")
	GameState.mark_thread_as_unread("welcomenewplayers")
	forum.site_header.alerts_btn.pressed.emit()
	await settle(0.1)
	check(forum.current_mode == ForumApp.MODE_ALERTS, "Alerts navigation did not open")
	var alert: Node
	for child: Node in forum.alerts_page.get_children():
		if child.has_signal("alert_selected"):
			alert = child
			break
	check(alert != null, "Watched unread thread has no alert card")
	if alert != null:
		var button := alert.find_child("*", true, false) as Button
		var buttons := alert.find_children("*", "BaseButton", true, false)
		if not buttons.is_empty():
			(buttons[0] as BaseButton).pressed.emit()
			await settle()
			_check_reader(browser, "welcomenewplayers")
	window.window_focused.connect(func() -> void: focus_requests += 1)
	window._motion_player.operation_finished.connect(func(control: Control, operation: StringName) -> void:
		if control == window.background and operation == &"flash":
			flashes += 1
	)
	for route: String in ["null.net/forums", "null.net/getstarted"]:
		browser.url_line_edit.text = route
		browser.go_button.pressed.emit()
		await settle()
		await _ordinary_input(window)
	check(focus_requests == 0 and flashes == 0, "Clicks/scroll in active Browser or Forum requested focus/pulse")
	var calendar := ContentRegistry.get_app("calendar")
	check(calendar != null, "Calendar is unavailable for second scrolling application test")
	if calendar != null:
		manager._on_request_open_app(calendar)
		var other := manager.open_windows[calendar.app_id] as WindowBase
		await other.wait_until_opened()
		await settle()
		var count := [0]
		other.window_focused.connect(func() -> void: count[0] += 1)
		await _ordinary_input(other)
		check(count[0] == 0, "Scroll/click in active Calendar requested redundant focus")
		var click := InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		window._gui_input(click)
		window._gui_input(click)
		check(manager.focused_app_id == "browser" and focus_requests == 1, "Inactive window did not activate exactly once")
		await settle()
		check(flashes == 1, "Real window activation lost its feedback")
		var next := InputEventAction.new()
		next.action = "ui_focus_next"
		next.pressed = true
		manager._input(next)
		check(manager.focused_app_id != "browser", "Keyboard window cycling stopped working")
		GlobalSignals.request_open_app.emit(app)
		check(manager.focused_app_id == "browser", "Dock/open-app intent failed to activate Browser")
	await capture("browser_focus_after_interactions")
	manager.reset_save_data()
	manager.queue_free()
	await get_tree().process_frame
	finish("BROWSER_FORUM_FOCUS_TEST")


func _find_row(forum: ForumApp, id: String) -> ForumThreadRowUI:
	for node: Node in forum.thread_list_container.get_children():
		if node is ForumThreadRowUI and node.thread_data.thread_ref.thread_id == id:
			return node
	return null


func _check_reader(browser: BrowserApp, id: String) -> void:
	var forum := browser._get_current_site() as ForumApp
	check(browser._active_url == "null.net/forums/thread/" + id, "Thread URL is wrong")
	check(forum != null and forum.current_mode == ForumApp.MODE_THREAD and forum.current_thread_id == id, "Click did not enter the requested thread reader")
	if forum != null:
		check(forum.reader_container.visible and not forum.thread_list_page.visible, "Reader/list visibility is inconsistent")
		var posts := 0
		for child: Node in forum.post_list.get_children():
			if child is ForumPostUI:
				posts += 1
		check(posts > 0, "Real thread posts were not rendered")


func _ordinary_input(window: WindowBase) -> void:
	var point := window.content_container.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await get_tree().process_frame
	for button: int in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_LEFT]:
		var event := InputEventMouseButton.new()
		event.pressed = true
		event.button_index = button
		event.position = point
		event.global_position = point
		Input.parse_input_event(event)
		window._gui_input(event)
		window._input(event)
		var release := event.duplicate() as InputEventMouseButton
		release.pressed = false
		Input.parse_input_event(release)
		for frame: int in range(12):
			await get_tree().process_frame
			check(window.background.modulate == Color.WHITE, "Window background flashed during ordinary mouse input")
