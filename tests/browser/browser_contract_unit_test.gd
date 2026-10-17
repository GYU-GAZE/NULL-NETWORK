extends Node

var failures := PackedStringArray()


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	var flag := FlagConditionData.new()
	flag.flag_name = "test.browser.unit.flag"
	var number := NumberConditionData.new()
	number.number_name = "test.browser.unit.number"
	number.minimum_value = 3
	var group := ConditionSetData.new()
	group.rules.assign([flag, number])
	var action := SiteActionData.new()
	action.conditions = group
	var button := SiteActionButton.new()
	button.action_data = action
	button.failed_condition_behavior = SiteActionButton.FailedConditionBehavior.DISABLE_BUTTON
	add_child(button)
	check(button.disabled, "Initial composite conditions ignored current state")
	GameState.set_flag(flag.flag_name, true)
	check(button.disabled, "ALL condition ignored number condition")
	var count := button.action_binding.refresh_count
	GameState.set_number("test.browser.unrelated.number", 99)
	check(button.action_binding.refresh_count == count, "Unrelated numeric state refreshed action")
	GameState.set_number(number.number_name, 3)
	check(not button.disabled, "Relevant numeric signal did not unlock action")
	var dependent := SiteActionButton.new()
	dependent.action_data = SiteActionData.new()
	var occupation := OccupationConditionData.new()
	occupation.requirement = OccupationConditionData.Requirement.HAS_ANY
	dependent.action_data.conditions = occupation
	add_child(dependent)
	count = dependent.action_binding.refresh_count
	CampaignState.campaign_changed.emit(&"inventory")
	check(dependent.action_binding.refresh_count == count, "Unrelated campaign domain refreshed occupation condition")
	CampaignState.campaign_changed.emit(&"operator")
	check(dependent.action_binding.refresh_count == count + 1, "Relevant campaign domain did not refresh occupation condition")
	var timed := SiteActionButton.new()
	timed.action_data = SiteActionData.new()
	timed.action_data.conditions = TimeConditionData.new()
	add_child(timed)
	count = timed.action_binding.refresh_count
	GlobalSignals.time_advanced.emit(0, 0, 1, "JAN")
	check(timed.action_binding.refresh_count == count + 1, "Time condition has no reactive signal")
	var notification := KubuNotificationData.new()
	notification.title = "Shared definition"
	notification.notification_id = "authored_identity"
	notification.is_read = true
	notification.set_meta("authoring_tag", "preserved metadata")
	var first: KubuNotificationData = UniversalNotifications.push_resource(notification, "browser", "unit.local")
	var second: KubuNotificationData = UniversalNotifications.push_resource(notification, "browser", "unit.local")
	check(first.notification_id != second.notification_id, "Same-frame notifications reused runtime identity")
	check(notification.notification_id == "authored_identity" and notification.is_read, "Notification Resource was mutated")
	check(first.source_app_id == "browser" and first.target_url == "unit.local", "Notification defaults lost page context")
	check(first.get_meta("authoring_tag", "") == "preserved metadata", "Notification publishing discarded Resource metadata")
	var layout := ResponsiveColumns.new()
	layout.size = Vector2(240, 160)
	add_child(layout)
	var children: Array[Control] = []
	for index: int in range(2):
		var child := Control.new()
		child.custom_minimum_size = Vector2(150, 30)
		child.scale = Vector2(0.8, 0.8)
		layout.add_child(child)
		children.append(child)
	await get_tree().process_frame
	await get_tree().process_frame
	check(layout.compact and children[1].position.y >= children[0].size.y, "Compact layout overlaps child rectangles")
	check(children[0].scale == Vector2(0.8, 0.8), "Container overwrote child animation transform")
	layout.size.x = 400
	await get_tree().process_frame
	await get_tree().process_frame
	check(not layout.compact and children[1].position.x >= children[0].size.x, "Wide layout failed to order columns")
	children[1].custom_minimum_size.x = 300
	await get_tree().process_frame
	await get_tree().process_frame
	check(layout.compact, "Dynamic child minimum changes did not update responsive layout")
	var preferred := PreferredWidthContainer.new()
	preferred.preferred_width = 800
	preferred.size = Vector2(800, 100)
	add_child(preferred)
	var paragraph := Label.new()
	paragraph.text = "A wrapping paragraph keeps its preferred width separate from its minimum."
	paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preferred.add_child(paragraph)
	await get_tree().process_frame
	await get_tree().process_frame
	preferred.size.x = 250
	await get_tree().process_frame
	await get_tree().process_frame
	check(preferred.get_combined_minimum_size().x <= 250 and paragraph.size.x <= 250, "Preferred content width became a sticky minimum after resize")
	preferred.queue_free()
	var scene := PackedScene.new()
	var root := Control.new()
	scene.pack(root)
	root.free()
	var page := WebsitePage.new()
	page.site_scene = scene
	check(not page.validate_data().is_empty(), "A document without a Container root was accepted")
	page.overflow_policy = WebsitePage.OverflowPolicy.SELF_MANAGED_SCROLL
	check(not page.validate_data().is_empty(), "Self-managed page without scroll was accepted")
	page.overflow_policy = WebsitePage.OverflowPolicy.FIXED_VIEWPORT
	check(page.validate_data().is_empty(), "Intentional viewport contract was rejected")
	var previous_catalog: WebsiteCatalog = SimulatedDNS.website_catalog
	var routes := WebsiteCatalog.new()
	for route: String in ["unit.local/section", "unit.local/section/deep", "unit.local/section/deep/exact"]:
		var definition := WebsitePage.new()
		definition.url = route
		definition.site_scene = scene
		definition.overflow_policy = WebsitePage.OverflowPolicy.FIXED_VIEWPORT
		definition.match_as_prefix = not route.ends_with("exact")
		routes.pages.append(definition)
	SimulatedDNS.website_catalog = routes
	SimulatedDNS.rebuild_routes()
	check(SimulatedDNS.fetch_page("unit.local/section/deep/child") == routes.pages[1], "Router ignored longest segment prefix")
	check(SimulatedDNS.fetch_page("unit.local/section/deep/exact") == routes.pages[2], "Exact route did not override matching prefixes")
	check(SimulatedDNS.fetch_page("unit.local/sectionspam") == null, "Router accepted a prefix outside its segment boundary")
	SimulatedDNS.website_catalog = previous_catalog
	SimulatedDNS.rebuild_routes()
	button.queue_free()
	dependent.queue_free()
	timed.queue_free()
	layout.queue_free()
	await get_tree().process_frame
	for failure: String in failures:
		push_error(failure)
	print("BROWSER_CONTRACT_UNIT_TEST: PASS" if failures.is_empty() else "BROWSER_CONTRACT_UNIT_TEST: FAIL (%d)" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
