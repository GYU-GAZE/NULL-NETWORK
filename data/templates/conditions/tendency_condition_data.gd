extends ConditionRuleData
class_name TendencyConditionData


@export var tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export_range(0, 999999, 1, "or_greater") var minimum_value: int = 0
@export_range(-1, 999999, 1, "or_greater") var maximum_value: int = -1


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	var value: int = CampaignState.tendencies.get_value(tendency)
	return (
		value >= minimum_value
		and (maximum_value == -1 or value <= maximum_value)
	)


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if minimum_value < 0:
		errors.append("minimum_value cannot be negative.")

	if maximum_value != -1 and maximum_value < minimum_value:
		errors.append(
			"maximum_value must be -1 or greater than or equal to minimum_value."
		)

	return errors
