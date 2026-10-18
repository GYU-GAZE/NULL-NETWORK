@tool
extends Resource
class_name FieldBehaviorModifierData

@export var conditions: ConditionRuleData
## Index in FieldBehaviorProfileData.Behavior; -1 preserves species identity.
@export_range(-1, 11) var behavior_override: int = -1
@export_range(0.1, 4.0, 0.1) var speed_multiplier: float = 1.0

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if behavior_override < -1 or behavior_override > 11 or speed_multiplier <= 0:
		errors.append("Invalid field behavior modifier.")
	if conditions != null:
		errors.append_array(conditions.validate_data())
	return errors
