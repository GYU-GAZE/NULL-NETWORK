@tool
extends Resource
class_name FieldBehaviorProfileData

enum Behavior { PASSIVE, AGGRESSIVE, TERRITORIAL, CAUTIOUS, COWARDLY, CURIOUS, PACK, SOLITARY, PROTECTIVE, OPPORTUNIST, SWARM, DORMANT }
@export var profile_id: String = ""
@export var behavior: Behavior = Behavior.PASSIVE
@export var active_conditions: ConditionRuleData
@export var aggro_conditions: ConditionRuleData
@export var modifiers: Array[FieldBehaviorModifierData] = []
@export var response_rules: Array[FieldCallResponseRule] = []
@export_range(0.0, 300.0) var speed: float = 48.0
@export_range(1.0, 2000.0) var acceleration: float = 240.0
@export_range(0.0, 1000.0) var perception_radius: float = 140.0
@export_range(8.0, 1000.0) var roaming_radius: float = 80.0
@export_range(8.0, 1000.0) var territory_radius: float = 120.0
@export_range(16.0, 2000.0) var maximum_pursuit: float = 280.0
@export_range(8.0, 300.0) var following_distance: float = 54.0
@export_range(0.0, 10.0) var minimum_pause: float = 0.6
@export_range(0.0, 10.0) var maximum_pause: float = 1.8
@export var patrol_offsets: PackedVector2Array = PackedVector2Array()
@export_range(0.05, 2.0) var perception_interval: float = 0.2
@export_range(0.0, 1.0) var opportunist_hp_threshold: float = 0.4
@export_range(0.0, 1.0) var response_probability: float = 1.0
@export_range(0.0, 30.0) var escape_grace_seconds: float = 5.0
@export_range(20.0, 500.0) var reengage_distance: float = 80.0

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id.is_empty() or speed < 0 or acceleration <= 0 or maximum_pause < minimum_pause or perception_interval <= 0:
		errors.append("Invalid field behavior identity/motion parameters.")
	for condition: ConditionRuleData in [active_conditions, aggro_conditions]:
		if condition != null:
			errors.append_array(condition.validate_data())
	for modifier: FieldBehaviorModifierData in modifiers:
		if modifier == null:
			errors.append("Null field behavior modifier.")
		else:
			errors.append_array(modifier.validate_data())
	for rule: FieldCallResponseRule in response_rules:
		if rule == null:
			errors.append("Null Combat Call response rule.")
		else:
			errors.append_array(rule.validate_data())
	return errors
