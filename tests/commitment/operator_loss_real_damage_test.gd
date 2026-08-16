extends Node


const CAMPAIGN_ID: String = "phase14_operator_loss_real_damage"
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const IDLE_MODULE: ModuleData = preload(
	"res://data/content/combat/modules/idle.tres"
)
const BASIC_ATTACK: ModuleData = preload(
	"res://data/content/combat/modules/basic_attack.tres"
)

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	seed(1402)
	_test_root = "user://null_network/tests/operator_loss_real_damage_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected Operator Loss damage regression content: %s" % catalog_errors
	)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	CombatManager.reset_encounter()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 14 Operator Loss Real Damage"
	)
	_check(
		create_errors.is_empty(),
		"Could not create the Operator Loss damage regression campaign: %s" % create_errors
	)

	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register the Operator Loss damage regression Operator: %s" % registration_errors
	)
	var starter_errors: PackedStringArray = APKProgressionService.select_starter(
		"novire_init",
		"Novi",
		0,
		0
	)
	_check(
		starter_errors.is_empty(),
		"Could not select the Operator Loss damage regression starter: %s" % starter_errors
	)
	CampaignState.campaign_phase = CampaignState.CampaignPhase.MAIN_CAMPAIGN
	CampaignState.set_current_location("akihabara")

	if not _failures.is_empty():
		_finish_test()
		return

	CampaignState.partner.current_hp = 0
	CampaignState.notify_partner_changed()
	var primary_loss: Dictionary = PartnerLossService.resolve_after_combat(
		CombatResult.Outcome.DEFEAT,
		"phase14.real_damage.primary_loss",
		0
	)
	var primary_loss_errors: PackedStringArray = primary_loss.get(
		"errors",
		PackedStringArray()
	)
	_check(
		primary_loss_errors.is_empty(),
		"Could not establish the active TURD fixture: %s" % primary_loss_errors
	)
	_check(
		PartnerContinuityService.is_turd_active()
		and CampaignState.partner.current_hp > 0,
		"Primary Partner Loss did not establish a living active TURD."
	)

	if not _failures.is_empty():
		_finish_test()
		return

	_check(
		CombatManager.load_encounter(TEST_ENCOUNTER),
		"CombatManager rejected the real-damage TURD encounter."
	)
	var player: Variant = CombatManager.get_player_actor()
	var enemy: Variant = _first_actor(CombatManager.enemy_team)

	if player is not Dictionary or enemy is not Dictionary:
		_failures.append("The real-damage TURD encounter did not create both combat actors.")
		_finish_test()
		return

	var player_actor := player as Dictionary
	var enemy_actor := enemy as Dictionary
	player_actor["dodge"] = 0.0
	player_actor["def"] = 0.0
	enemy_actor["atk"] = 1000000.0

	for slot_index: int in range(4):
		player_actor["modules"][slot_index] = IDLE_MODULE
		enemy_actor["modules"][slot_index] = BASIC_ATTACK

	CombatManager.rebuild_timeline()
	CombatManager.execute_cycle(false)

	_check(
		float(player_actor.get("hp", 1.0)) <= 0.0,
		"A lethal Module hit did not leave TURD at zero HP inside combat."
	)
	_check(
		CombatManager.is_awaiting_resolution()
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.DEFEAT,
		"Real combat damage did not reach the TURD DEFEAT resolution boundary."
	)

	if CombatManager.is_awaiting_resolution() \
		and CombatManager.get_pending_outcome() == CombatResult.Outcome.DEFEAT:
		var resolution_errors: PackedStringArray = CombatManager.resolve_encounter(
			CombatResult.Outcome.DEFEAT
		)
		_check(
			resolution_errors.is_empty(),
			"Operator Loss failed after real combat damage: %s" % resolution_errors
		)

	var metadata: Dictionary = CombatManager.get_result_metadata()
	_check(
		bool(metadata.get("operator_lost", false))
		and bool(metadata.get("irreversible", false)),
		"Real combat damage did not return irreversible Operator Loss metadata."
	)
	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.OPERATOR_LOSS
		and CampaignState.operator.is_empty()
		and CampaignState.partner.is_empty(),
		"Destroyed TURD remained active instead of resolving Operator Loss."
	)
	_check(
		CampaignState.operator_history.size() == 1,
		"Real-damage Operator Loss did not archive exactly one Operator."
	)

	_finish_test()


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Damage"
	profile.last_name = "Regression"
	profile.nickname = "Damage"
	profile.username = "real_damage_operator"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "damage_body"
	appearance.face_id = "damage_face"
	appearance.eye_id = "damage_eyes"
	appearance.outer_layer_id = "damage_outer"
	appearance.middle_layer_id = "damage_middle"
	appearance.lower_layer_id = "damage_lower"
	appearance.hat_id = "damage_hat"
	appearance.facial_accessory_id = "damage_accessory"
	return appearance


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
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("OPERATOR_LOSS_REAL_DAMAGE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"OPERATOR_LOSS_REAL_DAMAGE_TEST: FAIL (%d)"
		% _failures.size()
	)
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