extends Resource
class_name StatusEffect

@export var effect_name: String = "Buff"
@export_enum("Buff", "Debuff") var effect_type: String = "Buff"
@export_enum("ATK", "DEF", "DODGE", "STABILITY") var target_stat: String = "ATK"
@export var flat_value: int = 5
@export var duration_cycles: int = 1
