extends Resource
class_name CombatDamageFormulaData


@export_category("Core")
@export_range(1, 999, 1) var power: int = 40
@export var offense_stat: CombatConstants.Stat = CombatConstants.Stat.ATK
@export var defense_stat: CombatConstants.Stat = CombatConstants.Stat.DEF
@export var use_effective_offense: bool = true
@export var use_effective_defense: bool = true

@export_category("Final Modifiers")
@export_range(0.0, 1.0, 0.01) var multi_target_multiplier: float = 0.75
@export_range(0.0, 10.0, 0.05) var special_multiplier: float = 1.0


func calculate_base_damage(
	level: int,
	offense: float,
	defense: float
) -> int:
	var safe_level: int = clampi(level, 1, 100)
	var safe_offense: float = maxf(0.0, offense)
	var safe_defense: float = maxf(1.0, defense)
	var level_term: int = floori(2.0 * safe_level / 5.0) + 2
	var numerator: int = floori(
		float(level_term)
		* float(power)
		* safe_offense
		/ safe_defense
	)
	return maxi(
		1,
		floori(float(numerator) / 50.0) + 2
	)


func get_target_multiplier(resolved_target_count: int) -> float:
	if resolved_target_count <= 1:
		return 1.0
	return multi_target_multiplier


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if power <= 0:
		errors.append("CombatDamageFormulaData requires Power greater than zero.")
	if multi_target_multiplier < 0.0:
		errors.append("CombatDamageFormulaData multi-target multiplier cannot be negative.")
	if special_multiplier < 0.0:
		errors.append("CombatDamageFormulaData special multiplier cannot be negative.")
	return errors


func describe() -> String:
	return "Power %d (%s vs %s)" % [
		power,
		CombatConstants.stat_label(offense_stat),
		CombatConstants.stat_label(defense_stat)
	]
