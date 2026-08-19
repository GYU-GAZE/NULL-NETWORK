extends Control

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
	browser.set_anchors_preset(Control.PRESET_TOP_LEFT)
	browser.size = Vector2(600, 400)
	add_child(browser)
	await _wait_frames(4)

	browser._load_page("null.net")
	await get_tree().create_timer(0.40).timeout
	_check(browser.page_scroll.visible, "NULL NETWORK home did not use Browser page scrolling.")
	_check(browser.scroll_site_container is BrowserPageScrollHost, "Browser page-scroll host is not using the post-layout stabilizer.")
	_check(browser.page_scroll.scroll_vertical == 0, "NULL NETWORK home did not settle at scroll origin on entry.")
	_check_site_top_matches_viewport(browser, "initial NULL NETWORK entry")

	var scrollbar := browser.page_scroll.get_v_scroll_bar()
	if scrollbar != null and scrollbar.max_value > browser.page_scroll.size.y + 1.0:
		browser.page_scroll.scroll_vertical = 40
		await _wait_frames(2)
		_check(browser.page_scroll.scroll_vertical > 0, "Regression setup could not move the page away from origin.")

	# Leave the PAGE_SCROLL host, then return through Browser history. The old
	# ScrollContainer transform used to survive this route change until a resize
	# or maximize forced another layout pass.
	browser._load_page("null.net/getstarted")
	await get_tree().create_timer(0.35).timeout
	browser._on_browser_back_pressed()
	await get_tree().create_timer(0.45).timeout
	_check(browser._get_current_tab().current_url == "null.net", "Browser Back did not return to NULL NETWORK home.")
	_check(browser.page_scroll.scroll_vertical == 0, "Returned NULL NETWORK home kept a stale page-scroll offset.")
	_check_site_top_matches_viewport(browser, "returned NULL NETWORK entry")

	browser.queue_free()
	await _wait_frames(2)
	_finish_test()


func _check_site_top_matches_viewport(browser: BrowserApp, phase: String) -> void:
	var site := browser._get_current_site() as Control
	_check(site != null, "%s has no rendered site Control." % phase)
	if site == null:
		return
	var site_top := site.get_global_rect().position.y
	var viewport_top := browser.page_scroll.get_global_rect().position.y
	_check(
		is_equal_approx(site_top, viewport_top),
		"%s rendered the page at y=%s instead of Browser viewport y=%s." % [
			phase,
			site_top,
			viewport_top,
		]
	)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("BROWSER_PAGE_SCROLL_ORIGIN_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("BROWSER_PAGE_SCROLL_ORIGIN_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
