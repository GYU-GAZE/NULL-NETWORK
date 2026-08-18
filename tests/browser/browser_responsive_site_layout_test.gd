extends Node

const BROWSER_SCENE: PackedScene = preload("res://apps/browser/app_browser.tscn")

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var browser := BROWSER_SCENE.instantiate() as BrowserApp
	_check(browser != null, "Browser scene failed to instantiate.")
	if browser == null:
		_finish_test()
		return

	add_child(browser)
	browser.size = Vector2(600, 400)
	await get_tree().create_timer(0.35).timeout
	_check(not browser.is_tab_overflow_active(), "One Browser tab must not show horizontal overflow.")
	_check(browser.get_tab_button_count() == 1, "Browser did not preserve its initial tab button.")
	_check(browser.get_browser_chrome_height() <= 40.0, "Browser chrome exceeded its 40 px logical budget.")
	_check(browser.get_site_viewport_ratio() >= 0.85, "Browser site viewport must retain at least 85% of app height.")

	for index in range(7):
		browser.tabs.append(BrowserTabData.new())
	browser._sync_tab_buttons()
	await _wait_frames(3)
	_check(browser.get_tab_button_count() == browser.tabs.size(), "Persistent tab buttons diverged from BrowserTabData.")
	_check(browser.is_tab_overflow_active(), "Tab overflow did not appear after minimum widths exceeded the strip.")
	var first_tab_button := browser.tab_button_container.get_child(0) as BrowserTabButton
	_check(
		first_tab_button != null and first_tab_button.get_reserved_close_width() <= 14.0,
		"Browser tab reserves excessive close-button width."
	)

	browser.size = Vector2(900, 600)
	await _wait_frames(3)
	_check(not browser.is_tab_overflow_active(), "Resize did not hide tab overflow after tabs fit.")
	browser.size = Vector2(400, 250)
	await _wait_frames(3)
	_check(browser.is_tab_overflow_active(), "Breakpoint resize did not recalculate tab overflow.")

	while browser.tabs.size() > 2:
		await browser._close_tab(browser.tabs.size() - 1)
	await _wait_frames(3)
	_check(not browser.is_tab_overflow_active(), "Closing tabs did not restore the no-overflow state.")

	browser._load_page("kubuchan.net")
	await get_tree().create_timer(0.3).timeout
	_check(
		browser.site_container.get_child_count() == 1 and not browser.page_scroll.visible,
		"Kubuchan must preserve its self-managed PageScroll without a second Browser scrollbar."
	)
	var kubuchan := browser._get_current_site() as Control
	_check(kubuchan != null and kubuchan.custom_minimum_size == Vector2.ZERO, "Self-managed site retained a fixed Browser canvas.")

	var tab := browser._get_current_tab()
	var history_before := tab.history.size()
	browser._load_page("null.net")
	await get_tree().create_timer(0.3).timeout
	_check(tab.history.size() == history_before + 1, "Browser navigation no longer records tab history.")
	_check(browser.page_scroll.visible, "Null Network home did not opt into Browser page-level scrolling.")
	_check(browser.scroll_site_container.get_child_count() == 1, "Page-scroll site did not render in the scrolling host.")

	browser._on_browser_back_pressed()
	await get_tree().create_timer(0.3).timeout
	_check(tab.current_url == "kubuchan.net", "Browser Back did not restore the previous URL.")

	var session := browser.get_app_session_state()
	_check(
		session.get("tabs", []).size() == browser.tabs.size(),
		"Browser session state did not preserve persistent tabs."
	)

	browser.queue_free()
	await _wait_frames(2)
	_finish_test()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("BROWSER_RESPONSIVE_SITE_LAYOUT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("BROWSER_RESPONSIVE_SITE_LAYOUT_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
