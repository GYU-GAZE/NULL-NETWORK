@tool
extends ConditionRuleData
class_name ConditionSetData


enum MatchMode {
	ALL,
	ANY,
	NONE
}

@export var match_mode: MatchMode = MatchMode.ALL
@export var rules: Array[ConditionRuleData] = []


func _evaluate_rule(
	context: Dictionary,
	active_path: Dictionary
) -> bool:
	for rule: ConditionRuleData in rules:
		if rule == null:
			push_error("ConditionSetData contains a null rule.")
			return false

	match match_mode:
		MatchMode.ALL:
			for rule: ConditionRuleData in rules:
				if not rule._evaluate(context, active_path):
					return false
			return true

		MatchMode.ANY:
			for rule: ConditionRuleData in rules:
				if rule._evaluate(context, active_path):
					return true
			return false

		MatchMode.NONE:
			for rule: ConditionRuleData in rules:
				if rule._evaluate(context, active_path):
					return false
			return true

	return false


func _validate_rule(active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	for index: int in range(rules.size()):
		var rule: ConditionRuleData = rules[index]

		if rule == null:
			errors.append("Condition rule %d is null." % index)
			continue

		var rule_errors: PackedStringArray = rule._validate(active_path)

		for error: String in rule_errors:
			errors.append("Rule %d: %s" % [index, error])

	return errors


func get_change_dependencies(active_path: Dictionary = {}) -> Dictionary:
	if active_path.has(get_instance_id()):
		return {}
	active_path[get_instance_id()] = true
	var result := {}
	for rule: ConditionRuleData in rules:
		if rule == null:
			continue
		var dependencies := rule.get_change_dependencies(active_path)
		for key: String in dependencies:
			if key == "time":
				result[key] = true
			else:
				if not result.has(key):
					result[key] = PackedStringArray()
				for value: String in dependencies[key]:
					if value not in result[key]:
						result[key].append(value)
	active_path.erase(get_instance_id())
	return result
