extends Resource
class_name ConditionRuleData


func is_met(context: Dictionary = {}) -> bool:
	return _evaluate(context, {})


func validate_data() -> PackedStringArray:
	return _validate({})


func _evaluate(context: Dictionary, active_path: Dictionary) -> bool:
	var instance_id: int = get_instance_id()

	if active_path.has(instance_id):
		push_error("ConditionRuleData contains a recursive condition cycle.")
		return false

	active_path[instance_id] = true
	var result: bool = _evaluate_rule(context, active_path)
	active_path.erase(instance_id)
	return result


func _validate(active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var instance_id: int = get_instance_id()

	if active_path.has(instance_id):
		errors.append("Condition graph contains a recursive cycle.")
		return errors

	active_path[instance_id] = true
	errors.append_array(_validate_rule(active_path))
	active_path.erase(instance_id)
	return errors


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	push_error("ConditionRuleData must be specialized before evaluation.")
	return false


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	return PackedStringArray()
