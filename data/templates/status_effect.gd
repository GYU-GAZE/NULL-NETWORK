extends Resource
class_name StatusEffect

enum EffectType {
	BUFF,
	DEBUFF,
	SPECIAL
}

enum TargetStat {
	ATK,
	DEF,
	DODGE,
	STABILITY,
	CRIT,
	NONE
}

enum TriggerTiming {
	PASSIVE,
	ON_APPLIED,
	BEFORE_ACTION,
	AFTER_ACTION,
	ON_TAKE_DAMAGE,
	ON_DEAL_DAMAGE,
	START_OF_CYCLE,
	END_OF_CYCLE,
	ON_EXPIRE
}

@export var effect_name: String = "Buff"

@export_category("Effect")
@export var effect_type: EffectType = EffectType.BUFF
@export var target_stat: TargetStat = TargetStat.ATK
@export var trigger_timing: TriggerTiming = TriggerTiming.PASSIVE

@export_category("Values")
@export var flat_value: int = 5
@export var duration_cycles: int = 1

@export_category("Damage Modifiers")
@export var damage_taken_multiplier: float = 1.0
@export var damage_dealt_multiplier: float = 1.0

@export_category("Lifecycle")
@export var remove_after_trigger: bool = false