extends Node

enum TimePeriod { MORNING, NOON, AFTERNOON, EVENING, NIGHT }

@export_category("Time State")
var current_period: TimePeriod = TimePeriod.MORNING
var days_passed: int = 1
var days_until_update: int = 7

@export_category("Calendar System")
var current_year: int = 2024
var current_month_index: int = 0 # 0 = Janeiro, 1 = Fevereiro, etc.
var current_calendar_day: int = 21

# Arrays constantes para a lógica do calendário
const MONTH_NAMES: Array[String] = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
const FULL_MONTH_NAMES: Array[String] = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
const DAYS_IN_MONTH: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

func advance_time() -> void:
	# A escada do tempo atualizada
	match current_period:
		TimePeriod.MORNING:
			current_period = TimePeriod.NOON
		TimePeriod.NOON:
			current_period = TimePeriod.AFTERNOON
		TimePeriod.AFTERNOON:
			current_period = TimePeriod.EVENING
		TimePeriod.EVENING:
			current_period = TimePeriod.NIGHT
		TimePeriod.NIGHT:
			_advance_day() # Só vira o dia na virada da noite
			
	_emit_time_signal()

# Lida com a matemática de virar o mês e o ano
func _advance_day() -> void:
	current_period = TimePeriod.MORNING
	days_passed += 1
	days_until_update -= 1
	
	if days_until_update < 0:
		days_until_update = 0 # Trava provisória
		
	current_calendar_day += 1
	
	# Se o dia passar do limite do mês atual...
	if current_calendar_day > DAYS_IN_MONTH[current_month_index]:
		current_calendar_day = 1
		current_month_index += 1
		
		# Se passar de Dezembro, vira o ano
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
		TimePeriod.MORNING: return "MORNING"
		TimePeriod.NOON: return "NOON"
		TimePeriod.AFTERNOON: return "AFTERNOON"
		TimePeriod.EVENING: return "EVENING"
		TimePeriod.NIGHT: return "NIGHT"
	return "UNKNOWN"
