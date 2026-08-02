extends Node

enum TimePeriod {
	DAY,
	NIGHT
}

const ACTION_BLOCKS_PER_PERIOD: int = 12
const TOTAL_ACTION_BLOCKS_PER_DAY: int = ACTION_BLOCKS_PER_PERIOD * 2
const SECONDS_PER_DAY: int = 86400
const SAVE_DATA_VERSION: int = 1

@export_category("Game Start Date")
@export var start_year: int = 2026
@export_range(1, 12) var start_month: int = 1
@export_range(1, 31) var start_calendar_day: int = 1

@export_category("Time State")
var current_period: TimePeriod = TimePeriod.DAY
var current_action_block: int = 0

var days_passed: int = 1
var days_until_update: int = 7

@export_category("Calendar System")
var current_year: int = 2026
var current_month_index: int = 0
var current_calendar_day: int = 1
var current_weekday_index: int = 0

const MONTH_NAMES: Array[String] = [
	"JAN", "FEB", "MAR", "APR", "MAY", "JUN",
	"JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
]

const FULL_MONTH_NAMES: Array[String] = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

const WEEKDAY_NAMES: Array[String] = [
	"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"
]


func _ready() -> void:
	_sync_calendar_from_days_passed()


func get_save_section_id() -> String:
	return str(SaveConstants.SECTION_TIME)


func export_save_data() -> Dictionary:
	return {
		"version": SAVE_DATA_VERSION,
		"days_passed": days_passed,
		"days_until_update": days_until_update,
		"current_period": int(current_period),
		"current_action_block": current_action_block
	}


func import_save_data(data: Dictionary) -> void:
	var errors: PackedStringArray = validate_save_data(data)

	if not errors.is_empty():
		for error: String in errors:
			push_error("TimeManager import: %s" % error)
		return

	days_passed = maxi(1, int(data.get("days_passed", 1)))
	days_until_update = maxi(0, int(data.get("days_until_update", 7)))
	current_period = int(data.get("current_period", TimePeriod.DAY))
	current_action_block = clampi(
		int(data.get("current_action_block", 0)),
		0,
		ACTION_BLOCKS_PER_PERIOD - 1
	)
	_sync_calendar_from_days_passed()
	_emit_time_signal()


func reset_save_data() -> void:
	days_passed = 1
	days_until_update = 7
	current_period = TimePeriod.DAY
	current_action_block = 0
	_sync_calendar_from_days_passed()
	_emit_time_signal()


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if int(data.get("version", -1)) != SAVE_DATA_VERSION:
		errors.append("Unsupported TimeManager save version.")

	if int(data.get("days_passed", 0)) < 1:
		errors.append("days_passed must be at least 1.")

	var restored_period: int = int(data.get("current_period", -1))

	if restored_period < TimePeriod.DAY or restored_period > TimePeriod.NIGHT:
		errors.append("current_period is invalid.")

	var restored_block: int = int(data.get("current_action_block", -1))

	if restored_block < 0 or restored_block >= ACTION_BLOCKS_PER_PERIOD:
		errors.append("current_action_block must be between 0 and 11.")

	return errors


func advance_action(amount: int = 1) -> void:
	if amount <= 0:
		return

	current_action_block += amount

	while current_action_block >= ACTION_BLOCKS_PER_PERIOD:
		current_action_block -= ACTION_BLOCKS_PER_PERIOD

		if current_period == TimePeriod.DAY:
			current_period = TimePeriod.NIGHT
		else:
			_advance_day()

	_emit_time_signal()


func _advance_day() -> void:
	current_period = TimePeriod.DAY
	days_passed += 1
	days_until_update -= 1

	if days_until_update < 0:
		days_until_update = 0

	_sync_calendar_from_days_passed()


func _sync_calendar_from_days_passed() -> void:
	var date_info: Dictionary = get_date_for_game_day(days_passed)

	current_year = int(date_info.get("year", start_year))
	current_month_index = int(date_info.get("month", start_month)) - 1
	current_calendar_day = int(date_info.get("day", start_calendar_day))
	current_weekday_index = int(date_info.get("weekday", 0))


func _emit_time_signal() -> void:
	var month_short: String = MONTH_NAMES[current_month_index]

	GlobalSignals.time_advanced.emit(
		current_period as int,
		days_passed,
		current_calendar_day,
		month_short
	)


func get_period_name(period: TimePeriod) -> String:
	match period:
		TimePeriod.DAY:
			return "DAY"
		TimePeriod.NIGHT:
			return "NIGHT"

	return "UNKNOWN"


func get_current_period_name() -> String:
	return get_period_name(current_period)


func get_current_weekday_name() -> String:
	var safe_index: int = clampi(current_weekday_index, 0, WEEKDAY_NAMES.size() - 1)
	return WEEKDAY_NAMES[safe_index]


func is_weekend() -> bool:
	return current_weekday_index == 0 or current_weekday_index == 6


func get_actions_left_in_period() -> int:
	return ACTION_BLOCKS_PER_PERIOD - current_action_block


func is_day() -> bool:
	return current_period == TimePeriod.DAY


func is_night() -> bool:
	return current_period == TimePeriod.NIGHT


func get_total_action_index() -> int:
	return get_action_index_for_game_time(
		days_passed,
		current_period,
		current_action_block
	)


func get_current_day_block_index() -> int:
	var period_offset: int = 0

	if current_period == TimePeriod.NIGHT:
		period_offset = ACTION_BLOCKS_PER_PERIOD

	return period_offset + current_action_block


func get_action_index_for_game_time(game_day: int, period: int, action_block: int) -> int:
	var period_offset: int = 0

	if period == TimePeriod.NIGHT:
		period_offset = ACTION_BLOCKS_PER_PERIOD

	var safe_action_block: int = clampi(action_block, 0, ACTION_BLOCKS_PER_PERIOD - 1)

	return ((game_day - 1) * TOTAL_ACTION_BLOCKS_PER_DAY) + period_offset + safe_action_block


func get_date_for_game_day(game_day: int) -> Dictionary:
	var start_unix_time: int = int(Time.get_unix_time_from_datetime_dict({
		"year": start_year,
		"month": start_month,
		"day": start_calendar_day,
		"hour": 0,
		"minute": 0,
		"second": 0
	}))

	var day_offset: int = game_day - 1
	var target_unix_time: int = start_unix_time + (day_offset * SECONDS_PER_DAY)

	return Time.get_datetime_dict_from_unix_time(target_unix_time)


func get_action_block_hour(period: int, action_block: int) -> int:
	var safe_action_block: int = clampi(action_block, 0, ACTION_BLOCKS_PER_PERIOD - 1)

	if period == TimePeriod.NIGHT:
		return (18 + safe_action_block) % 24

	return 6 + safe_action_block


func get_day_block_index_for_hour(hour: int) -> int:
	var safe_hour: int = posmod(hour, 24)

	if safe_hour >= 6 and safe_hour <= 17:
		return safe_hour - 6

	if safe_hour >= 18 and safe_hour <= 23:
		return ACTION_BLOCKS_PER_PERIOD + (safe_hour - 18)

	return ACTION_BLOCKS_PER_PERIOD + 6 + safe_hour


func is_hour_in_day_period(hour: int) -> bool:
	var safe_hour: int = posmod(hour, 24)
	return safe_hour >= 6 and safe_hour <= 17


func format_hour_12(hour_24: int) -> String:
	var safe_hour: int = posmod(hour_24, 24)
	var suffix: String = "AM"

	if safe_hour >= 12:
		suffix = "PM"

	var hour_12: int = safe_hour % 12

	if hour_12 == 0:
		hour_12 = 12

	return "%d %s" % [hour_12, suffix]


func format_action_block_hour(period: int, action_block: int) -> String:
	return format_hour_12(get_action_block_hour(period, action_block))


func format_forum_timestamp(game_day: int, period: int, action_block: int) -> String:
	var time_text: String = format_action_block_hour(period, action_block)
	var day_difference: int = days_passed - game_day

	if day_difference == 0:
		return "Today, %s" % time_text

	if day_difference == 1:
		return "Yesterday, %s" % time_text

	var date_info: Dictionary = get_date_for_game_day(game_day)
	var day: int = int(date_info.get("day", 1))
	var month: int = int(date_info.get("month", 1))
	var year: int = int(date_info.get("year", start_year))
	var month_label: String = MONTH_NAMES[month - 1]

	return "%02d %s %d, %s" % [
		day,
		month_label,
		year,
		time_text
	]
