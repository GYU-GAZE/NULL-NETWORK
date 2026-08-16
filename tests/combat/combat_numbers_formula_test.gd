extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_power_formula()
	_test_module_authoring()
	_test_runtime_damage_integration()
	_test_configurable_heal_scaling()
	_test_hp_allocation_value()
	_finish_test()


func _test_power_formula() -> void:
	var formula := CombatDamageFormulaData.new()
	formula.power = 45

	_check(
		formula.calculate_base_damage(1, 6.0, 5.0) == 4,
		"Power 45 level-1 damage must be 4 for 6 ATK vs 5 DEF."
	)
	_check(
		formula.calculate_base_damage(3, 7.0, 6.0) == 5,
		"Power 45 level-3 damage must be 5 for 7 ATK vs 6 DEF."
	)
	_check(
		formula.calculate_base_damage(15, 15.0, 12.0) == 11,
		"Power 45 level-15 damage must be 11 for 15 ATK vs 12 DEF."
	)
	_check(
		formula.calculate_base_damage(40, 31.0, 23.0) == 23,
		"Power 45 level-40 damage must be 23 for 31 ATK vs 23 DEF."
	)
	_check(
		formula.calculate_base_damage(100, 70.0, 50.0) == 54,
		"Power 45 level-100 damage must be 54 for 70 ATK vs 50 DEF."
	)
	_check(
		is_equal_approx(formula.get_target_multiplier(1), 1.0)
		and is_equal_approx(formula.get_target_multiplier(2), 0.75),
		"Power damage must use 1.00 single-target and 0.75 multi-target modifiers by default."
	)


func _test_module_authoring() -> void:
	var basic: ModuleData = load(
		"res://data/content/combat/modules/basic_attack.tres"
	) as ModuleData
	var heavy: ModuleData = load(
		"res://data/content/combat/modules/heavy_attack.tres"
	) as ModuleData
	var heal: ModuleData = load(
		"res://data/content/combat/modules/basic_heal.tres"
	) as ModuleData

	_check(basic != null and not basic.combat_effects.is_empty(), "Basic Attack did not load.")
	_check(heavy != null and not heavy.combat_effects.is_empty(), "Break did not load.")
	_check(heal != null and not heal.combat_effects.is_empty(), "Basic Heal did not load.")
	if basic == null or heavy == null or heal == null:
		return

	var basic_effect: CombatEffectData = basic.combat_effects[0]
	var heavy_effect: CombatEffectData = heavy.combat_effects[0]
	var heal_effect: CombatEffectData = heal.combat_effects[0]

	_check(
		basic.stability_cost == 10
		and basic_effect.damage_formula != null
		and basic_effect.damage_formula.power == 45
		and basic_effect.damage_formula.offense_stat == CombatConstants.Stat.ATK
		and basic_effect.damage_formula.defense_stat == CombatConstants.Stat.DEF
		and is_equal_approx(basic_effect.crit_multiplier, 1.5),
		"Basic Attack is not authored as Power 45 ATK vs DEF with the standard 1.5x crit."
	)
	_check(
		heavy.stability_cost == 35
		and heavy_effect.damage_formula != null
		and heavy_effect.damage_formula.power == 100,
		"Break is not authored as the Power 100 / 35 STB heavy attack."
	)
	_check(
		heal_effect.value_formula != null
		and heal_effect.value_formula.stat_reference == CombatValueFormula.ReferenceActor.TARGET
		and heal_effect.value_formula.stat == CombatConstants.Stat.MAX_HP
		and is_equal_approx(heal_effect.value_formula.stat_multiplier, 0.15)
		and heal_effect.value_formula.secondary_stat_reference == CombatValueFormula.ReferenceActor.CASTER
		and heal_effect.value_formula.secondary_stat == CombatConstants.Stat.MATK
		and is_equal_approx(heal_effect.value_formula.secondary_stat_multiplier, 0.10)
		and heal_effect.value_formula.use_minimum
		and is_equal_approx(heal_effect.value_formula.minimum_value, 2.0),
		"Basic Heal is not authored as 15% target Max HP + 10% configurable caster stat."
	)
	_check(
		basic.validate_data().is_empty()
		and heavy.validate_data().is_empty()
		and heal.validate_data().is_empty(),
		"Migrated Modules failed data validation."
	)


func _test_runtime_damage_integration() -> void:
	var formula := CombatDamageFormulaData.new()
	formula.power = 45
	var effect := CombatEffectData.new()
	effect.damage_formula = formula
	var caster := {
		"level": 3,
		"atk": 7.0,
		"def": 6.0,
		"matk": 7.0,
		"mdef": 6.0,
		"active_statuses": [],
		"runtime_effects": []
	}
	var target := {
		"level": 3,
		"atk": 7.0,
		"def": 6.0,
		"matk": 7.0,
		"mdef": 6.0,
		"active_statuses": [],
		"runtime_effects": []
	}

	_check(
		CombatManager._calculate_damage(caster, target, effect, 0.0, 1) == 5,
		"CombatManager did not route standard damage through the Power formula."
	)
	_check(
		CombatManager._calculate_damage(caster, target, effect, 0.0, 2) == 4,
		"CombatManager did not apply the 0.75 multi-target damage modifier."
	)


func _test_configurable_heal_scaling() -> void:
	var formula := CombatValueFormula.new()
	formula.stat_reference = CombatValueFormula.ReferenceActor.TARGET
	formula.stat = CombatConstants.Stat.MAX_HP
	formula.stat_multiplier = 0.15
	formula.use_effective_stat = true
	formula.secondary_stat_reference = CombatValueFormula.ReferenceActor.CASTER
	formula.secondary_stat = CombatConstants.Stat.MATK
	formula.secondary_stat_multiplier = 0.10
	formula.secondary_use_effective_stat = true
	formula.use_minimum = true
	formula.minimum_value = 2.0

	var caster := {
		"matk": 7.0,
		"def": 20.0,
		"active_statuses": [],
		"runtime_effects": []
	}
	var target := {
		"max_hp": 13.0,
		"active_statuses": [],
		"runtime_effects": []
	}

	var matk_heal: float = CombatManager._evaluate_formula(
		formula,
		caster,
		target,
		caster,
		null,
		null
	)
	formula.secondary_stat = CombatConstants.Stat.DEF
	var defense_heal: float = CombatManager._evaluate_formula(
		formula,
		caster,
		target,
		caster,
		null,
		null
	)

	_check(
		int(matk_heal) == 3
		and int(defense_heal) == 4,
		"Heal secondary scaling is not configurable per formula Resource."
	)


func _test_hp_allocation_value() -> void:
	var apk: APKData = load(
		"res://data/content/apks/starters/novire_init.tres"
	) as APKData
	var partner := PartnerStateData.new()
	partner.apk_id = "novire_init"
	partner.level = 3
	partner.allocated_stats = {"hp": 1}
	var stats: Dictionary = APKStatCalculator.calculate_stats(apk, partner)
	_check(
		int(stats.get("max_hp", 0)) == 16,
		"One HP Allocation Point must add 4 HP to REVQUIRE's natural 12 HP at level 3."
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	if _failures.is_empty():
		print("COMBAT_NUMBERS_FORMULA_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	print("COMBAT_NUMBERS_FORMULA_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
