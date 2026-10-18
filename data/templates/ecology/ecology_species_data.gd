@tool
extends Resource
class_name EcologySpeciesData

@export var species_line_id: String = ""
@export_range(0, 100000) var population_base: int = 5
@export_range(1, 100000) var population_capacity: int = 5
@export_range(0.0, 100.0) var frequency: float = 1.0
@export_range(0, 100000) var weekly_recovery: int = 2
@export_range(0, 3) var weekly_resonance_decay: int = 1
@export var recompile_on_micro_update: bool = true
@export var conditions: ConditionRuleData
@export var variants: Array[EcologyVariantData] = []
@export var pressure_rules: Array[EcologyPressureRuleData] = []

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if species_line_id.is_empty() or population_base < 0 or population_base > population_capacity or population_capacity < 1:
		errors.append("Ecology species requires a stable line and base within capacity.")
	if conditions != null: errors.append_array(conditions.validate_data())
	for variant: EcologyVariantData in variants:
		if variant == null: errors.append("Null ecological Variant.")
		else:
			errors.append_array(variant.validate_data())
			if species_line_id not in variant.species_line_ids: errors.append("Variant pool contains an incompatible species.")
	for rule: EcologyPressureRuleData in pressure_rules:
		if rule == null: errors.append("Null pressure rule.")
		else:
			if rule.conditions != null: errors.append_array(rule.conditions.validate_data())
			for variant: EcologyVariantData in rule.variant_additions:
				if variant == null: errors.append("Null pressure Variant.")
				else:
					errors.append_array(variant.validate_data())
					if species_line_id not in variant.species_line_ids: errors.append("Pressure Variant incompatible with species.")
	return errors
