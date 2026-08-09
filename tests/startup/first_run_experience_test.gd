extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog: AppCatalog = ContentRegistry.get_app_catalog()
	_check(catalog != null, "AppCatalog is missing.")

	if catalog != null:
		var default_ids: PackedStringArray = catalog.get_default_app_ids()
		_check(
			default_ids == PackedStringArray(["browser"]),
			"Fresh campaigns must expose Browser as the only default-installed app."
		)

	var browser: AppResource = ContentRegistry.get_app("browser")
	var social: AppResource = ContentRegistry.get_app("social")
	_check(browser != null, "Browser AppResource is missing.")
	_check(
		browser != null and browser.available_while_locked,
		"Browser must remain usable while the prologue shell is locked."
	)
	_check(
		social != null and not social.installed_by_default,
		"Social must not be installed on a fresh campaign."
	)

	var kubuchan: WebsitePage = SimulatedDNS.fetch_page("kubuchan.net")
	_check(kubuchan != null, "Kubuchan route is not registered in SimulatedDNS.")
	_check(
		kubuchan != null and kubuchan.site_scene != null,
		"Kubuchan route has no renderable site scene."
	)

	var registration_event: StoryEventData = ContentRegistry.get_story_event(
		"prologue.registration_started"
	)
	_check(registration_event != null, "Registration StoryEvent is missing.")

	if registration_event != null and registration_event.trigger != null:
		_check(
			registration_event.trigger.trigger_type
			== StoryEventTriggerData.TriggerType.FLAG_CHANGED,
			"Registration must no longer start directly from campaign creation."
		)
		_check(
			registration_event.trigger.watched_flag_name
			== "prologue.registration_unlocked",
			"Registration must wait for the Kubuchan prologue release flag."
		)

	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	if _failures.is_empty():
		print("FIRST_RUN_EXPERIENCE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("FIRST_RUN_EXPERIENCE_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
