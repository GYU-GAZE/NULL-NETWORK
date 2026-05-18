extends Resource
class_name ThreadButtonData

@export var thread_ref: ForumThread
@export var conditions: Array[ConditionData] = []


func are_conditions_met() -> bool:
	for condition in conditions:
		if condition == null:
			continue

		if not condition.is_met():
			return false

	return true