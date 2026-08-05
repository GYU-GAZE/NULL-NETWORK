extends RefCounted
class_name APKCombatLoadoutFactory


static func create_loadout(
	apk_id: String,
	level: int = 1,
	integrity_state: PartnerStateData.IntegrityState = PartnerStateData.IntegrityState.EXE
) -> CharacterLoadout:
	var clean_id: String = apk_id.strip_edges()
	var apk: APKData = ContentRegistry.get_apk(clean_id)

	if apk == null or not apk.validate_data().is_empty():
		return null

	var state: PartnerStateData = APKProgressionService.create_partner_state(
		clean_id,
		apk.display_name,
		0,
		0
	)

	if state == null:
		return null

	state.level = clampi(level, 1, 100)
	state.current_exp = APKProgressionService.get_total_exp_for_level(
		state.level
	)
	state.allocation_points = maxi(0, state.level - 1)
	state.allocated_stats = {}
	state.integrity_state = integrity_state
	state.current_stability = PartnerStateData.MAX_STABILITY

	var stats: Dictionary = APKProgressionService.calculate_partner_stats(
		state
	)

	if stats.is_empty():
		return null

	state.current_hp = int(stats.get("max_hp", 1))
	return APKProgressionService.create_combat_snapshot(state)
