extends Resource
class_name CombatTendencyLog


var combat_valour: int = 0
var combat_logic: int = 0
var combat_sync: int = 0
var combat_self: int = 0

var cycle_damage_dealt: int = 0
var highest_cycle_damage: int = 0
var highest_single_hit_damage: int = 0
var total_damage_dealt: int = 0
var cycles_elapsed: int = 0
var scan_uses: int = 0
var support_uses: int = 0
var offensive_uses: int = 0
var corrupted_uses: int = 0
var critical_hits: int = 0
var allies_saved: int = 0
var allies_defeated: int = 0
var enemies_defeated: int = 0
var stability_breaks: int = 0
var run_attempts: int = 0


func reset() -> void:
	combat_valour = 0
	combat_logic = 0
	combat_sync = 0
	combat_self = 0
	cycle_damage_dealt = 0
	highest_cycle_damage = 0
	highest_single_hit_damage = 0
	total_damage_dealt = 0
	cycles_elapsed = 0
	scan_uses = 0
	support_uses = 0
	offensive_uses = 0
	corrupted_uses = 0
	critical_hits = 0
	allies_saved = 0
	allies_defeated = 0
	enemies_defeated = 0
	stability_breaks = 0
	run_attempts = 0


func begin_cycle() -> void:
	cycle_damage_dealt = 0


func finish_cycle() -> void:
	highest_cycle_damage = maxi(highest_cycle_damage, cycle_damage_dealt)
	cycles_elapsed += 1


func add_tendency(tendency: TendencyStateData.Tendency, amount: int) -> void:
	match tendency:
		TendencyStateData.Tendency.VALOUR:
			combat_valour = maxi(0, combat_valour + amount)
		TendencyStateData.Tendency.LOGIC:
			combat_logic = maxi(0, combat_logic + amount)
		TendencyStateData.Tendency.SYNC:
			combat_sync = maxi(0, combat_sync + amount)
		TendencyStateData.Tendency.SELF:
			combat_self = maxi(0, combat_self + amount)


func get_tendency(tendency: TendencyStateData.Tendency) -> int:
	match tendency:
		TendencyStateData.Tendency.VALOUR:
			return combat_valour
		TendencyStateData.Tendency.LOGIC:
			return combat_logic
		TendencyStateData.Tendency.SYNC:
			return combat_sync
		TendencyStateData.Tendency.SELF:
			return combat_self

	return 0


func get_projected_tendency(tendency: TendencyStateData.Tendency) -> int:
	return CampaignState.tendencies.get_value(tendency) + get_tendency(tendency)


func record_module(module: ModuleData) -> void:
	if module == null:
		return

	if module.module_tags & 1:
		offensive_uses += 1

	if module.module_tags & (2 | 4 | 16):
		support_uses += 1

	if module.is_corrupted:
		corrupted_uses += 1

	for gain: CombatTendencyGainData in module.combat_tendency_gains:
		if gain != null and gain.is_available():
			add_tendency(gain.tendency, gain.amount)


func record_damage(amount: int, critical: bool) -> void:
	var safe_amount: int = maxi(0, amount)
	cycle_damage_dealt += safe_amount
	total_damage_dealt += safe_amount
	highest_single_hit_damage = maxi(highest_single_hit_damage, safe_amount)

	if critical:
		critical_hits += 1


func record_player_action(action: PlayerActionData) -> void:
	if action == null:
		return

	if action.action_kind == PlayerActionData.ActionKind.SCAN:
		scan_uses += 1

	for gain: CombatTendencyGainData in action.completion_tendency_gains:
		if gain != null and gain.is_available():
			add_tendency(gain.tendency, gain.amount)


func to_save_data() -> Dictionary:
	return {
		"combat_valour": combat_valour,
		"combat_logic": combat_logic,
		"combat_sync": combat_sync,
		"combat_self": combat_self,
		"cycle_damage_dealt": cycle_damage_dealt,
		"highest_cycle_damage": highest_cycle_damage,
		"highest_single_hit_damage": highest_single_hit_damage,
		"total_damage_dealt": total_damage_dealt,
		"cycles_elapsed": cycles_elapsed,
		"scan_uses": scan_uses,
		"support_uses": support_uses,
		"offensive_uses": offensive_uses,
		"corrupted_uses": corrupted_uses,
		"critical_hits": critical_hits,
		"allies_saved": allies_saved,
		"allies_defeated": allies_defeated,
		"enemies_defeated": enemies_defeated,
		"stability_breaks": stability_breaks,
		"run_attempts": run_attempts
	}


func load_save_data(data: Dictionary) -> void:
	reset()

	for property_name: String in [
		"combat_valour", "combat_logic", "combat_sync", "combat_self",
		"cycle_damage_dealt", "highest_cycle_damage",
		"highest_single_hit_damage", "total_damage_dealt", "cycles_elapsed",
		"scan_uses", "support_uses", "offensive_uses", "corrupted_uses",
		"critical_hits", "allies_saved", "allies_defeated", "enemies_defeated",
		"stability_breaks", "run_attempts"
	]:
		set(property_name, maxi(0, int(data.get(property_name, 0))))
