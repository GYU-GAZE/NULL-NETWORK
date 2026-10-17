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
	_check(browser.scroll_site_container is BrowserPageScrollHost, "Browser page-scroll host is not using the PAGE_SCROLL origin host.")
	_check(browser.page_scroll.scroll_vertical == 0, "NULL NETWORK home did not settle at scroll origin on entry.")
	_check_site_top_matches_viewport(browser, "initial NULL NETWORK entry")
	await _check_scroll_reaches_true_bounds(browser, "initial NULL NETWORK entry")

	var scrollbar := browser.page_scroll.get_v_scroll_bar()
	if scrollbar != null and scrollbar.max_value > browser.page_scroll.size.y + 1.0:
		browser.page_scroll.scroll_vertical = 40
		await _wait_frames(2)
		_check(browser.page_scroll.scroll_vertical > 0, "Regression setup could not move the page away from origin.")

	# PAGE_SCROLL transitions temporarily keep outgoing and incoming roots alive.
	# They must overlay at y=0; a VBox stack here is the source of the page that
	# used to remain half outside the Browser until resize/maximize.
	browser._load_page("null.net/getstarted")
	await get_tree().process_frame
	_check_page_scroll_children_share_origin(browser, "PAGE_SCROLL transition")
	await get_tree().create_timer(0.35).timeout
	_check_site_top_matches_viewport(browser, "Get Started entry")

	browser._on_browser_back_pressed()
	await get_tree().process_frame
	_check_page_scroll_children_share_origin(browser, "Browser Back transition")
	await get_tree().create_timer(0.45).timeout
	_check(browser._get_current_tab().current_url == "null.net", "Browser Back did not return to NULL NETWORK home.")
	_check(browser.page_scroll.scroll_vertical == 40, "Browser Back did not restore its history-entry scroll offset.")
	_check_site_top_matches_viewport(browser, "returned NULL NETWORK entry", 40)
	await _check_scroll_reaches_true_bounds(browser, "returned NULL NETWORK entry")

	browser.queue_free()
	await _wait_frames(2)
	_finish_test()


func _check_scroll_reaches_true_bounds(browser: BrowserApp, phase: String) -> void:
	var site := browser._get_current_site() as Control
	_check(site != null, "%s has no rendered site Control." % phase)
	if site == null:
		return

	var vertical_bar := browser.page_scroll.get_v_scroll_bar()
	_check(vertical_bar != null, "%s has no vertical scrollbar." % phase)
	if vertical_bar == null:
		return

	var maximum_scroll := maxf(0.0, vertical_bar.max_value - vertical_bar.page)
	_check(maximum_scroll > 0.0, "%s did not expose a scrollable document height." % phase)
	if maximum_scroll <= 0.0:
		return

	browser.page_scroll.scroll_vertical = int(ceil(maximum_scroll))
	await _wait_frames(2)

	var viewport_rect := browser.page_scroll.get_global_rect()
	var site_rect := site.get_global_rect()
	_check(
		absf(site_rect.end.y - viewport_rect.end.y) <= 1.5,
		"%s cannot reach the real document bottom: site bottom %.1f, viewport bottom %.1f." % [
			phase,
			site_rect.end.y,
			viewport_rect.end.y,
		]
	)

	var footer := site.find_child("PortalFooter", true, false) as Control
	_check(footer != null, "%s lost the NULL NETWORK footer." % phase)
	if footer != null:
		_check(
			footer.get_global_rect().end.y <= viewport_rect.end.y + 0.5,
			"%s clips the footer even at maximum scroll." % phase
		)

	browser.page_scroll.scroll_vertical = 0
	await _wait_frames(2)
	_check_site_top_matches_viewport(browser, "%s after returning to top" % phase)


func _check_page_scroll_children_share_origin(browser: BrowserApp, phase: String) -> void:
	for child: Node in browser.scroll_site_container.get_children():
		if child is Control:
			_check(
				is_zero_approx((child as Control).position.y),
				"%s stacked page '%s' at local y=%s instead of overlaying it at zero." % [
					phase,
					child.name,
					(child as Control).position.y,
				]
			)


func _check_site_top_matches_viewport(browser: BrowserApp, phase: String, expected_scroll: int = 0) -> void:
	var site := browser._get_current_site() as Control
	_check(site != null, "%s has no rendered site Control." % phase)
	if site == null:
		return
	var site_top := site.get_global_rect().position.y
	var viewport_top := browser.page_scroll.get_global_rect().position.y
	# ScrollContainer theme borders may inset its content viewport by one pixel.
	# What matters is that the document returns to that authored top boundary
	# instead of retaining a stale scroll offset.
	_check(
		absf(site_top - (viewport_top - expected_scroll)) <= 1.5,
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
