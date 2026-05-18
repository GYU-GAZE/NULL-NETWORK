extends Resource
class_name ConditionData

enum PeriodRequirement {
	ANY,
	DAY,
	NIGHT
}

@export_category("Flags")
@export var required_true_flags: Array[String] = []
@export var required_false_flags: Array[String] = []

@export_category("Time")
@export var min_day: int = 0
@export var max_day: int = -1

@export var required_period: PeriodRequirement = PeriodRequirement.ANY
@export_range(0, 5) var min_action_block: int = 0
@export_range(0, 5) var max_action_block: int = 5


func is_met() -> bool:
	for flag in required_true_flags:
		if not GameState.get_flag(flag):
			return false

	for flag in required_false_flags:
		if GameState.get_flag(flag):
			return false

	if TimeManager.days_passed < min_day:
		return false

	if max_day != -1 and TimeManager.days_passed > max_day:
		return false

	if not _is_period_met():
		return false

	if TimeManager.current_action_block < min_action_block:
		return false

	if TimeManager.current_action_block > max_action_block:
		return false

	return true


func _is_period_met() -> bool:
	match required_period:
		PeriodRequirement.ANY:
			return true

		PeriodRequirement.DAY:
			return TimeManager.current_period == TimeManager.TimePeriod.DAY

		PeriodRequirement.NIGHT:
			return TimeManager.current_period == TimeManager.TimePeriod.NIGHT

	return false