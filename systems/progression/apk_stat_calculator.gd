extends RefCounted
class_name APKStatCalculator


const MAX_STABILITY: int = 100
const LINEAGE_WEIGHT: float = 0.25
const HP_PER_ALLOCATION_POINT: int = 4

# HP uses a dedicated survivability curve instead of the generic linear stat curve.
# The curve is authored around the game's numerical targets:
# Lv. 1  -> 1.8% of the distance from the curve base to the Lv.100 profile
# Lv. 15 -> 9.1%
# Lv. 40 -> 27.3%
# Lv. 80 -> 72.7%
# Lv.100 -> 100%
#
# A curve base of 5 keeps low-level HP from collapsing to 1-2 points while the
# Lv.100 profile still remains the authoritative species/form target.
const HP_CURVE_BASE: float = 5.0
const HP_GROWTH_L1: float = 0.018
const HP_GROWTH_L15: float = 0.091
const HP_GROWTH_L40: float = 0.273
const HP_GROWTH_L80: float = 0.727
const HP_GROWTH_L100: float = 1.0


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
		"max_hp": _calculate_natural_hp(float(level_100.get("hp", 1.0)), level),
		"atk": maxi(5, roundi(5.0 + (float(level_100.get("atk", 5.0)) - 5.0) * level / 100.0)),
		"def": maxi(5, roundi(5.0 + (float(level_100.get("def", 5.0)) - 5.0) * level / 100.0)),
		"matk": maxi(5, roundi(5.0 + (float(level_100.get("matk", 5.0)) - 5.0) * level / 100.0)),
		"mdef": maxi(5, roundi(5.0 + (float(level_100.get("mdef", 5.0)) - 5.0) * level / 100.0)),
		"max_stability": MAX_STABILITY,
		"stability_recovery": _calculate_stability_recovery(apk, lineage_apk),
		"dodge": apk.dodge_chance,
		"crit": apk.crit_chance
	}
	stats["max_hp"] = int(stats["max_hp"]) + (
		partner.get_allocated_stat("hp") * HP_PER_ALLOCATION_POINT
	)
	stats["atk"] = int(stats["atk"]) + partner.get_allocated_stat("atk")
	stats["def"] = int(stats["def"]) + partner.get_allocated_stat("def")
	stats["matk"] = int(stats["matk"]) + partner.get_allocated_stat("matk")
	stats["mdef"] = int(stats["mdef"]) + partner.get_allocated_stat("mdef")
	return stats


static func _calculate_natural_hp(level_100_hp: float, level: int) -> int:
	var growth: float = _get_hp_growth_factor(level)
	return maxi(
		1,
		roundi(
			HP_CURVE_BASE
			+ (level_100_hp - HP_CURVE_BASE) * growth
		)
	)


static func _get_hp_growth_factor(level: int) -> float:
	var clamped_level: int = clampi(level, 1, 100)

	if clamped_level <= 15:
		return _interpolate_hp_growth(
			clamped_level,
			1,
			15,
			HP_GROWTH_L1,
			HP_GROWTH_L15
		)
	if clamped_level <= 40:
		return _interpolate_hp_growth(
			clamped_level,
			15,
			40,
			HP_GROWTH_L15,
			HP_GROWTH_L40
		)
	if clamped_level <= 80:
		return _interpolate_hp_growth(
			clamped_level,
			40,
			80,
			HP_GROWTH_L40,
			HP_GROWTH_L80
		)

	return _interpolate_hp_growth(
		clamped_level,
		80,
		100,
		HP_GROWTH_L80,
		HP_GROWTH_L100
	)


static func _interpolate_hp_growth(
	level: int,
	start_level: int,
	end_level: int,
	start_growth: float,
	end_growth: float
) -> float:
	var span: float = float(end_level - start_level)
	if is_zero_approx(span):
		return end_growth

	var weight: float = clampf(
		float(level - start_level) / span,
		0.0,
		1.0
	)
	return lerpf(start_growth, end_growth, weight)


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
