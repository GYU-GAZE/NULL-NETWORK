extends PanelContainer
class_name CalendarApp


@onready var current_date_label: Label = %CurrentDateLabel
@onready var current_period_label: Label = %CurrentPeriodLabel
@onready var current_block_label: Label = %CurrentBlockLabel
@onready var available_blocks_label: Label = %AvailableBlocksLabel
@onready var update_countdown_label: Label = %UpdateCountdownLabel
@onready var next_event_label: Label = %NextEventLabel
@onready var day_button_list: VBoxContainer = %DayButtonList
@onready var selected_day_label: Label = %SelectedDayLabel
@onready var occupation_label: Label = %OccupationLabel
@onready var selected_day_summary: Label = %SelectedDaySummary
@onready var event_list: VBoxContainer = %EventList
@onready var empty_events_label: Label = %EmptyEventsLabel


var _snapshot: Dictionary = {}
var _selected_game_day: int = -1
var _day_buttons: Dictionary = {}
var _refresh_queued: bool = false


func _ready() -> void:
	_connect_signals()
	refresh_calendar()


func refresh_calendar() -> void:
	_refresh_queued = false
	_snapshot = CalendarProjectionService.build_snapshot()
	var current: Dictionary = _snapshot.get("current", {}) as Dictionary
	var current_day: int = int(current.get("game_day", TimeManager.days_passed))

	if not _contains_game_day(_selected_game_day):
		_selected_game_day = current_day

	_render_header()
	_rebuild_day_buttons()
	_render_selected_day()


func get_visible_day_count() -> int:
	return (_snapshot.get("days", []) as Array).size()


func get_selected_game_day() -> int:
	return _selected_game_day


func get_rendered_event_count() -> int:
	var selected: Dictionary = _get_selected_day_snapshot()
	return (selected.get("events", []) as Array).size()


func get_next_event_id() -> String:
	var next_event: Dictionary = _snapshot.get("next_event", {}) as Dictionary
	return str(next_event.get("event_id", ""))


func select_game_day(game_day: int) -> bool:
	if not _contains_game_day(game_day):
		return false

	_selected_game_day = game_day
	_update_day_button_selection()
	_render_selected_day()
	return true


func _connect_signals() -> void:
	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	if not CampaignState.lead_state_changed.is_connected(_on_lead_state_changed):
		CampaignState.lead_state_changed.connect(_on_lead_state_changed)

	if not CampaignState.incident_state_changed.is_connected(
		_on_incident_state_changed
	):
		CampaignState.incident_state_changed.connect(_on_incident_state_changed)

	if not ContentRegistry.registry_rebuilt.is_connected(_on_registry_rebuilt):
		ContentRegistry.registry_rebuilt.connect(_on_registry_rebuilt)


func _render_header() -> void:
	var current: Dictionary = _snapshot.get("current", {}) as Dictionary
	var occupation: Dictionary = _snapshot.get("occupation", {}) as Dictionary
	var next_event: Dictionary = _snapshot.get("next_event", {}) as Dictionary

	current_date_label.text = "%s // %s" % [
		str(current.get("weekday_name", "---")),
		str(current.get("date_label", "-- --- ----"))
	]
	current_period_label.text = "%s // %s" % [
		str(current.get("period_name", "UNKNOWN")),
		str(current.get("hour_label", "--"))
	]
	current_block_label.text = "BLOCK %02d / 11" % int(
		current.get("action_block", 0)
	)
	available_blocks_label.text = "%d BLOCKS LEFT IN %s" % [
		int(current.get("actions_left_in_period", 0)),
		str(current.get("period_name", "PERIOD"))
	]
	update_countdown_label.text = (
		"UPDATE 1.0 // TODAY"
		if int(_snapshot.get("days_until_update", 0)) == 0
		else "UPDATE 1.0 // D-%d" % int(
			_snapshot.get("days_until_update", 0)
		)
	)
	occupation_label.text = "ROUTINE // %s" % str(
		occupation.get("display_name", "NO OCCUPATION")
	)

	if next_event.is_empty():
		next_event_label.text = "NEXT // NO KNOWN EVENT"
	else:
		var next_day: int = int(next_event.get("game_day", TimeManager.days_passed))
		var day_delta: int = next_day - TimeManager.days_passed
		var day_label: String = (
			"TODAY"
			if day_delta == 0
			else "D+%d" % day_delta
		)
		next_event_label.text = "NEXT // %s // %s // %s" % [
			day_label,
			str(next_event.get("time_label", "")),
			str(next_event.get("title", "UNKNOWN EVENT"))
		]


func _rebuild_day_buttons() -> void:
	_clear_container(day_button_list)
	_day_buttons.clear()

	for day_value: Variant in _snapshot.get("days", []):
		if day_value is not Dictionary:
			continue

		var day: Dictionary = day_value as Dictionary
		var game_day: int = int(day.get("game_day", -1))
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 48.0
		button.text = "%s  %02d/%02d\n%s  ·  %d FREE" % [
			str(day.get("weekday_name", "---")),
			int(day.get("calendar_day", 1)),
			int(day.get("month", 1)),
			"TODAY" if bool(day.get("is_today", false)) else "DAY %d" % game_day,
			int(day.get("remaining_free_blocks", 0))
		]
		button.set_meta(&"game_day", game_day)
		button.pressed.connect(_on_day_button_pressed.bind(game_day))
		day_button_list.add_child(button)
		_day_buttons[game_day] = button

	_update_day_button_selection()


func _update_day_button_selection() -> void:
	for raw_day: Variant in _day_buttons:
		var button := _day_buttons[raw_day] as Button

		if button != null:
			button.button_pressed = int(raw_day) == _selected_game_day


func _render_selected_day() -> void:
	_clear_container(event_list)
	var day: Dictionary = _get_selected_day_snapshot()

	if day.is_empty():
		selected_day_label.text = "NO DAY SELECTED"
		selected_day_summary.text = ""
		empty_events_label.visible = true
		return

	selected_day_label.text = "%s // %s // GAME DAY %d" % [
		str(day.get("weekday_name", "---")),
		str(day.get("date_label", "-- --- ----")),
		int(day.get("game_day", 1))
	]
	selected_day_summary.text = "%d FREE BLOCKS REMAINING // %d OCCUPIED BLOCKS" % [
		int(day.get("remaining_free_blocks", 0)),
		(day.get("occupied_blocks", []) as Array).size()
	]
	var events: Array = day.get("events", []) as Array
	empty_events_label.visible = events.is_empty()

	for event_value: Variant in events:
		if event_value is not Dictionary:
			continue

		_render_event(event_value as Dictionary)


func _render_event(event: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 72.0
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var content := VBoxContainer.new()
	var header := Label.new()
	header.text = "%s // %s" % [
		str(event.get("time_label", "")),
		str(event.get("kind_label", "EVENT"))
	]
	var title := Label.new()
	title.text = str(event.get("title", "UNKNOWN EVENT"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var description := Label.new()
	description.text = str(event.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var location_id: String = str(event.get("location_id", "")).strip_edges()

	if not location_id.is_empty():
		var location: MapLocation = ContentRegistry.get_location(location_id)
		var location_label := Label.new()
		location_label.text = "LOCATION // %s" % (
			location.location_name if location != null else location_id
		)
		content.add_child(header)
		content.add_child(title)
		content.add_child(description)
		content.add_child(location_label)
	else:
		content.add_child(header)
		content.add_child(title)
		content.add_child(description)

	margin.add_child(content)
	panel.add_child(margin)
	event_list.add_child(panel)


func _get_selected_day_snapshot() -> Dictionary:
	for day_value: Variant in _snapshot.get("days", []):
		if day_value is Dictionary \
			and int((day_value as Dictionary).get("game_day", -1)) \
			== _selected_game_day:
			return day_value as Dictionary

	return {}


func _contains_game_day(game_day: int) -> bool:
	if game_day < 1:
		return false

	for day_value: Variant in _snapshot.get("days", []):
		if day_value is Dictionary \
			and int((day_value as Dictionary).get("game_day", -1)) == game_day:
			return true

	return false


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _queue_refresh() -> void:
	if _refresh_queued or is_queued_for_deletion():
		return

	_refresh_queued = true
	call_deferred("refresh_calendar")


func _on_day_button_pressed(game_day: int) -> void:
	select_game_day(game_day)


func _on_time_advanced(
	_period: int,
	_days_passed: int,
	_calendar_day: int,
	_month_short: String
) -> void:
	_queue_refresh()


func _on_campaign_changed(_section: StringName) -> void:
	_queue_refresh()


func _on_lead_state_changed(_lead_id: String) -> void:
	_queue_refresh()


func _on_incident_state_changed(_incident_id: String) -> void:
	_queue_refresh()


func _on_registry_rebuilt() -> void:
	_queue_refresh()
