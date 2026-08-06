extends RefCounted
class_name CalendarProjectionService


const DEFAULT_VISIBLE_DAYS: int = 7
const MAX_VISIBLE_DAYS: int = 30


static func build_snapshot(
	visible_day_count: int = DEFAULT_VISIBLE_DAYS
) -> Dictionary:
	var day_count: int = clampi(visible_day_count, 1, MAX_VISIBLE_DAYS)
	var first_day: int = TimeManager.days_passed
	var last_day: int = first_day + day_count - 1
	var occupation: OccupationData = _get_operator_occupation()
	var authored_events: Array[CalendarEventData] = _get_visible_authored_events(
		first_day,
		last_day
	)
	var days: Array[Dictionary] = []
	var all_events: Array[Dictionary] = []

	for game_day: int in range(first_day, last_day + 1):
		var day_snapshot: Dictionary = _build_day_snapshot(
			game_day,
			occupation,
			authored_events
		)
		days.append(day_snapshot)

		for event_value: Variant in day_snapshot.get("events", []):
			if event_value is Dictionary:
				all_events.append(event_value as Dictionary)

	all_events.sort_custom(_sort_event_snapshots)
	var next_event: Dictionary = _find_next_event(all_events)

	return {
		"current": _build_current_time_snapshot(),
		"occupation": _build_occupation_snapshot(occupation),
		"days": days,
		"events": all_events,
		"next_event": next_event,
		"days_until_update": TimeManager.days_until_update,
		"update_game_day": (
			TimeManager.days_passed + TimeManager.days_until_update
		)
	}


static func build_day_snapshot(game_day: int) -> Dictionary:
	var safe_day: int = maxi(1, game_day)
	var occupation: OccupationData = _get_operator_occupation()
	var authored_events: Array[CalendarEventData] = _get_visible_authored_events(
		safe_day,
		safe_day
	)
	return _build_day_snapshot(safe_day, occupation, authored_events)


static func _build_current_time_snapshot() -> Dictionary:
	var current_hour: int = TimeManager.get_action_block_hour(
		TimeManager.current_period,
		TimeManager.current_action_block
	)
	var date_info: Dictionary = TimeManager.get_date_for_game_day(
		TimeManager.days_passed
	)

	return {
		"game_day": TimeManager.days_passed,
		"year": int(date_info.get("year", TimeManager.current_year)),
		"month": int(date_info.get("month", TimeManager.current_month_index + 1)),
		"calendar_day": int(date_info.get("day", TimeManager.current_calendar_day)),
		"weekday_index": int(date_info.get("weekday", TimeManager.current_weekday_index)),
		"weekday_name": TimeManager.get_current_weekday_name(),
		"period": int(TimeManager.current_period),
		"period_name": TimeManager.get_current_period_name(),
		"action_block": TimeManager.current_action_block,
		"day_block": TimeManager.get_current_day_block_index(),
		"hour": current_hour,
		"hour_label": TimeManager.format_hour_12(current_hour),
		"actions_left_in_period": TimeManager.get_actions_left_in_period(),
		"total_action_index": TimeManager.get_total_action_index(),
		"date_label": _format_date(date_info)
	}


static func _build_day_snapshot(
	game_day: int,
	occupation: OccupationData,
	authored_events: Array[CalendarEventData]
) -> Dictionary:
	var date_info: Dictionary = TimeManager.get_date_for_game_day(game_day)
	var weekday_index: int = int(date_info.get("weekday", 0))
	var events: Array[Dictionary] = []

	for event: CalendarEventData in authored_events:
		if event == null:
			continue

		var occurrence_days: PackedInt32Array = event.get_occurrence_game_days(
			game_day,
			game_day
		)

		if occurrence_days.has(game_day):
			var snapshot: Dictionary = _build_authored_event_snapshot(
				event,
				game_day
			)

			if not snapshot.is_empty():
				events.append(snapshot)

	events.append_array(_build_occupation_events(
		occupation,
		game_day,
		weekday_index
	))

	if game_day == TimeManager.days_passed:
		events.append_array(_build_active_lead_events())

	events.sort_custom(_sort_event_snapshots)
	var occupied_blocks: PackedInt32Array = _get_occupied_blocks(
		occupation,
		weekday_index
	)
	var remaining_free_blocks: int = _count_remaining_free_blocks(
		game_day,
		occupied_blocks
	)

	return {
		"game_day": game_day,
		"year": int(date_info.get("year", TimeManager.start_year)),
		"month": int(date_info.get("month", TimeManager.start_month)),
		"calendar_day": int(date_info.get("day", 1)),
		"weekday_index": weekday_index,
		"weekday_name": _weekday_name(weekday_index),
		"date_label": _format_date(date_info),
		"is_today": game_day == TimeManager.days_passed,
		"is_weekend": weekday_index in [0, 6],
		"occupied_blocks": Array(occupied_blocks),
		"remaining_free_blocks": remaining_free_blocks,
		"events": events
	}


static func _get_visible_authored_events(
	first_day: int,
	last_day: int
) -> Array[CalendarEventData]:
	var result: Array[CalendarEventData] = []
	var context: Dictionary = GameEffectContext.create(
		"calendar.projection",
		CampaignState.operator.profile.username,
		CampaignState.current_location_id,
		"",
		"calendar"
	).to_condition_context()

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CALENDAR_EVENTS
	):
		var event := resource as CalendarEventData

		if event == null \
			or not event.is_visible(context) \
			or not event.is_available(context):
			continue

		if event.get_occurrence_game_days(first_day, last_day).is_empty():
			continue

		result.append(event)

	return result


static func _build_authored_event_snapshot(
	event: CalendarEventData,
	game_day: int
) -> Dictionary:
	var action_index: int = event.get_occurrence_action_index(game_day)
	var current_index: int = TimeManager.get_total_action_index()
	var is_past: bool = action_index < current_index

	if is_past and not event.show_after_occurrence:
		return {}

	return {
		"event_id": event.get_display_id(),
		"title": event.get_display_title(),
		"description": event.description.strip_edges(),
		"kind": int(event.event_kind),
		"kind_label": event.get_kind_label(),
		"game_day": game_day,
		"day_block": event.get_day_block_index(),
		"action_index": action_index,
		"time_label": event.get_time_label(),
		"all_day": event.all_day,
		"duration_blocks": event.duration_blocks,
		"priority": event.priority,
		"source_id": event.source_id.strip_edges(),
		"location_id": event.location_id.strip_edges(),
		"is_past": is_past,
		"is_ongoing": false,
		"origin": "authored"
	}


static func _build_occupation_events(
	occupation: OccupationData,
	game_day: int,
	weekday_index: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if occupation == null or occupation.schedule == null:
		return result

	var occupied_blocks: PackedInt32Array = _get_occupied_blocks(
		occupation,
		weekday_index
	)

	if occupied_blocks.is_empty():
		return result

	var ranges: Array[Vector2i] = _contiguous_ranges(occupied_blocks)

	for range_value: Vector2i in ranges:
		var start_block: int = range_value.x
		var end_block: int = range_value.y
		var duration: int = end_block - start_block + 1
		var action_index: int = (
			(game_day - 1) * TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
			+ start_block
		)
		var start_hour: int = _hour_for_day_block(start_block)
		var end_hour: int = posmod(start_hour + duration, 24)
		result.append({
			"event_id": "occupation.%s.%d.%d" % [
				occupation.get_display_id(),
				game_day,
				start_block
			],
			"title": occupation.get_display_name(),
			"description": occupation.schedule.get_occupied_reason(),
			"kind": int(CalendarEventData.EventKind.OCCUPATION),
			"kind_label": "OCCUPATION",
			"game_day": game_day,
			"day_block": start_block,
			"action_index": action_index,
			"time_label": "%s — %s" % [
				TimeManager.format_hour_12(start_hour),
				TimeManager.format_hour_12(end_hour)
			],
			"all_day": false,
			"duration_blocks": duration,
			"priority": 100,
			"source_id": occupation.get_display_id(),
			"location_id": occupation.starting_location_id.strip_edges(),
			"is_past": action_index < TimeManager.get_total_action_index(),
			"is_ongoing": _is_range_ongoing(game_day, start_block, end_block),
			"origin": "occupation"
		})

	return result


static func _build_active_lead_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_incident_ids: Dictionary = {}

	for lead_id: String in CampaignState.active_lead_ids:
		var lead: LeadData = ContentRegistry.get_lead(lead_id)

		if lead == null:
			continue

		var progress: Dictionary = CampaignState.get_lead_progress(lead_id)
		var stage: LeadStageData = lead.get_stage(
			str(progress.get("stage_id", ""))
		)
		var location_id: String = lead.location_id.strip_edges()

		if stage != null and not stage.location_id.strip_edges().is_empty():
			location_id = stage.location_id.strip_edges()

		result.append({
			"event_id": "lead.%s" % lead.get_display_id(),
			"title": lead.title.strip_edges(),
			"description": (
				stage.description.strip_edges()
				if stage != null and not stage.description.strip_edges().is_empty()
				else lead.description.strip_edges()
			),
			"kind": int(CalendarEventData.EventKind.LEAD),
			"kind_label": "ACTIVE LEAD",
			"game_day": TimeManager.days_passed,
			"day_block": TimeManager.get_current_day_block_index(),
			"action_index": TimeManager.get_total_action_index(),
			"time_label": "ONGOING",
			"all_day": true,
			"duration_blocks": 0,
			"priority": 300,
			"source_id": lead.get_display_id(),
			"location_id": location_id,
			"is_past": false,
			"is_ongoing": true,
			"origin": "lead"
		})

		if stage == null or stage.incident_id.strip_edges().is_empty():
			continue

		var incident_id: String = stage.incident_id.strip_edges()

		if seen_incident_ids.has(incident_id) \
			or CampaignState.has_completed_incident(incident_id):
			continue

		var incident: IncidentData = ContentRegistry.get_incident(incident_id)

		if incident == null:
			continue

		seen_incident_ids[incident_id] = true
		result.append({
			"event_id": "incident.%s" % incident.get_display_id(),
			"title": incident.title.strip_edges(),
			"description": incident.description.strip_edges(),
			"kind": int(CalendarEventData.EventKind.INCIDENT),
			"kind_label": "AVAILABLE INCIDENT",
			"game_day": TimeManager.days_passed,
			"day_block": TimeManager.get_current_day_block_index(),
			"action_index": TimeManager.get_total_action_index(),
			"time_label": "AVAILABLE NOW",
			"all_day": true,
			"duration_blocks": 0,
			"priority": 350,
			"source_id": incident.get_display_id(),
			"location_id": incident.location_id.strip_edges(),
			"is_past": false,
			"is_ongoing": true,
			"origin": "incident"
		})

	return result


static func _build_occupation_snapshot(
	occupation: OccupationData
) -> Dictionary:
	if occupation == null:
		return {
			"occupation_id": "",
			"display_name": "NO OCCUPATION",
			"schedule_id": "",
			"occupied_reason": "No mandatory routine is registered."
		}

	return {
		"occupation_id": occupation.get_display_id(),
		"display_name": occupation.get_display_name(),
		"schedule_id": (
			occupation.schedule.get_display_id()
			if occupation.schedule != null
			else ""
		),
		"occupied_reason": (
			occupation.schedule.get_occupied_reason()
			if occupation.schedule != null
			else "No mandatory routine is registered."
		)
	}


static func _get_operator_occupation() -> OccupationData:
	if not CampaignState.has_campaign() or CampaignState.operator.is_empty():
		return null

	return ContentRegistry.get_occupation(
		CampaignState.operator.occupation_id
	)


static func _get_occupied_blocks(
	occupation: OccupationData,
	weekday_index: int
) -> PackedInt32Array:
	var result := PackedInt32Array()

	if occupation == null or occupation.schedule == null:
		return result

	for day_block: int in range(TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY):
		if occupation.schedule.is_block_occupied(weekday_index, day_block):
			result.append(day_block)

	return result


static func _contiguous_ranges(
	blocks: PackedInt32Array
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if blocks.is_empty():
		return result

	var sorted_blocks: PackedInt32Array = blocks.duplicate()
	sorted_blocks.sort()
	var range_start: int = sorted_blocks[0]
	var previous: int = sorted_blocks[0]

	for index: int in range(1, sorted_blocks.size()):
		var current: int = sorted_blocks[index]

		if current != previous + 1:
			result.append(Vector2i(range_start, previous))
			range_start = current

		previous = current

	result.append(Vector2i(range_start, previous))
	return result


static func _count_remaining_free_blocks(
	game_day: int,
	occupied_blocks: PackedInt32Array
) -> int:
	var first_block: int = 0

	if game_day == TimeManager.days_passed:
		first_block = TimeManager.get_current_day_block_index()
	elif game_day < TimeManager.days_passed:
		return 0

	var result: int = 0

	for day_block: int in range(
		first_block,
		TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY
	):
		if not occupied_blocks.has(day_block):
			result += 1

	return result


static func _find_next_event(
	events: Array[Dictionary]
) -> Dictionary:
	var current_index: int = TimeManager.get_total_action_index()

	for event: Dictionary in events:
		if bool(event.get("is_ongoing", false)):
			continue

		if int(event.get("action_index", -1)) >= current_index:
			return event.duplicate(true)

	return {}


static func _sort_event_snapshots(
	left: Dictionary,
	right: Dictionary
) -> bool:
	var left_index: int = int(left.get("action_index", 0))
	var right_index: int = int(right.get("action_index", 0))

	if left_index != right_index:
		return left_index < right_index

	var left_priority: int = int(left.get("priority", 0))
	var right_priority: int = int(right.get("priority", 0))

	if left_priority != right_priority:
		return left_priority > right_priority

	return str(left.get("event_id", "")) < str(right.get("event_id", ""))


static func _is_range_ongoing(
	game_day: int,
	start_block: int,
	end_block: int
) -> bool:
	if game_day != TimeManager.days_passed:
		return false

	var current_block: int = TimeManager.get_current_day_block_index()
	return current_block >= start_block and current_block <= end_block


static func _hour_for_day_block(day_block: int) -> int:
	var safe_block: int = clampi(
		day_block,
		0,
		TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY - 1
	)

	if safe_block < TimeManager.ACTION_BLOCKS_PER_PERIOD:
		return TimeManager.get_action_block_hour(
			TimeManager.TimePeriod.DAY,
			safe_block
		)

	return TimeManager.get_action_block_hour(
		TimeManager.TimePeriod.NIGHT,
		safe_block - TimeManager.ACTION_BLOCKS_PER_PERIOD
	)


static func _weekday_name(weekday_index: int) -> String:
	var safe_index: int = clampi(
		weekday_index,
		0,
		TimeManager.WEEKDAY_NAMES.size() - 1
	)
	return TimeManager.WEEKDAY_NAMES[safe_index]


static func _format_date(date_info: Dictionary) -> String:
	var month_index: int = clampi(
		int(date_info.get("month", 1)) - 1,
		0,
		TimeManager.MONTH_NAMES.size() - 1
	)
	return "%02d %s %d" % [
		int(date_info.get("day", 1)),
		TimeManager.MONTH_NAMES[month_index],
		int(date_info.get("year", TimeManager.start_year))
	]
