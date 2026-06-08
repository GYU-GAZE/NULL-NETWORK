extends Node

enum TimePeriod {
	DAY,
	NIGHT
}

const ACTION_BLOCKS_PER_PERIOD: int = 6
const TOTAL_ACTION_BLOCKS_PER_DAY: int = ACTION_BLOCKS_PER_PERIOD * 2
const SECONDS_PER_DAY: int = 86400

@export_category("Game Start Date")
var start_year: int = 2026
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

const MONTH_NAMES: Array[String] = [
	"JAN", "FEB", "MAR", "APR", "MAY", "JUN",
	"JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
]

const FULL_MONTH_NAMES: Array[String] = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]


func _ready() -> void:
	_sync_calendar_from_days_passed()


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
		return (18 + (safe_action_block * 2)) % 24

	return 6 + (safe_action_block * 2)


func format_action_block_hour(period: int, action_block: int) -> String:
	var hour_24: int = get_action_block_hour(period, action_block)

	var suffix: String = "AM"

	if hour_24 >= 12:
		suffix = "PM"

	var hour_12: int = hour_24 % 12

	if hour_12 == 0:
		hour_12 = 12

	return "%d %s" % [hour_12, suffix]


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
