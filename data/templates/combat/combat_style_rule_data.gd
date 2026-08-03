extends Resource
class_name CombatStyleRuleData


enum CombatStyle {
	NEUTRAL,
	VALIANT,
	CALCULATED,
	SYNCHRONIZED,
	RUTHLESS,
	MIXED
}

@export_range(0, 100, 1) var minimum_combat_style_score: int = 6
@export_range(0, 100, 1) var dominance_margin: int = 3
@export_range(0, 100, 1) var dominant_bonus_amount: int = 2
@export_range(0, 100, 1) var mixed_bonus_amount: int = 1
@export_range(0, 100, 1) var max_bonus_per_combat: int = 2


func resolve(log: CombatTendencyLog) -> Dictionary:
	if log == null:
		return _result(CombatStyle.NEUTRAL, [])

	var scores: Array[Dictionary] = [
		{"tendency": TendencyStateData.Tendency.VALOUR, "score": log.combat_valour},
		{"tendency": TendencyStateData.Tendency.LOGIC, "score": log.combat_logic},
		{"tendency": TendencyStateData.Tendency.SYNC, "score": log.combat_sync},
		{"tendency": TendencyStateData.Tendency.SELF, "score": log.combat_self}
	]
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["score"]) > int(b["score"])
	)
	var first: Dictionary = scores[0]
	var second: Dictionary = scores[1]

	if int(first["score"]) < minimum_combat_style_score:
		return _result(CombatStyle.NEUTRAL, [])

	if int(first["score"]) - int(second["score"]) >= dominance_margin:
		var amount: int = mini(max_bonus_per_combat, dominant_bonus_amount)
		return _result(
			_style_for_tendency(first["tendency"]),
			[{"tendency": int(first["tendency"]), "amount": amount}]
		)

	var mixed_amount: int = mini(mixed_bonus_amount, max_bonus_per_combat)
	var gains: Array[Dictionary] = []

	if mixed_amount > 0:
		gains.append({"tendency": int(first["tendency"]), "amount": mixed_amount})

	if mixed_amount * 2 <= max_bonus_per_combat and mixed_amount > 0:
		gains.append({"tendency": int(second["tendency"]), "amount": mixed_amount})

	return _result(CombatStyle.MIXED, gains)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if dominant_bonus_amount > max_bonus_per_combat:
		errors.append("Dominant Combat Style bonus exceeds the configured maximum.")

	if mixed_bonus_amount * 2 > max_bonus_per_combat:
		errors.append("Mixed Combat Style bonus exceeds the configured maximum.")

	return errors


func _style_for_tendency(tendency: TendencyStateData.Tendency) -> CombatStyle:
	match tendency:
		TendencyStateData.Tendency.VALOUR:
			return CombatStyle.VALIANT
		TendencyStateData.Tendency.LOGIC:
			return CombatStyle.CALCULATED
		TendencyStateData.Tendency.SYNC:
			return CombatStyle.SYNCHRONIZED
		TendencyStateData.Tendency.SELF:
			return CombatStyle.RUTHLESS

	return CombatStyle.NEUTRAL


func _result(style: CombatStyle, gains: Array) -> Dictionary:
	return {
		"style": int(style),
		"style_name": CombatStyle.keys()[style],
		"tendency_gains": gains
	}
