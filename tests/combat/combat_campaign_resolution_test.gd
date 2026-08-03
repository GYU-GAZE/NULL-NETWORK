extends Node


const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const REST_MODULE: ModuleData = preload(
	"res://data/content/combat/modules/idle.tres"
)
const BASIC_ATTACK: ModuleData = preload(
	"res://data/content/combat/modules/basic_attack.tres"
)
const HEAVY_ATTACK: ModuleData = preload(
	"res://data/content/combat/modules/heavy_attack.tres"
)

var _failures := PackedStringArray()
var _test_root: String


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	seed(1010)
	_test_root = "user://null_network/tests/combat_resolution_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var registry_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(registry_errors.is_empty(), "Default catalog failed: %s" % registry_errors)
	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"phase10_combat_resolution",
		CampaignState.SaveMode.SAFE,
		"Phase 10 Combat"
	)
	_check(create_errors.is_empty(), "Phase 10 campaign creation failed: %s" % create_errors)
	CampaignState.campaign_phase = CampaignState.CampaignPhase.MAIN_CAMPAIGN

	_test_normal_victory_and_style()
	_test_scan()
	_test_purge()
	_test_purify()
	_test_tame(false)
	_test_tame(true)
	_test_evolution()
	_test_escape()
	_test_recoverable_defeat()
	_test_save_between_cycles()
	_finish_test()


func _test_normal_victory_and_style() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var player: Dictionary = actors.get("player", {})
	var enemy: Dictionary = actors.get("enemy", {})

	if player.is_empty() or enemy.is_empty():
		return

	player["atk"] = 1.0
	enemy["hp"] = 1000.0
	enemy["max_hp"] = 1000.0

	for slot_index: int in range(4):
		CombatManager.set_player_module(slot_index, BASIC_ATTACK)

	CombatManager.execute_cycle(false)
	CombatManager.execute_cycle(false)
	_check(
		CombatManager.combat_tendency_log.combat_valour >= 8,
		"Temporary Module tendencies were not accumulated across cycles."
	)
	enemy["hp"] = 1.0
	CombatManager.execute_cycle(false)
	_check(
		CombatManager.is_awaiting_resolution()
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY,
		"A normal enemy defeat did not reach the victory boundary."
	)
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.VICTORY
	)
	var metadata: Dictionary = CombatManager.get_result_metadata()
	_check(errors.is_empty(), "Normal victory resolution failed: %s" % errors)
	_check(
		int(metadata.get("experience", 0)) == 20
		and CampaignState.partner.level == 2
		and CampaignState.partner.allocation_points == 1
		and CampaignState.inventory.get_item_count("healing_patch") == 1,
		"Normal defeat rewards or level-up were not applied exactly once."
	)
	var style: Dictionary = metadata.get("combat_style", {})
	_check(
		str(style.get("style_name", "")) == "VALIANT"
		and CampaignState.tendencies.valour == 2,
		"Combat Style did not compress temporary VALOUR into the two-point cap."
	)
	var entries: Dictionary = CampaignState.encyclopedia_state.get("entries", {})
	_check(
		entries.has("exe.rattildus")
		and bool((entries["exe.rattildus"] as Dictionary).get("defeated", false)),
		"Normal victory did not update the Encyclopedia discovery record."
	)
	var exp_after: int = CampaignState.partner.current_exp
	_check(
		CombatManager.resolve_encounter(CombatResult.Outcome.VICTORY).is_empty()
		and CampaignState.partner.current_exp == exp_after,
		"Combat resolution was not idempotent."
	)
	_check(CombatManager.finalize_resolved_encounter(), "Normal victory did not finalize.")


func _test_scan() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var enemy: Dictionary = actors.get("enemy", {})

	if enemy.is_empty() or not _complete_action("scan", enemy):
		return

	var choice_errors: PackedStringArray = CombatManager.select_player_action_reward(
		"heavy_attack"
	)
	_check(choice_errors.is_empty(), "SCAN choice failed: %s" % choice_errors)
	_kill_current_enemy()
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.VICTORY
	)
	_check(errors.is_empty(), "SCAN resolution failed: %s" % errors)
	_check(
		CampaignState.known_module_ids.has("heavy_attack")
		and CampaignState.tendencies.logic == 1,
		"SCAN did not grant the chosen active Module and permanent LOGIC."
	)
	CombatManager.finalize_resolved_encounter()


func _test_purge() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var enemy: Dictionary = actors.get("enemy", {})

	if enemy.is_empty() or not _complete_action("purge", enemy):
		return

	_check(bool(enemy.get("purged", false)), "PURGE did not mark its target.")
	_check(
		not CombatManager.set_player_action(0, "purify", int(enemy["uid"])).is_empty()
		and not CombatManager.set_player_action(0, "tame", int(enemy["uid"])).is_empty(),
		"PURGE did not exclude PURIFY and TAME for the same target."
	)
	_kill_current_enemy()
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.VICTORY
	)
	var metadata: Dictionary = CombatManager.get_result_metadata()
	_check(errors.is_empty(), "PURGE resolution failed: %s" % errors)
	var extracted_modules: Array = metadata.get("module_ids", []) as Array
	_check(
		int(metadata.get("experience", 0)) in [30, 40]
		and (
			not extracted_modules.is_empty()
			or int(metadata.get("experience", 0)) == 40
		)
		and CampaignState.tendencies.self_value == 1,
		"PURGE did not grant increased EXP, active extraction/duplicate EXP and permanent SELF."
	)
	CombatManager.finalize_resolved_encounter()


func _test_purify() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var enemy: Dictionary = actors.get("enemy", {})

	if enemy.is_empty() or not _complete_action("purify", enemy):
		return

	_check(bool(enemy.get("purified", false)), "PURIFY did not stabilize its target.")
	_check(
		not CombatManager.set_player_action(0, "purge", int(enemy["uid"])).is_empty(),
		"PURIFY did not exclude PURGE for the same target."
	)
	_kill_current_enemy()
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.VICTORY
	)
	_check(errors.is_empty(), "PURIFY resolution failed: %s" % errors)
	_check(
		CampaignState.partner.secondary_passive_module_id == "rattildus_guard"
		and not CampaignState.partner.known_active_module_ids.has("rattildus_guard")
		and CampaignState.tendencies.sync == 1,
		"PURIFY did not install only the transferable passive or permanent SYNC."
	)
	CombatManager.finalize_resolved_encounter()


func _test_tame(purified_first: bool) -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var enemy: Dictionary = actors.get("enemy", {})

	if enemy.is_empty():
		return

	if purified_first and not _complete_action("purify", enemy):
		return

	if not _complete_action("tame", enemy):
		return

	_check(
		CombatManager.is_awaiting_resolution()
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY,
		"TAME did not remove the target through the terminal combat boundary."
	)
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.VICTORY
	)
	_check(errors.is_empty(), "TAME resolution failed: %s" % errors)
	var expected_integrity := (
		PartnerStateData.IntegrityState.PURIFIED
		if purified_first
		else PartnerStateData.IntegrityState.EXE
	)
	_check(
		CampaignState.partner.apk_id == "rattildus_init"
		and CampaignState.partner.integrity_state == expected_integrity,
		"TAME did not replace the partner with the expected integrity state."
	)
	CombatManager.finalize_resolved_encounter()


func _test_evolution() -> void:
	_prepare_partner(15)
	CampaignState.set_tendency(TendencyStateData.Tendency.VALOUR, 30)
	var actors: Dictionary = _load_quiet_encounter()
	var player: Dictionary = actors.get("player", {})

	if player.is_empty():
		return

	for slot_index: int in range(4):
		CombatManager.set_player_module(slot_index, REST_MODULE)

	CombatManager.execute_cycle(false)
	var branch: EvolutionBranchData = EvolutionManager.get_pending_branch()
	_check(
		branch != null and branch.branch_id == "evolution.novire.valour",
		"End-of-cycle projected VALOUR did not offer the configured evolution."
	)
	var old_hp: int = CampaignState.partner.current_hp
	var old_max_hp: int = int(APKProgressionService.get_current_stats().get("max_hp", 1))
	var errors: PackedStringArray = CombatManager.accept_pending_evolution()
	var new_max_hp: int = int(APKProgressionService.get_current_stats().get("max_hp", 1))
	_check(errors.is_empty(), "Evolution acceptance failed: %s" % errors)
	_check(
		CampaignState.partner.apk_id == "novire_valour"
		and CampaignState.partner.level == 15
		and CampaignState.partner.current_exp == APKProgressionService.get_total_exp_for_level(15)
		and CampaignState.partner.current_hp == mini(new_max_hp, old_hp + (new_max_hp - old_max_hp)),
		"Evolution did not preserve progression or apply the canonical HP delta."
	)
	CombatManager.reset_encounter()


func _test_escape() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var player: Dictionary = actors.get("player", {})

	if player.is_empty():
		return

	player["dodge"] = 1.0
	var escaped: bool = false

	for _attempt: int in range(100):
		if CombatManager.try_escape():
			escaped = true
			break

	_check(escaped, "A 95% escape chance never reached the escape boundary.")
	_check(
		CombatManager.combat_tendency_log.combat_self >= 2,
		"Configurable escape behavior did not contribute temporary SELF."
	)
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.ESCAPED
	)
	_check(errors.is_empty(), "Escape resolution failed: %s" % errors)
	_check(
		CampaignState.partner.apk_id == "novire_init"
		and CampaignState.partner.integrity_state == PartnerStateData.IntegrityState.REGISTERED
		and CampaignState.campaign_phase == CampaignState.CampaignPhase.MAIN_CAMPAIGN,
		"Escape incorrectly activated a definitive Partner/Operator Loss state."
	)
	CombatManager.finalize_resolved_encounter()


func _test_recoverable_defeat() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var player: Dictionary = actors.get("player", {})

	if player.is_empty():
		return

	player["hp"] = 0.0
	CombatManager.execute_cycle(false)
	_check(
		CombatManager.is_awaiting_resolution()
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.DEFEAT,
		"Zero HP did not reach the recoverable defeat boundary."
	)
	var errors: PackedStringArray = CombatManager.resolve_encounter(
		CombatResult.Outcome.DEFEAT
	)
	_check(errors.is_empty(), "Defeat resolution failed: %s" % errors)
	_check(
		CampaignState.partner.apk_id == "novire_init"
		and CampaignState.partner.integrity_state == PartnerStateData.IntegrityState.REGISTERED
		and CampaignState.campaign_phase == CampaignState.CampaignPhase.MAIN_CAMPAIGN,
		"Defeat incorrectly activated the Phase 14 loss lifecycle."
	)
	CombatManager.finalize_resolved_encounter()


func _test_save_between_cycles() -> void:
	_prepare_partner(1)
	var actors: Dictionary = _load_quiet_encounter()
	var enemy: Dictionary = actors.get("enemy", {})

	if enemy.is_empty():
		return

	_check(
		CombatManager.set_player_action(0, "scan", int(enemy["uid"])).is_empty(),
		"Could not assign partial SCAN before save."
	)
	for slot_index: int in range(1, 4):
		CombatManager.set_player_module(slot_index, REST_MODULE)

	CombatManager.execute_cycle(false)
	var progress: PlayerActionProgressData = PlayerActionService.get_progress(
		CombatManager.player_action_progress,
		"scan",
		int(enemy["uid"])
	)
	_check(progress != null and progress.progress == 25, "Partial SCAN did not reach 25%.")
	_check(
		SaveManager.save_checkpoint(&"phase10.between_cycles", true),
		"Could not save between combat cycles."
	)
	CampaignState.reset_campaign()
	CombatManager.reset_encounter()
	var errors: PackedStringArray = SaveManager.load_campaign(
		"phase10_combat_resolution"
	)
	_check(errors.is_empty(), "Between-cycle reload failed: %s" % errors)
	var restored: PlayerActionProgressData = (
		CombatManager.player_action_progress[0]
		if not CombatManager.player_action_progress.is_empty()
		else null
	)
	_check(
		CombatManager.is_encounter_active()
		and restored != null
		and restored.action_id == "scan"
		and restored.progress == 25
		and not restored.completed,
		"Combat save/restart did not restore exact Player Action progress."
	)


func _prepare_partner(level: int) -> void:
	CombatManager.reset_encounter()
	CampaignState.inventory.reset()
	CampaignState.known_module_ids.clear()
	CampaignState.encyclopedia_state.clear()
	CampaignState.tendencies.reset()
	var partner: PartnerStateData = APKProgressionService.create_partner_state(
		"novire_init",
		"Novi",
		0,
		0
	)

	if partner == null:
		_failures.append("Could not create the Phase 10 partner fixture.")
		return

	partner.level = clampi(level, 1, 100)
	partner.current_exp = APKProgressionService.get_total_exp_for_level(partner.level)
	partner.allocation_points = maxi(0, partner.level - 1)
	var stats: Dictionary = APKProgressionService.calculate_partner_stats(partner)
	partner.current_hp = int(stats.get("max_hp", 1))
	_check(CampaignState.set_partner_state(partner), "Campaign rejected partner fixture.")
	CampaignState.known_module_ids = partner.known_active_module_ids.duplicate()


func _load_quiet_encounter() -> Dictionary:
	_check(CombatManager.load_encounter(TEST_ENCOUNTER), "CombatManager rejected Phase 10 encounter.")
	var player: Variant = CombatManager.get_player_actor()
	var enemy: Variant = _first_actor(CombatManager.enemy_team)

	if player is not Dictionary or enemy is not Dictionary:
		_failures.append("Phase 10 encounter did not create both actors.")
		return {}

	for slot_index: int in range(4):
		(enemy as Dictionary)["modules"][slot_index] = REST_MODULE

	CombatManager.rebuild_timeline()
	return {"player": player, "enemy": enemy}


func _complete_action(action_id: String, enemy: Dictionary) -> bool:
	for slot_index: int in range(4):
		var errors: PackedStringArray = CombatManager.set_player_action(
			slot_index,
			action_id,
			int(enemy.get("uid", -1))
		)

		if not errors.is_empty():
			_failures.append("Could not assign %s: %s" % [action_id, errors])
			return false

	CombatManager.execute_cycle(false)
	var state: PlayerActionProgressData = PlayerActionService.get_progress(
		CombatManager.player_action_progress,
		action_id,
		int(enemy.get("uid", -1))
	)
	_check(
		state != null and state.completed and state.progress == 100,
		"%s did not reach 100%% with four Timeline slots." % action_id.to_upper()
	)
	return state != null and state.completed


func _kill_current_enemy() -> void:
	var player: Variant = CombatManager.get_player_actor()
	var enemy: Variant = _first_actor(CombatManager.enemy_team)

	if player is not Dictionary or enemy is not Dictionary:
		_failures.append("Could not prepare the post-action defeat cycle.")
		return

	(player as Dictionary)["atk"] = 1000.0
	for slot_index: int in range(4):
		CombatManager.set_player_module(slot_index, HEAVY_ATTACK)

	CombatManager.execute_cycle(false)
	_check(
		CombatManager.is_awaiting_resolution()
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY,
		"Post-action enemy defeat did not reach victory."
	)


func _first_actor(team: Array) -> Variant:
	for actor: Variant in team:
		if actor is Dictionary:
			return actor

	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("COMBAT_CAMPAIGN_RESOLUTION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("COMBAT_CAMPAIGN_RESOLUTION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()

	while not entry.is_empty():
		var child_path: String = "%s/%s" % [path, entry]

		if directory.current_is_dir():
			_remove_directory_recursive(child_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child_path))

		entry = directory.get_next()

	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
