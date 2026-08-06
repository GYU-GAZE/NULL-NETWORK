extends Node


const ENCOUNTER_ID: String = "akihabara_rattildus_1v1"
const NPC_ID: String = "ganbarekun"
const PARTY_OWNER_ID: String = "test.party_experience"

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected party EXP content: %s" % catalog_errors
	)

	_test_even_split_ignores_dummy()
	_test_dead_party_partner_is_lost()
	_test_defeated_player_receives_no_exp()
	_finish_test()


func _test_even_split_ignores_dummy() -> void:
	var actors: Dictionary = _prepare_party_encounter("party_exp_even_split")
	var player: Dictionary = actors.get("player", {})
	var party: Dictionary = actors.get("party", {})
	var enemy: Dictionary = actors.get("enemy", {})

	if player.is_empty() or party.is_empty() or enemy.is_empty():
		return

	var reward: CombatRewardData = enemy.get("reward_profile") as CombatRewardData
	var reward_copy: CombatRewardData = reward.duplicate(true) as CombatRewardData
	reward_copy.base_experience = 21
	enemy["reward_profile"] = reward_copy
	enemy["hp"] = 0.0
	enemy["defeated"] = true
	var dummy: Dictionary = {
		"uid": 9999,
		"character_id": "temporary_dummy",
		"source_kind": CombatSlotData.ParticipantSource.FIXED_LOADOUT,
		"encounter_slot_index": 2,
		"hp": 1.0,
		"max_hp": 1.0,
		"stability": 0.0,
		"max_stability": 0.0,
		"is_ally": true,
		"is_player": false,
		"is_dummy": true,
		"defeated": false
	}
	var allies: Array[Dictionary] = [
		player.duplicate(true),
		party.duplicate(true),
		dummy
	]
	var enemies: Array[Dictionary] = [enemy.duplicate(true)]
	var progress_states: Array[PlayerActionProgressData] = []
	var result: Dictionary = CombatResolutionService.resolve(
		CombatResult.Outcome.VICTORY,
		ContentRegistry.get_combat_encounter(ENCOUNTER_ID),
		player,
		enemies,
		progress_states,
		CombatTendencyLog.new(),
		allies
	)
	var result_errors: PackedStringArray = result.get(
		"errors",
		PackedStringArray()
	)
	var metadata: Dictionary = result.get("metadata", {})
	var distribution: Array = metadata.get("experience_distribution", [])
	var party_state: NPCPartyPartnerStateData = (
		SocialService.get_party_partner_state(NPC_ID)
	)

	_check(
		result_errors.is_empty(),
		"Living party EXP split failed: %s" % result_errors
	)
	_check(
		int(metadata.get("experience", 0)) == 21
		and int(metadata.get("experience_assigned", 0)) == 21
		and distribution.size() == 2,
		"Dummy occupied an EXP share or total EXP was not preserved."
	)
	_check(
		CampaignState.partner.current_exp == 11
		and party_state != null
		and party_state.current_exp == 10,
		"Remainder-safe EXP split did not grant 11/10 by stable slot order."
	)

	var saved_campaign: Dictionary = CampaignState.export_save_data()
	CampaignState.reset_campaign()
	var restore_errors: PackedStringArray = CampaignState.restore_save_data(
		saved_campaign
	)
	var restored_party_state: NPCPartyPartnerStateData = (
		SocialService.get_party_partner_state(NPC_ID)
	)
	_check(
		restore_errors.is_empty()
		and restored_party_state != null
		and restored_party_state.current_exp == 10,
		"NPC partner EXP did not survive CampaignState restore."
	)


func _test_dead_party_partner_is_lost() -> void:
	var actors: Dictionary = _prepare_party_encounter("party_exp_partner_loss")
	var player: Dictionary = actors.get("player", {})
	var party: Dictionary = actors.get("party", {})
	var enemy: Dictionary = actors.get("enemy", {})

	if player.is_empty() or party.is_empty() or enemy.is_empty():
		return

	party["hp"] = 0.0
	party["defeated"] = true
	enemy["hp"] = 0.0
	enemy["defeated"] = true
	var allies: Array[Dictionary] = [
		player.duplicate(true),
		party.duplicate(true)
	]
	var enemies: Array[Dictionary] = [enemy.duplicate(true)]
	var progress_states: Array[PlayerActionProgressData] = []
	var result: Dictionary = CombatResolutionService.resolve(
		CombatResult.Outcome.VICTORY,
		ContentRegistry.get_combat_encounter(ENCOUNTER_ID),
		player,
		enemies,
		progress_states,
		CombatTendencyLog.new(),
		allies
	)
	var result_errors: PackedStringArray = result.get(
		"errors",
		PackedStringArray()
	)
	var metadata: Dictionary = result.get("metadata", {})
	var lost_ids: Array = metadata.get("lost_party_member_ids", [])
	var party_state: NPCPartyPartnerStateData = (
		SocialService.get_party_partner_state(NPC_ID)
	)

	_check(
		result_errors.is_empty(),
		"Permanent party partner loss resolution failed: %s" % result_errors
	)
	_check(
		CampaignState.partner.current_exp == 20
		and party_state != null
		and party_state.current_exp == 0,
		"Dead party partner received EXP or reduced the survivor's share."
	)
	_check(
		party_state != null
		and party_state.lost
		and party_state.current_hp == 0
		and not SocialService.is_party_member(NPC_ID),
		"0 HP did not persist permanent NPC partner loss and party removal."
	)
	_check(
		not SocialService.add_party_member(NPC_ID, PARTY_OWNER_ID),
		"A permanently lost NPC partner was added to the party again."
	)
	_check(
		lost_ids.has(NPC_ID),
		"Combat metadata did not report the lost party partner."
	)


func _test_defeated_player_receives_no_exp() -> void:
	var actors: Dictionary = _prepare_party_encounter("party_exp_player_defeated")
	var player: Dictionary = actors.get("player", {})
	var party: Dictionary = actors.get("party", {})
	var enemy: Dictionary = actors.get("enemy", {})

	if player.is_empty() or party.is_empty() or enemy.is_empty():
		return

	# The current Phase-10 compatibility policy restores the Operator partner
	# to 1 HP before persistence. The defeat marker must still exclude it from
	# EXP until the Phase-14 permanent-loss lifecycle replaces that policy.
	player["hp"] = 1.0
	player["defeated_in_combat"] = true
	enemy["hp"] = 0.0
	enemy["defeated"] = true
	var allies: Array[Dictionary] = [
		player.duplicate(true),
		party.duplicate(true)
	]
	var enemies: Array[Dictionary] = [enemy.duplicate(true)]
	var progress_states: Array[PlayerActionProgressData] = []
	var result: Dictionary = CombatResolutionService.resolve(
		CombatResult.Outcome.VICTORY,
		ContentRegistry.get_combat_encounter(ENCOUNTER_ID),
		player,
		enemies,
		progress_states,
		CombatTendencyLog.new(),
		allies
	)
	var result_errors: PackedStringArray = result.get(
		"errors",
		PackedStringArray()
	)
	var party_state: NPCPartyPartnerStateData = (
		SocialService.get_party_partner_state(NPC_ID)
	)

	_check(
		result_errors.is_empty(),
		"Defeated-player EXP distribution failed: %s" % result_errors
	)
	_check(
		CampaignState.partner.current_exp == 0
		and party_state != null
		and party_state.current_exp == 20,
		"A defeated player partner received EXP instead of the living ally."
	)


func _prepare_party_encounter(campaign_id: String) -> Dictionary:
	CombatManager.reset_encounter()
	ActivityManager.reset_runtime_state()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	CampaignState.create_campaign(
		campaign_id,
		CampaignState.SaveMode.SAFE,
		CampaignState.CampaignPhase.MAIN_CAMPAIGN
	)
	var partner: PartnerStateData = APKProgressionService.create_partner_state(
		"novire_init",
		"NOVIRE",
		0,
		0
	)

	if partner == null or not CampaignState.set_partner_state(partner):
		_check(false, "Could not create the player partner fixture.")
		return {}

	_check(
		SocialService.add_friend(NPC_ID),
		"Could not add Ganbarekun to the friend list."
	)
	_check(
		SocialService.add_party_member(NPC_ID, PARTY_OWNER_ID),
		"Could not add Ganbarekun's living partner to the party."
	)
	var encounter: CombatEncounter = ContentRegistry.get_combat_encounter(
		ENCOUNTER_ID
	)
	_check(
		encounter != null and CombatManager.load_encounter(encounter),
		"Could not load the standard party-enabled encounter."
	)
	var player: Variant = CombatManager.ally_team[0]
	var party: Variant = CombatManager.ally_team[1]
	var enemy: Variant = CombatManager.enemy_team[1]

	if player is not Dictionary \
		or party is not Dictionary \
		or enemy is not Dictionary:
		_check(false, "Combat did not materialize player, party and enemy actors.")
		return {}

	return {
		"player": player,
		"party": party,
		"enemy": enemy
	}


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	ActivityManager.reset_runtime_state()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("PARTY_EXPERIENCE_DISTRIBUTION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"PARTY_EXPERIENCE_DISTRIBUTION_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
