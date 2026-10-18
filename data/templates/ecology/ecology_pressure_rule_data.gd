@tool
extends Resource
class_name EcologyPressureRuleData

@export var rule_id: String = ""
@export var conditions: ConditionRuleData
@export var periods: PackedInt32Array = PackedInt32Array()
@export var minimum_infestation: int = -1
@export var minimum_danger: int = -1
@export var population_base_bonus: int = 0
@export var weekly_recovery_bonus: int = 0
@export_range(0.0, 10.0) var frequency_multiplier: float = 1.0
@export var variant_additions: Array[EcologyVariantData] = []

func matches(context: Dictionary) -> bool:
	return (conditions == null or conditions.is_met(context)) and (periods.is_empty() or int(context.get("current_period", -1)) in periods) and (minimum_infestation < 0 or int(context.get("infestation", -1)) >= minimum_infestation) and (minimum_danger < 0 or int(context.get("danger", -1)) >= minimum_danger)
