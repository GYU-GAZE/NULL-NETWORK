extends ConditionRuleData
class_name NumberConditionData

@export var number_name: String = ""
@export var minimum_value: int = 0
@export var maximum_value: int = -1


func _evaluate_rule(_context: Dictionary, _active_path: Dictionary) -> bool:
	var value: int = GameState.get_number(number_name)
	return value >= minimum_value and (maximum_value == -1 or value <= maximum_value)


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	return PackedStringArray(["number_name cannot be empty."]) if number_name.strip_edges().is_empty() else PackedStringArray()


func get_change_dependencies(_active_path: Dictionary = {}) -> Dictionary:
	return {"numbers": PackedStringArray([number_name])}
