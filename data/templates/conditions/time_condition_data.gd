extends ConditionRuleData
class_name TimeConditionData


enum PeriodRequirement {
	ANY,
	DAY,
	NIGHT
}

@export_range(1, 999999, 1, "or_greater") var min_day: int = 1
@export_range(-1, 999999, 1, "or_greater") var max_day: int = -1
@export var required_period: PeriodRequirement = PeriodRequirement.ANY
@export_range(0, 11) var min_action_block: int = 0
@export_range(0, 11) var max_action_block: int = 11


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	if TimeManager.days_passed < min_day:
		return false

	if max_day >= 0 and TimeManager.days_passed > max_day:
		return false

	match required_period:
		PeriodRequirement.DAY:
			if TimeManager.current_period != TimeManager.TimePeriod.DAY:
				return false
		PeriodRequirement.NIGHT:
			if TimeManager.current_period != TimeManager.TimePeriod.NIGHT:
				return false

	return (
		TimeManager.current_action_block >= min_action_block
		and TimeManager.current_action_block <= max_action_block
	)


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if min_day < 1:
		errors.append("min_day must be at least 1.")

	if max_day != -1 and max_day < min_day:
		errors.append("max_day must be -1 or greater than or equal to min_day.")

	if min_action_block > max_action_block:
		errors.append("min_action_block cannot exceed max_action_block.")

	return errors
