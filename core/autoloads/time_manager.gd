extends Node

enum TimePeriod {
	DAY,
	NIGHT
}

const ACTION_BLOCKS_PER_PERIOD: int = 6

@export_category("Time State")
var current_period: TimePeriod = TimePeriod.DAY
var current_action_block: int = 0

var days_passed: int = 1
var days_until_update: int = 7

@export_category("Calendar System")
var current_year: int = 2024
var current_month_index: int = 0
var current_calendar_day: int = 21

const MONTH_NAMES: Array[String] = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
const FULL_MONTH_NAMES: Array[String] = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
const DAYS_IN_MONTH: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

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

	current_calendar_day += 1

	if current_calendar_day > DAYS_IN_MONTH[current_month_index]:
		current_calendar_day = 1
		current_month_index += 1

		if current_month_index > 11:
			current_month_index = 0
			current_year += 1


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