extends Node


const CALENDAR_SCENE: PackedScene = preload(
	"res://apps/calendar/calendar_app.tscn"
)
const CAMPAIGN_ID: String = "phase13_calendar"

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/calendar_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	UniversalNotifications.clear_history()
	TimeManager.reset_save_data()
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected Calendar content: %s" % catalog_errors
	)
	_check(
		ContentRegistry.get_all(&"calendar_events").size() == 1,
		"Default Calendar event was not registered."
	)

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 13 Calendar"
	)
	_check(
		create_errors.is_empty(),
		"Could not create Calendar fixture campaign: %s" % create_errors
	)
	_check(
		not CampaignState.has_installed_app("calendar"),
		"Calendar installed before Operator registration."
	)

	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register Calendar fixture Operator: %s"
		% registration_errors
	)
	await _wait_frames(8)
	_check(
		CampaignState.has_installed_app("calendar"),
		"Occupation condition did not auto-install Calendar."
	)

	_assert_base_projection("initial")
	_check(
		LeadIncidentManager.activate_lead(
			"aquarium_signal",
			"calendar_test"
		),
		"Could not activate Calendar fixture Lead."
	)
	await _wait_frames(4)
	_assert_known_campaign_events("active")

	var app := CALENDAR_SCENE.instantiate() as CalendarApp
	_check(app != null, "Calendar scene did not instantiate CalendarApp.")

	if app == null:
		_finish_test()
		return

	add_child(app)
	app.size = Vector2(840, 560)
	await _wait_frames(8)
	_check(
		app.get_visible_day_count() == 8
		and app.get_selected_game_day() == 1
		and app.get_rendered_event_count() >= 3,
		"Calendar app did not render the current eight-day projection."
	)
	_check(
		app.select_game_day(8)
		and app.get_rendered_event_count() == 1,
		"Calendar app did not render Update 1.0 on D+7."
	)

	TimeManager.advance_action(4)
	await _wait_frames(6)
	var advanced: Dictionary = CalendarProjectionService.build_snapshot()
	var current: Dictionary = advanced.get("current", {}) as Dictionary
	var today: Dictionary = (advanced.get("days", []) as Array)[0] as Dictionary
	_check(
		int(current.get("action_block", -1)) == 4
		and str(current.get("hour_label", "")) == "10 AM"
		and int(today.get("remaining_free_blocks", -1)) == 12,
		"Calendar did not refresh block time or remaining free blocks."
	)

	_check(
		SaveManager.save_checkpoint(&"phase13.calendar", true),
		"Could not save Calendar checkpoint."
	)
	app.queue_free()
	await _wait_frames(3)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	var load_errors: PackedStringArray = SaveManager.load_campaign(CAMPAIGN_ID)
	_check(
		load_errors.is_empty(),
		"Calendar campaign reload failed: %s" % load_errors
	)
	await _wait_frames(8)
	_check(
		CampaignState.has_installed_app("calendar")
		and TimeManager.current_action_block == 4
		and CampaignState.active_lead_ids.has("aquarium_signal"),
		"Calendar installation, time or known Lead did not survive reload."
	)
	_assert_base_projection("restored")
	_assert_known_campaign_events("restored")

	var reopened := CALENDAR_SCENE.instantiate() as CalendarApp
	_check(reopened != null, "Calendar could not reopen after reload.")

	if reopened != null:
		add_child(reopened)
		reopened.size = Vector2(840, 560)
		await _wait_frames(8)
		_check(
			reopened.get_selected_game_day() == 1
			and reopened.get_rendered_event_count() >= 3,
			"Restored Calendar did not project current routine and campaign events."
		)
		reopened.queue_free()

	await _wait_frames(2)
	_finish_test()


func _assert_base_projection(boundary: String) -> void:
	var snapshot: Dictionary = CalendarProjectionService.build_snapshot()
	var current: Dictionary = snapshot.get("current", {}) as Dictionary
	var occupation: Dictionary = snapshot.get("occupation", {}) as Dictionary
	var days: Array = snapshot.get("days", []) as Array
	var update_event: Dictionary = _find_event(
		snapshot.get("events", []) as Array,
		"calendar.update_1_0"
	)
	var today: Dictionary = days[0] as Dictionary if not days.is_empty() else {}
	_check(
		int(current.get("game_day", 0)) == 1
		and str(current.get("weekday_name", "")) == "THU"
		and str(current.get("date_label", "")) == "01 JAN 2026"
		and str(current.get("period_name", "")) == "DAY",
		"%s Calendar did not project canonical date and period."
		% boundary.capitalize()
	)
	_check(
		str(occupation.get("occupation_id", "")) == "salaryperson"
		and (today.get("occupied_blocks", []) as Array).size() == 9,
		"%s Calendar did not project the Salaryperson routine."
		% boundary.capitalize()
	)
	_check(
		days.size() == 8
		and not update_event.is_empty()
		and int(update_event.get("game_day", 0)) == 8
		and int(snapshot.get("days_until_update", -1)) == 7,
		"%s Calendar did not project the Update 1.0 countdown."
		% boundary.capitalize()
	)


func _assert_known_campaign_events(boundary: String) -> void:
	var snapshot: Dictionary = CalendarProjectionService.build_snapshot()
	var events: Array = snapshot.get("events", []) as Array
	_check(
		not _find_event(events, "lead.aquarium_signal").is_empty(),
		"%s Calendar did not project the known active Lead."
		% boundary.capitalize()
	)
	_check(
		not _find_event(events, "incident.akihabara_aquarium_relay").is_empty(),
		"%s Calendar did not project the available Incident."
		% boundary.capitalize()
	)


func _find_event(events: Array, event_id: String) -> Dictionary:
	for event_value: Variant in events:
		if event_value is Dictionary \
			and str((event_value as Dictionary).get("event_id", "")) == event_id:
			return event_value as Dictionary

	return {}


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Gyu"
	profile.last_name = "Calendar"
	profile.nickname = "Operator"
	profile.username = "calendar_operator"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "salaryperson"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_calendar"
	appearance.face_id = "face_calendar"
	appearance.eye_id = "eyes_calendar"
	appearance.outer_layer_id = "outer_calendar"
	appearance.middle_layer_id = "middle_calendar"
	appearance.lower_layer_id = "lower_calendar"
	appearance.hat_id = "hat_calendar"
	appearance.facial_accessory_id = "accessory_calendar"
	return appearance


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	UniversalNotifications.clear_history()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("CALENDAR_APP_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("CALENDAR_APP_TEST: FAIL (%d)" % _failures.size())
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
