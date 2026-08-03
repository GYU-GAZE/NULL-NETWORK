extends Resource
class_name EvolutionCatalystData


enum CatalystKind {
	PROJECTED_TENDENCY_AT_LEAST,
	CYCLE_DAMAGE_AT_LEAST,
	SINGLE_HIT_DAMAGE_AT_LEAST,
	USED_SCAN_THIS_COMBAT,
	ENTERED_UNSTABILITY,
	ALLY_DEFEATED,
	ENEMY_DEFEATED,
	CRITICAL_HIT_COUNT_AT_LEAST
}

@export var catalyst_kind: CatalystKind = CatalystKind.PROJECTED_TENDENCY_AT_LEAST
@export var tendency: TendencyStateData.Tendency = TendencyStateData.Tendency.VALOUR
@export_range(0, 1000000, 1) var threshold: int = 1


func is_met(log: CombatTendencyLog) -> bool:
	if log == null:
		return false

	match catalyst_kind:
		CatalystKind.PROJECTED_TENDENCY_AT_LEAST:
			return log.get_projected_tendency(tendency) >= threshold
		CatalystKind.CYCLE_DAMAGE_AT_LEAST:
			return log.cycle_damage_dealt >= threshold
		CatalystKind.SINGLE_HIT_DAMAGE_AT_LEAST:
			return log.highest_single_hit_damage >= threshold
		CatalystKind.USED_SCAN_THIS_COMBAT:
			return log.scan_uses >= maxi(1, threshold)
		CatalystKind.ENTERED_UNSTABILITY:
			return log.stability_breaks >= maxi(1, threshold)
		CatalystKind.ALLY_DEFEATED:
			return log.allies_defeated >= maxi(1, threshold)
		CatalystKind.ENEMY_DEFEATED:
			return log.enemies_defeated >= maxi(1, threshold)
		CatalystKind.CRITICAL_HIT_COUNT_AT_LEAST:
			return log.critical_hits >= threshold

	return false


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if threshold <= 0:
		errors.append("Evolution Catalyst threshold must be positive.")

	return errors
