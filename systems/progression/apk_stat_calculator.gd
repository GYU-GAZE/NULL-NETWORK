extends RefCounted
class_name APKStatCalculator


const MAX_STABILITY: int = 100
const LINEAGE_WEIGHT: float = 0.25


static func calculate_stats(
	apk: APKData,
	partner: PartnerStateData,
	lineage_apk: APKData = null
) -> Dictionary:
	if apk == null or partner == null or apk.level_100_stats == null:
		return {}

	var level_100: Dictionary = _calculate_level_100_profile(apk, lineage_apk)
	var level: int = clampi(partner.level, 1, 100)
	var stats := {
		"max_hp": maxi(1, roundi(float(level_100.get("hp", 1.0)) * level / 100.0)),
		"atk": maxi(5, roundi(5.0 + (float(level_100.get("atk", 5.0)) - 5.0) * level / 100.0)),
		"def": maxi(5, roundi(5.0 + (float(level_100.get("def", 5.0)) - 5.0) * level / 100.0)),
		"matk": maxi(5, roundi(5.0 + (float(level_100.get("matk", 5.0)) - 5.0) * level / 100.0)),
		"mdef": maxi(5, roundi(5.0 + (float(level_100.get("mdef", 5.0)) - 5.0) * level / 100.0)),
		"max_stability": MAX_STABILITY,
		"stability_recovery": _calculate_stability_recovery(apk, lineage_apk),
		"dodge": apk.dodge_chance,
		"crit": apk.crit_chance
	}
	stats["max_hp"] = int(stats["max_hp"]) + partner.get_allocated_stat("hp") * 2
	stats["atk"] = int(stats["atk"]) + partner.get_allocated_stat("atk")
	stats["def"] = int(stats["def"]) + partner.get_allocated_stat("def")
	stats["matk"] = int(stats["matk"]) + partner.get_allocated_stat("matk")
	stats["mdef"] = int(stats["mdef"]) + partner.get_allocated_stat("mdef")
	return stats


static func _calculate_level_100_profile(apk: APKData, lineage_apk: APKData) -> Dictionary:
	var current: APKGrowthProfileData = apk.level_100_stats

	if not apk.is_final_form() or lineage_apk == null or lineage_apk.level_100_stats == null:
		return {
			"hp": current.hp,
			"atk": current.atk,
			"def": current.def,
			"matk": current.matk,
			"mdef": current.mdef
		}

	var current_weights: Dictionary = current.get_weighted_values()
	var lineage_weights: Dictionary = lineage_apk.level_100_stats.get_weighted_values()
	var current_budget: float = current.get_weighted_budget()
	var lineage_budget: float = lineage_apk.level_100_stats.get_weighted_budget()
	var blended: Dictionary = {}

	for stat_id: String in ["hp", "atk", "def", "matk", "mdef"]:
		var current_share: float = float(current_weights[stat_id]) / current_budget
		var lineage_share: float = float(lineage_weights[stat_id]) / lineage_budget
		blended[stat_id] = current_budget * (
			current_share * (1.0 - LINEAGE_WEIGHT)
			+ lineage_share * LINEAGE_WEIGHT
		)

	blended["hp"] = float(blended["hp"]) * 2.0
	return blended


static func _calculate_stability_recovery(apk: APKData, lineage_apk: APKData) -> int:
	if not apk.is_final_form() or lineage_apk == null:
		return apk.stability_recovery

	return clampi(roundi(
		apk.stability_recovery * (1.0 - LINEAGE_WEIGHT)
		+ lineage_apk.stability_recovery * LINEAGE_WEIGHT
	), 0, MAX_STABILITY)
