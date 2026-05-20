extends Resource
class_name StatusEffect

enum EffectType {
	BUFF,
	DEBUFF
}

enum TargetStat {
	ATK,
	DEF,
	DODGE,
	STABILITY
}

@export var effect_name: String = "Buff"

@export_category("Effect")
@export var effect_type: EffectType = EffectType.BUFF
@export var target_stat: TargetStat = TargetStat.ATK

@export_category("Values")
@export var flat_value: int = 5
@export var duration_cycles: int = 1