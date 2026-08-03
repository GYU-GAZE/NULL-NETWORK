extends ConditionRuleData
class_name FlagConditionData


@export var flag_name: String = ""
@export var expected_value: bool = true


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	var clean_name: String = flag_name.strip_edges()
	return (
		not clean_name.is_empty()
		and GameState.get_flag(clean_name) == expected_value
	)


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if flag_name.strip_edges().is_empty():
		errors.append("flag_name cannot be empty.")

	return errors
