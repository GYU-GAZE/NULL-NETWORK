extends RefCounted
class_name CombatConstants


enum Stat {
	HP,
	MAX_HP,
	STABILITY,
	MAX_STABILITY,
	STABILITY_RECOVERY,
	ATK,
	DEF,
	MATK,
	MDEF,
	DODGE,
	CRIT
}


enum ModuleTag {
	DAMAGE = 1,
	HEAL = 2,
	STATUS = 4,
	DUMMY = 8,
	DEFENSE = 16,
	UTILITY = 32
}


enum TriggerTiming {
	CONTINUOUS,
	ENCOUNTER_START,
	CYCLE_START,
	BEFORE_ACTION,
	AFTER_ACTION,
	CYCLE_END,
	MODULE_USED,
	DAMAGE_DEALT,
	DAMAGE_RECEIVED,
	STATUS_APPLIED,
	STATUS_EXPIRED,
	DUMMY_CREATED,
	DUMMY_DESTROYED,
	DUMMY_EXPIRED
}


enum TriggerActor {
	HOLDER,
	HOLDER_ALLY,
	HOLDER_ENEMY,
	ANY
}


static func stat_key(stat: Stat) -> StringName:
	match stat:
		Stat.HP:
			return &"hp"
		Stat.MAX_HP:
			return &"max_hp"
		Stat.STABILITY:
			return &"stability"
		Stat.MAX_STABILITY:
			return &"max_stability"
		Stat.STABILITY_RECOVERY:
			return &"stability_recovery"
		Stat.ATK:
			return &"atk"
		Stat.DEF:
			return &"def"
		Stat.MATK:
			return &"matk"
		Stat.MDEF:
			return &"mdef"
		Stat.DODGE:
			return &"dodge"
		Stat.CRIT:
			return &"crit"

	return &""


static func stat_label(stat: Stat) -> String:
	return String(stat_key(stat)).to_upper()
