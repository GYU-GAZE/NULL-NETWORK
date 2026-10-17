extends Node

const BROWSER: PackedScene = preload("res://apps/browser/app_browser.tscn")
const FAILING: Script = preload("res://tests/browser/fixtures/failing_site_effect.gd")
var failures := PackedStringArray()
var browser: BrowserApp
var fixture: Dictionary
var captures: String = ""


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-directory="):
			captures = argument.trim_prefix("--capture-directory=")
			DirAccess.make_dir_recursive_absolute(captures)
			KubuDisplaySetting.set_windowed_size(Vector2i(1600, 1000))
	_test_routes_and_history()
	fixture = BrowserAuthoringFixture.build()
	check(fixture.ok, "Authoring flow failed: %s" % fixture)
	if not fixture.ok:
		finish()
		return
	check(fixture.catalog.validate_data().is_empty(), "Generated catalog is invalid")
	var catalog_before := FileAccess.get_file_as_bytes(fixture.catalog_path)
	var duplicate := WebsiteAuthoring.create_page({"name": "duplicate", "url": "HTTPS://WWW.ACCEPTANCE.LOCAL/", "title": "Duplicate", "folder": BrowserAuthoringFixture.ROOT, "catalog": fixture.catalog_path})
	check(not duplicate.ok, "Authoring accepted a normalized duplicate URL")
	check(catalog_before == FileAccess.get_file_as_bytes(fixture.catalog_path), "Rejected creation modified the catalog")
	check(not FileAccess.file_exists(BrowserAuthoringFixture.ROOT.path_join("duplicate.tscn")), "Rejected creation left a partial scene")
	# A directory occupying the temporary catalog path forces a real save
	# failure after the new scene and page Resource have already been written.
	var pending := str(fixture.catalog_path).get_basename() + ".pending.tres"
	DirAccess.make_dir_absolute(pending)
	print("AUTHORING_EXPECTED_WRITE_FAILURE: BEGIN")
	var interrupted := WebsiteAuthoring.create_page({"name": "rollback_probe", "url": "rollback.local", "title": "Rollback", "folder": BrowserAuthoringFixture.ROOT, "catalog": fixture.catalog_path})
	print("AUTHORING_EXPECTED_WRITE_FAILURE: END")
	check(not interrupted.ok, "Catalog save failure was reported as success")
	check(catalog_before == FileAccess.get_file_as_bytes(fixture.catalog_path), "Catalog save failure changed the original catalog")
	for extension: String in ["tscn", "tres"]:
		check(not FileAccess.file_exists(BrowserAuthoringFixture.ROOT.path_join("rollback_probe." + extension)), "Interrupted creation left a new partial file")
	DirAccess.remove_absolute(pending)
	var old_catalog: WebsiteCatalog = SimulatedDNS.website_catalog
	SimulatedDNS.website_catalog = fixture.catalog
	SimulatedDNS.rebuild_routes()
	GameState.set_flag(BrowserAuthoringFixture.FLAG, false)
	GameState.set_flag(BrowserAuthoringFixture.EFFECT, false)
	browser = BROWSER.instantiate() as BrowserApp
	browser.size = Vector2(600, 400)
	add_child(browser)
	browser._load_page(BrowserAuthoringFixture.URL)
	await settle()
	await _test_document_and_actions()
	await _test_history_tabs_and_transitions()
	await _test_window_cycles()
	await _test_existing_sites(old_catalog)
	browser.queue_free()
	await get_tree().process_frame
	SimulatedDNS.website_catalog = old_catalog
	SimulatedDNS.rebuild_routes()
	finish()


func _test_routes_and_history() -> void:
	for value: String in ["https://www.Null.Net/", "http://null.net", "NULL.NET///"]:
		check(BrowserRoute.normalize(value) == "null.net", "Route normalization disagrees: %s" % value)
	check(not BrowserRoute.validate(" ").is_empty(), "Empty URL accepted")
	check(BrowserRoute.matches_prefix("null.net/forums/thread/1", "null.net/forums/"), "Segment prefix failed")
	check(not BrowserRoute.matches_prefix("null.net/forumspam", "null.net/forums"), "Prefix matched a different path segment")
	var catalog := WebsiteCatalog.new()
	var first := WebsitePage.new()
	first.url = "https://www.test.local/"
	var second := WebsitePage.new()
	second.url = "test.local"
	catalog.pages.assign([first, second, null])
	var errors := catalog.validate_data()
	check(errors.size() >= 4, "Catalog omitted duplicate/null/scene errors")
	var tab := BrowserTabData.from_session_state({"current_url": "second.local", "history": ["first.local", "second.local"], "history_index": 1, "site_state": {"form": "legacy"}})
	check(tab.current_url == "second.local" and tab.current_entry().page_state.form == "legacy", "v1 tab state was not migrated")
	tab.go_back()
	check(tab.current_entry().page_state.is_empty(), "v1 state leaked into a different history entry")
	tab.navigate_to("third.local")
	check(not tab.can_go_forward() and tab.history.size() == 2, "New navigation did not truncate the forward branch")
	var transient := Node.new()
	tab.current_entry().page_state = {"node": transient, "nested": [transient, {"value": 12}]}
	var saved := tab.to_session_state()
	check(saved.entries[1].page_state.node == null and saved.entries[1].page_state.nested[0] == null, "Session persisted transient Node references")
	transient.free()
	var restored := BrowserTabData.from_session_state(saved)
	check(restored.current_url == "third.local" and restored.history.size() == 2, "v2 history roundtrip failed")


func _test_document_and_actions() -> void:
	var page := browser._get_current_site() as Control
	check(page != null and browser._active_url == BrowserAuthoringFixture.URL, "Active page is not explicit")
	var gate := page.get_node("Content/ConditionalAction") as SiteActionButton
	var before := gate.action_binding.refresh_count
	GameState.set_flag("test.browser.irrelevant", true)
	check(gate.action_binding.refresh_count == before, "Unrelated flags refreshed the action")
	gate.pressed.emit()
	check(not GameState.get_flag(BrowserAuthoringFixture.EFFECT), "Blocked action applied an effect")
	check(is_instance_valid(UniversalAlerts.active_layer) and UniversalAlerts.active_layer.is_open, "Blocked action did not open its authored alert")
	if is_instance_valid(UniversalAlerts.active_layer):
		UniversalAlerts.active_layer.close_alert()
	page.get_node("Content/EnableAction").pressed.emit()
	check(gate.action_binding.available, "Condition did not update reactively after its flag changed")
	var definition := gate.action_data.notification
	var original_id := definition.notification_id
	var notification_count: int = UniversalNotifications.notification_history.size()
	gate.pressed.emit()
	check(GameState.get_flag(BrowserAuthoringFixture.EFFECT), "Action did not reuse SetFlagEffectData")
	check(UniversalNotifications.notification_history.size() == notification_count + 1, "Successful action did not publish exactly one notification")
	var notification: KubuNotificationData = UniversalNotifications.notification_history[0]
	check(notification.priority == KubuNotificationData.NotificationPriority.HIGH and notification.source_app_id == "browser" and notification.target_url.ends_with("/second"), "Structured notification lost routing/classification")
	check(definition.notification_id == original_id and notification != definition, "Notification publishing mutated shared content")
	var failing := gate.action_data.duplicate(true) as SiteActionData
	var effect := FAILING.new() as GameEffectData
	effect.effect_id = "fixture.expected_failure"
	failing.effects.assign([effect])
	failing.target_url = BrowserAuthoringFixture.URL + "/second"
	var active_before := browser._active_url
	var result := SiteActionRunner.execute(failing, gate)
	check(result.status == "failed", "Effect failure was not reported")
	check(UniversalNotifications.notification_history.size() == notification_count + 1 and browser._active_url == active_before, "Effect failure emitted success feedback or navigated")
	# Same Resource on a card: no Button inheritance is required.
	var card := PanelContainer.new()
	var binding := SiteActionBinding.new()
	binding.action_data = gate.action_data
	card.add_child(binding)
	page.get_node("Content").add_child(card)
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	card.gui_input.emit(accept)
	check(UniversalNotifications.notification_history.size() == notification_count + 2, "Non-Button action binding did not execute")
	card.queue_free()
	var rich_link := SiteRichTextLabel.new()
	rich_link.actions["shared"] = gate.action_data
	rich_link.text = "[url=action:shared]Shared Resource action[/url]"
	page.get_node("Content").add_child(rich_link)
	rich_link.meta_clicked.emit("action:shared")
	check(UniversalNotifications.notification_history.size() == notification_count + 3, "Rich link did not execute the shared Resource action")
	rich_link.queue_free()
	for extent: Vector2 in [Vector2(600, 400), Vector2(320, 250), Vector2(430, 320), Vector2(700, 480)]:
		browser.size = extent
		await settle()
		var columns := page.get_node("Content/Columns") as ResponsiveColumns
		check(columns.compact == (columns.size.x < 368), "Measured responsive columns chose the wrong orientation")
		check(page.size.x <= browser.page_scroll.size.x + 1, "Document overflowed horizontally at %s" % extent)
		check(page.position == Vector2.ZERO and browser._active_surface.position == Vector2.ZERO, "Animation displaced document origin")
		await _check_document_bounds(page)
		await capture("authored_%dx%d" % [extent.x, extent.y])
	var maximum := browser.page_scroll.get_v_scroll_bar().max_value
	page.get_node("Content/Expand").pressed.emit()
	await settle()
	check(browser.page_scroll.get_v_scroll_bar().max_value > maximum + 100, "Revealed content did not extend document scroll range")
	await _check_document_bounds(page)
	# Conditions configured as disable/hide must recover automatically too.
	for behavior: int in [SiteActionButton.FailedConditionBehavior.DISABLE_BUTTON, SiteActionButton.FailedConditionBehavior.HIDE_BUTTON]:
		var button := SiteActionButton.new()
		button.action_data = gate.action_data
		button.failed_condition_behavior = behavior as SiteActionButton.FailedConditionBehavior
		page.get_node("Content").add_child(button)
		GameState.set_flag(BrowserAuthoringFixture.FLAG, false)
		check(button.disabled if behavior == 1 else not button.visible, "Unavailable condition visual policy was ignored")
		GameState.set_flag(BrowserAuthoringFixture.FLAG, true)
		check(not button.disabled and button.visible, "Condition visual policy did not recover")
		button.queue_free()


func _test_history_tabs_and_transitions() -> void:
	var page := browser._get_current_site() as Control
	page.get_node("Content/NameField").text = "first entry"
	browser.page_scroll.scroll_vertical = 80
	page.get_node("Content/NextPage").pressed.emit()
	await settle()
	var second := browser._get_current_site() as Control
	second.get_node("Content/NameField").text = "second entry"
	browser._on_browser_back_pressed()
	await settle()
	page = browser._get_current_site() as Control
	check(page.get_node("Content/NameField").text == "first entry", "Back lost the previous entry's form state")
	check(browser.page_scroll.scroll_vertical == 80, "Back lost the previous entry's scroll state")
	check(page.get_node("Content/ExtraContent").visible, "Infrastructure form state lost expanded content")
	browser._on_browser_forward_pressed()
	await settle()
	check(browser._get_current_site().get_node("Content/NameField").text == "second entry", "Forward lost its independent form state")
	browser._create_tab(BrowserAuthoringFixture.URL)
	await settle()
	browser._get_current_site().get_node("Content/NameField").text = "other tab"
	browser._switch_tab(0)
	await settle()
	check(browser._get_current_site().get_node("Content/NameField").text == "second entry", "Switching tabs mixed history states")
	browser._switch_tab(1)
	await settle()
	check(browser._get_current_site().get_node("Content/NameField").text == "other tab", "Returning to another tab lost its state")
	# Cancel transitions across different policies; the current site must never
	# be inferred from an old child still present in the other host.
	var outgoing := browser._active_context
	var old_action := browser._get_current_site().get_node("Content/ConditionalAction") as SiteActionButton
	browser._load_page(BrowserAuthoringFixture.URL + "/application")
	check(browser._get_current_site() == browser._active_site and not browser.page_scroll.visible, "Cross-policy navigation exposed an outgoing page as current")
	check(not outgoing.enabled, "Outgoing page context remains interactive")
	check(SiteActionRunner.execute(old_action.action_data, old_action).status == "inactive_page", "Outgoing control still executes gameplay effects")
	browser._load_page(BrowserAuthoringFixture.URL + "/viewport")
	browser._load_page(BrowserAuthoringFixture.URL)
	await settle()
	check(browser._active_url == BrowserAuthoringFixture.URL and browser.page_scroll.visible, "Latest navigation lost to a cancelled transition")
	check(browser.site_container.get_child_count() == 0 and browser.scroll_site_container.get_child_count() == 1, "Cancelled transition leaked stale page surfaces")
	# A link created after page initialization routes through ancestor context.
	var dynamic := SiteActionButton.new()
	dynamic.action_data = SiteActionData.new()
	dynamic.action_data.target_url = BrowserAuthoringFixture.URL + "/second"
	browser._get_current_site().get_node("Content").add_child(dynamic)
	dynamic.pressed.emit()
	await settle()
	check(browser._active_url.ends_with("/second"), "Dynamically created link needed manual signal wiring")
	browser._get_current_site().get_node("Content/NameField").text = "session state"
	var saved := browser.get_app_session_state()
	var restored := BROWSER.instantiate() as BrowserApp
	restored.size = Vector2(500, 360)
	add_child(restored)
	restored.restore_app_session_state(saved)
	await settle()
	check(restored._get_current_site().get_node("Content/NameField").text == "session state", "v2 session restoration lost per-entry form state")
	check(restored.tabs.size() == 2, "Session restoration lost tabs")
	restored.queue_free()
	await get_tree().process_frame
	# Repeated visits to the same route are separate history entries.
	browser._load_page(BrowserAuthoringFixture.URL)
	await settle()
	browser._get_current_site().get_node("Content/NameField").text = "same URL / first visit"
	browser._load_page(BrowserAuthoringFixture.URL)
	await settle()
	browser._get_current_site().get_node("Content/NameField").text = "same URL / second visit"
	browser._on_browser_back_pressed()
	await settle()
	check(browser._get_current_site().get_node("Content/NameField").text == "same URL / first visit", "Repeated URL visits shared a single state dictionary")
	browser._on_browser_forward_pressed()
	await settle()
	check(browser._get_current_site().get_node("Content/NameField").text == "same URL / second visit", "Forward mixed repeated URL visits")


func _test_window_cycles() -> void:
	var manager := (load("res://systems/window_manager/window_manager.tscn") as PackedScene).instantiate() as WindowManager
	manager.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	manager.size = Vector2(800, 560)
	add_child(manager)
	var app := AppResource.new()
	app.app_id = "browser_authoring_window"
	app.app_name = "Authored website"
	app.app_scene = BROWSER
	app.default_window_size = Vector2(520, 400)
	app.min_window_size = Vector2(400, 300)
	app.can_resize = true
	manager._on_request_open_app(app)
	var window := manager.open_windows[app.app_id] as WindowBase
	await window.wait_until_opened()
	var mounted := window.content_container.get_child(0) as BrowserApp
	mounted._load_page(BrowserAuthoringFixture.URL)
	await settle()
	mounted._get_current_site().get_node("Content/NameField").text = "window cycles"
	for index: int in range(2):
		var rectangle := window.get_rect()
		await window.maximize(false)
		await settle()
		check(mounted._get_current_site().size.x <= mounted.content_area.size.x + 1, "Maximized authored page overflowed its window")
		await window.restore_from_maximized(false)
		await settle()
		check(window.get_rect() == rectangle, "Authored website changed the window restore rectangle")
		window.apply_resolved_geometry(Rect2(Vector2(20, 20), Vector2(400 + index * 70, 300 + index * 50)))
		await settle()
		var page := mounted._get_current_site() as Control
		check(page.position == Vector2.ZERO and page.scale == Vector2.ONE, "Window cycles changed authored document origin or scale")
		check(page.size.x <= mounted.content_area.size.x + 1, "Resized authored page overflowed its window")
		check(page.get_node("Content/NameField").text == "window cycles", "Window cycles lost live form state")
	await capture("authored_window_cycles")
	manager.reset_save_data()
	manager.queue_free()
	await get_tree().process_frame


func _test_existing_sites(catalog: WebsiteCatalog) -> void:
	SimulatedDNS.website_catalog = catalog
	SimulatedDNS.rebuild_routes()
	check(catalog.validate_data().is_empty(), "Migrated production catalog validation failed")
	for url: String in ["null.net", "null.net/getstarted", "null.net/register", "null.net/select-starter", "null.net/forums", "null.net/playerrankings", "null.net/updates", "kubuchan.net", "kubus://home"]:
		browser.size = Vector2(390, 300)
		browser._load_page(url)
		await settle()
		var page := browser._get_current_site() as Control
		check(page != null and browser._active_url == url, "Production route did not render: %s" % url)
		if page == null:
			continue
		var definition: WebsitePage = SimulatedDNS.fetch_page(url)
		check(browser.page_scroll.visible == (definition.overflow_policy == WebsitePage.OverflowPolicy.PAGE_SCROLL), "Production page has conflicting scroll host: %s" % url)
		check(page.scale == Vector2.ONE, "Production page changed fixed pixel scale: %s" % url)
		check(page.size.x <= browser.content_area.size.x + 1, "Production page forces horizontal overflow at 390 logical units: %s (%s > %s)" % [url, page.size.x, browser.content_area.size.x])
		for node: Node in page.find_children("*", "ScrollContainer", true, false):
			var scroll := node as ScrollContainer
			if scroll.is_visible_in_tree() and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
				check(scroll.size.x <= browser.content_area.size.x + 1, "Internal scroll overflows the page: %s / %s (%s)" % [url, page.get_path_to(scroll), scroll.size])
		if url == "kubuchan.net":
			browser.size.x = 800
			await settle()
			browser.size.x = 390
			await settle()
			check((page.get_node("PageRoot/PageScroll") as ScrollContainer).size.x <= 390, "Kubuchan could not shrink after expansion")
		await capture(url.replace("://", "_").replace("/", "_").replace(".", "_"))


func _check_document_bounds(page: Control) -> void:
	var bar := browser.page_scroll.get_v_scroll_bar()
	check(bar.max_value > bar.page, "Long document did not expose scroll")
	browser.page_scroll.scroll_vertical = ceili(bar.max_value - bar.page)
	await get_tree().process_frame
	await get_tree().process_frame
	var footer := page.get_node("Footer") as Control
	check(footer.get_global_rect().end.y <= browser.page_scroll.get_global_rect().end.y + 1.5, "Document footer is unreachable")
	await capture("authored_footer_%d" % int(browser.size.x))
	browser.page_scroll.scroll_vertical = 0
	await get_tree().process_frame


func settle() -> void:
	await get_tree().create_timer(0.32).timeout


func capture(name: String) -> void:
	if captures.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(captures.path_join(name + ".png"))


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func finish() -> void:
	for failure: String in failures:
		push_error(failure)
	print("BROWSER_AUTHORING_PIPELINE_TEST: PASS" if failures.is_empty() else "BROWSER_AUTHORING_PIPELINE_TEST: FAIL (%d)" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
