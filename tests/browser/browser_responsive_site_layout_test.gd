extends Node

const BROWSER_SCENE: PackedScene = preload("res://apps/browser/app_browser.tscn")
const WINDOW_SCENE: PackedScene = preload("res://systems/window_manager/window_base.tscn")
const NULL_NETWORK_URLS: Array[String] = [
	"null.net",
	"null.net/getstarted",
	"null.net/register",
	"null.net/forums",
	"null.net/playerrankings",
	"null.net/select-starter",
	"null.net/updates",
]

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
	_check(not browser.tab_scroll.get_h_scroll_bar().visible, "One Browser tab left a horizontal scrollbar visible.")
	_check(browser.get_tab_button_count() == 1, "Browser did not preserve its initial tab button.")
	_check(browser.get_browser_chrome_height() <= 40.0, "Browser chrome exceeded its 40 px logical budget.")
	_check(browser.get_site_viewport_ratio() >= 0.85, "Browser site viewport must retain at least 85% of app height.")

	for index in range(7):
		browser.tabs.append(BrowserTabData.new())
	browser._sync_tab_buttons()
	await _wait_frames(3)
	_check(browser.get_tab_button_count() == browser.tabs.size(), "Persistent tab buttons diverged from BrowserTabData.")
	_check(browser.is_tab_overflow_active(), "Tab overflow did not appear after minimum widths exceeded the strip.")
	_check(browser.tab_scroll.get_h_scroll_bar().visible, "Tab overflow did not expose the horizontal scrollbar.")
	_check(
		browser.get_required_tab_content_width() > browser.tab_scroll.size.x - browser.tab_bar_reserved_margin,
		"Tab overflow was not derived from measured tab content width."
	)
	var first_tab_button := browser.tab_button_container.get_child(0) as BrowserTabButton
	_check(
		first_tab_button != null and first_tab_button.get_reserved_close_width() <= 14.0,
		"Browser tab reserves excessive close-button width."
	)

	browser.size = Vector2(900, 600)
	await _wait_frames(3)
	_check(not browser.is_tab_overflow_active(), "Resize did not hide tab overflow after tabs fit.")
	_check(not browser.tab_scroll.get_h_scroll_bar().visible, "Resize left an unnecessary tab scrollbar visible.")
	browser.size = Vector2(400, 250)
	await _wait_frames(3)
	_check(
		browser.is_tab_overflow_active(),
		"Breakpoint resize did not recalculate tab overflow (browser=%s, scroll=%s, required=%s)." % [
			browser.size.x,
			browser.tab_scroll.size.x,
			browser.get_required_tab_content_width(),
		]
	)

	while browser.tabs.size() > 2:
		await browser._close_tab(browser.tabs.size() - 1)
	await _wait_frames(3)
	_check(not browser.is_tab_overflow_active(), "Closing tabs did not restore the no-overflow state.")
	_check(not browser.tab_scroll.get_h_scroll_bar().visible, "Closing tabs did not hide the horizontal scrollbar.")

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
	var null_home := browser._get_current_site()
	var navigation_source: SiteActionButton
	if null_home != null:
		navigation_source = null_home.find_child("Get Started", true, false) as SiteActionButton
	_check(navigation_source != null, "Null Network home lost its connected SiteActionButton.")
	if navigation_source != null:
		navigation_source.pressed.emit()
		await get_tree().create_timer(0.3).timeout
		_check(
			browser._get_current_tab().current_url == "null.net/getstarted",
			"browser_navigation_requested did not reach BrowserApp."
		)
		browser._on_browser_back_pressed()
		await get_tree().create_timer(0.3).timeout
		_check(browser._get_current_tab().current_url == "null.net", "Browser Back did not reverse SiteActionButton navigation.")

	browser._on_browser_back_pressed()
	await get_tree().create_timer(0.3).timeout
	_check(tab.current_url == "kubuchan.net", "Browser Back did not restore the previous URL.")

	await _test_null_network_overflow_policies(browser)
	await _test_browser_state_restore(browser)
	var session := browser.get_app_session_state()
	_check(
		session.get("tabs", []).size() == browser.tabs.size(),
		"Browser session state did not preserve persistent tabs."
	)

	browser.queue_free()
	await _wait_frames(2)
	await _test_browser_window_density()
	_finish_test()


func _test_null_network_overflow_policies(browser: BrowserApp) -> void:
	for url: String in NULL_NETWORK_URLS:
		browser._load_page(url)
		await get_tree().create_timer(0.3).timeout
		var page := SimulatedDNS.fetch_page(url)
		var site := browser._get_current_site() as Control
		_check(page != null and site != null, "Null Network route %s did not render." % url)
		if page == null or site == null:
			continue
		if page.overflow_policy == WebsitePage.OverflowPolicy.PAGE_SCROLL:
			_check(browser.page_scroll.visible, "%s silently clipped instead of using page-level scroll." % url)
			_check(site.custom_minimum_size.y >= page.get_resolved_canvas_size().y, "%s lost its authored scrolling height." % url)
		else:
			_check(not browser.page_scroll.visible, "%s received an unintended second Browser scrollbar." % url)
			_check(site.custom_minimum_size == Vector2.ZERO, "%s retained a fixed minimum inside its self-managed viewport." % url)


func _test_browser_state_restore(browser: BrowserApp) -> void:
	browser._load_page("null.net/register")
	await get_tree().create_timer(0.35).timeout
	var register := browser._get_current_site() as OperatorCreationPage
	_check(register != null, "Registration page was unavailable for site-state restore coverage.")
	if register == null:
		return
	register.first_name_edit.text = "STATEFUL"
	register.username_edit.text = "restore_test"
	var saved_state := browser.get_app_session_state()

	var restored_browser := BROWSER_SCENE.instantiate() as BrowserApp
	restored_browser.size = Vector2(600, 400)
	add_child(restored_browser)
	await get_tree().create_timer(0.35).timeout
	restored_browser.restore_app_session_state(saved_state)
	await get_tree().create_timer(0.45).timeout
	var restored_register := restored_browser._get_current_site() as OperatorCreationPage
	_check(restored_register != null, "Browser session restore did not recreate the active registration site.")
	if restored_register != null:
		_check(restored_register.first_name_edit.text == "STATEFUL", "Browser session restore lost site-owned form state.")
		_check(restored_register.username_edit.text == "restore_test", "Browser session restore lost the registration username.")
	restored_browser.queue_free()
	await _wait_frames(2)


func _test_browser_window_density() -> void:
	var workspace := Control.new()
	workspace.size = Vector2(900, 600)
	add_child(workspace)
	var window := WINDOW_SCENE.instantiate() as AdaptiveScaleWindowBase
	_check(window != null, "Adaptive WindowBase failed to instantiate for Browser density coverage.")
	if window == null:
		workspace.queue_free()
		return
	workspace.add_child(window)
	window.setup("browser_density", "Browser", Vector2(600, 400), Vector2(400, 250), true)
	var browser := BROWSER_SCENE.instantiate() as BrowserApp
	window.content_container.add_child(browser)
	browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.35).timeout
	_check(window.get_current_window_pixel_density() == AdaptiveScaleWindowBase.PIXEL_DENSITY_2X, "Browser did not begin at 2x window density.")
	_check(browser.get_browser_chrome_height() <= 40.0, "Browser chrome exceeded its budget at 2x density.")

	window.size = Vector2(390, 240)
	await _wait_frames(4)
	_check(window.get_current_window_pixel_density() == AdaptiveScaleWindowBase.PIXEL_DENSITY_1X, "Shrinking Browser did not switch the window to 1x density.")
	_check(browser.get_browser_chrome_height() <= 40.0, "Browser chrome exceeded its budget at 1x density.")
	_check(browser.get_site_viewport_ratio() >= 0.80, "Browser chrome crushed the site viewport at 1x density.")

	window.size = Vector2(430, 280)
	await _wait_frames(4)
	_check(window.get_current_window_pixel_density() == AdaptiveScaleWindowBase.PIXEL_DENSITY_2X, "Growing Browser beyond hysteresis did not restore 2x density.")
	await window.maximize()
	_check(browser.get_browser_chrome_height() <= 40.0, "Maximized Browser chrome exceeded its logical budget.")
	_check(browser.get_site_viewport_ratio() >= 0.85, "Maximized Browser did not preserve the site-dominant layout.")
	workspace.queue_free()
	await _wait_frames(2)


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
