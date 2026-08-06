extends Resource
class_name CalendarEventData


enum EventKind {
	SYSTEM_UPDATE,
	MICRO_UPDATE,
	OCCUPATION,
	STORY,
	LEAD,
	INCIDENT,
	SOCIAL,
	HANGOUT,
	DEADLINE,
	OTHER
}

enum ScheduleMode {
	ABSOLUTE_GAME_DAY,
	WEEKLY,
	UPDATE_COUNTDOWN
}

@export_category("Identity")
@export var event_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var event_kind: EventKind = EventKind.OTHER
@export var priority: int = 0

@export_category("Schedule")
@export var schedule_mode: ScheduleMode = ScheduleMode.ABSOLUTE_GAME_DAY
## Absolute target day. UPDATE_COUNTDOWN also uses this as its stable deadline
## once TimeManager.days_until_update reaches zero, preventing the event from
## moving forward one day forever after the deadline.
@export_range(1, 9999, 1, "or_greater") var game_day: int = 1
## Sunday = 0, Monday = 1, ..., Saturday = 6.
@export var weekday_indices: PackedInt32Array = PackedInt32Array()
@export var all_day: bool = false
@export_enum("DAY", "NIGHT") var period: int = TimeManager.TimePeriod.DAY
@export_range(0, 11, 1) var action_block: int = 0
@export_range(1, 24, 1) var duration_blocks: int = 1
@export var show_after_occurrence: bool = false

@export_category("Routing")
@export var source_id: String = ""
@export var location_id: String = ""

@export_category("Knowledge and Availability")
## Controls whether the Operator knows enough for this event to appear.
@export var visibility_conditions: ConditionSetData
## Controls whether the known event is currently relevant. A known but inactive
## event remains hidden rather than revealing future branches prematurely.
@export var availability_conditions: ConditionSetData


func get_display_id() -> String:
	return event_id.strip_edges()


func get_display_title() -> String:
	var clean_title: String = title.strip_edges()
	return clean_title if not clean_title.is_empty() else get_display_id()


func is_visible(context: Dictionary = {}) -> bool:
	return visibility_conditions == null \
		or visibility_conditions.is_met(context)


func is_available(context: Dictionary = {}) -> bool:
	return availability_conditions == null \
		or availability_conditions.is_met(context)


func get_occurrence_game_days(
	from_game_day: int,
	to_game_day: int
) -> PackedInt32Array:
	var result := PackedInt32Array()
	var first_day: int = maxi(1, from_game_day)
	var last_day: int = maxi(first_day, to_game_day)

	match schedule_mode:
		ScheduleMode.ABSOLUTE_GAME_DAY:
			if game_day >= first_day and game_day <= last_day:
				result.append(game_day)

		ScheduleMode.UPDATE_COUNTDOWN:
			var update_day: int = game_day

			if TimeManager.days_until_update > 0:
				update_day = (
					TimeManager.days_passed
					+ TimeManager.days_until_update
				)

			if update_day >= first_day and update_day <= last_day:
				result.append(update_day)

		ScheduleMode.WEEKLY:
			for candidate_day: int in range(first_day, last_day + 1):
				var date_info: Dictionary = TimeManager.get_date_for_game_day(
					candidate_day
				)
				var weekday: int = int(date_info.get("weekday", -1))

				if weekday_indices.has(weekday):
					result.append(candidate_day)

	return result


func get_day_block_index() -> int:
	if all_day:
		return 0

	return (
		action_block
		+ TimeManager.ACTION_BLOCKS_PER_PERIOD
		* (1 if period == TimeManager.TimePeriod.NIGHT else 0)
	)


func get_occurrence_action_index(occurrence_game_day: int) -> int:
	if all_day:
		return TimeManager.get_action_index_for_game_time(
			occurrence_game_day,
			TimeManager.TimePeriod.DAY,
			0
		)

	return TimeManager.get_action_index_for_game_time(
		occurrence_game_day,
		period,
		action_block
	)


func get_time_label() -> String:
	if all_day:
		return "ALL DAY"

	var start_hour: int = TimeManager.get_action_block_hour(period, action_block)
	var end_hour: int = posmod(start_hour + duration_blocks, 24)

	if duration_blocks == 1:
		return TimeManager.format_hour_12(start_hour)

	return "%s — %s" % [
		TimeManager.format_hour_12(start_hour),
		TimeManager.format_hour_12(end_hour)
	]


func get_kind_label() -> String:
	return EventKind.keys()[event_kind]


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_weekdays: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("event_id cannot be empty.")

	if get_display_title().is_empty():
		errors.append("title cannot be empty.")

	match schedule_mode:
		ScheduleMode.ABSOLUTE_GAME_DAY, ScheduleMode.UPDATE_COUNTDOWN:
			if game_day < 1:
				errors.append("game_day must be at least 1.")
		ScheduleMode.WEEKLY:
			if weekday_indices.is_empty():
				errors.append("WEEKLY events require weekday_indices.")
		_:
			errors.append("schedule_mode is invalid.")

	for weekday: int in weekday_indices:
		if weekday < 0 or weekday > 6:
			errors.append("weekday index must be between 0 and 6.")
		elif seen_weekdays.has(weekday):
			errors.append("weekday index %d is duplicated." % weekday)
		else:
			seen_weekdays[weekday] = true

	if period < TimeManager.TimePeriod.DAY \
		or period > TimeManager.TimePeriod.NIGHT:
		errors.append("period is invalid.")

	if action_block < 0 or action_block >= TimeManager.ACTION_BLOCKS_PER_PERIOD:
		errors.append("action_block must be between 0 and 11.")

	if duration_blocks < 1 or duration_blocks > 24:
		errors.append("duration_blocks must be between 1 and 24.")

	if visibility_conditions != null:
		for error: String in visibility_conditions.validate_data():
			errors.append("Visibility condition: %s" % error)

	if availability_conditions != null:
		for error: String in availability_conditions.validate_data():
			errors.append("Availability condition: %s" % error)

	return errors
