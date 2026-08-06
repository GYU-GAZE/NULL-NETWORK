extends Node


const CAMPAIGN_ID: String = "phase14_partner_loss_turd"

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/commitment_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected commitment content: %s" % catalog_errors
	)
	_check(
		ContentRegistry.get_apk(TurdPartnerFactory.TURD_APK_ID) != null,
		"TURD APK is not registered in ContentRegistry."
	)

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 14 Partner Loss"
	)
	_check(
		create_errors.is_empty(),
		"Could not create commitment fixture campaign: %s" % create_errors
	)

	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register commitment fixture Operator: %s"
		% registration_errors
	)
	var starter_errors: PackedStringArray = APKProgressionService.select_starter(
		"novire_init",
		"Novi",
		0,
		0
	)
	_check(
		starter_errors.is_empty(),
		"Could not select commitment fixture starter: %s" % starter_errors
	)
	CampaignState.set_current_location("akihabara")

	CampaignState.partner.current_hp = 0
	CampaignState.notify_partner_changed()
	var first_loss: Dictionary = PartnerLossService.resolve_after_combat(
		CombatResult.Outcome.DEFEAT,
		"phase14.first_loss"
	)
	var first_loss_errors: PackedStringArray = first_loss.get(
		"errors",
		PackedStringArray()
	)
	_check(
		first_loss_errors.is_empty(),
		"First Partner Loss failed: %s" % first_loss_errors
	)
	var first_metadata: Dictionary = first_loss.get("metadata", {}) as Dictionary
	_check(
		bool(first_metadata.get("partner_lost", false))
		and str(first_metadata.get("lost_apk_id", "")) == "novire_init"
		and PartnerContinuityService.is_turd_active(),
		"Primary Partner Loss did not activate TURD."
	)
	_check(
		PartnerContinuityService.get_lost_partner_history().size() == 1,
		"First lost partner was not archived."
	)
	_check(
		CampaignState.world_state.get_infestation("akihabara") == 1,
		"Partner Loss did not increase location infestation exactly once."
	)

	var turd_exp_errors: PackedStringArray = APKProgressionService.grant_experience(20)
	_check(
		turd_exp_errors.is_empty(),
		"Could not progress TURD before reserve transition: %s"
		% turd_exp_errors
	)
	CampaignState.partner.affinity = 7
	CampaignState.partner.active_module_ids = PackedStringArray([
		"basic_heal",
		"basic_defense",
		"basic_dodge",
		"basic_attack"
	])
	CampaignState.notify_partner_changed()
	var preserved_turd: Dictionary = CampaignState.partner.to_save_data()

	var tamed_partner: PartnerStateData = (
		APKProgressionService.create_tamed_partner_state(
			"rattildus_init",
			3,
			PartnerStateData.IntegrityState.EXE,
			0
		)
	)
	_check(tamed_partner != null, "Could not create the TAME fixture partner.")
	_check(
		tamed_partner != null \
		and PartnerContinuityService.replace_partner_from_tame(tamed_partner),
		"TAME did not replace active TURD with the new primary partner."
	)
	_check(
		CampaignState.partner.apk_id == "rattildus_init"
		and PartnerContinuityService.has_turd_reserve(),
		"TAME did not move TURD into the inactive reserve."
	)
	_assert_turd_matches(
		PartnerContinuityService.get_turd_state_snapshot(),
		preserved_turd,
		"reserved"
	)

	CampaignState.partner.current_hp = 0
	CampaignState.notify_partner_changed()
	var second_loss: Dictionary = PartnerLossService.resolve_after_combat(
		CombatResult.Outcome.DEFEAT,
		"phase14.second_loss"
	)
	var second_loss_errors: PackedStringArray = second_loss.get(
		"errors",
		PackedStringArray()
	)
	_check(
		second_loss_errors.is_empty(),
		"Second Partner Loss failed: %s" % second_loss_errors
	)
	_check(
		PartnerContinuityService.is_turd_active()
		and not PartnerContinuityService.has_turd_reserve(),
		"Second Partner Loss did not move the reserved TURD back to active state."
	)
	_assert_turd_matches(CampaignState.partner, preserved_turd, "reactivated")
	_check(
		PartnerContinuityService.get_lost_partner_history().size() == 2,
		"Second lost partner was not appended to permanent history."
	)
	_check(
		CampaignState.world_state.get_infestation("akihabara") == 2,
		"Second Partner Loss did not increase infestation exactly once."
	)

	_check(
		SaveManager.save_checkpoint(&"phase14.partner_loss", true),
		"Could not save the Partner Loss checkpoint."
	)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	var load_errors: PackedStringArray = SaveManager.load_campaign(CAMPAIGN_ID)
	_check(
		load_errors.is_empty(),
		"Commitment campaign reload failed: %s" % load_errors
	)
	_check(
		PartnerContinuityService.is_turd_active()
		and PartnerContinuityService.get_lost_partner_history().size() == 2
		and CampaignState.world_state.get_infestation("akihabara") == 2,
		"Partner continuity did not survive save/reload."
	)
	_assert_turd_matches(CampaignState.partner, preserved_turd, "restored")

	CampaignState.partner.current_hp = 0
	var operator_loss_boundary: Dictionary = PartnerLossService.resolve_after_combat(
		CombatResult.Outcome.DEFEAT,
		"phase14.operator_loss_boundary"
	)
	var boundary_metadata: Dictionary = operator_loss_boundary.get(
		"metadata",
		{}
	) as Dictionary
	_check(
		bool(boundary_metadata.get("operator_loss_required", false)),
		"Defeated TURD did not report the Operator Loss boundary."
	)

	_finish_test()


func _assert_turd_matches(
	state: PartnerStateData,
	expected: Dictionary,
	boundary: String
) -> void:
	_check(state != null, "%s TURD state is missing." % boundary.capitalize())

	if state == null:
		return

	_check(
		state.apk_id == "turd_init"
		and state.integrity_state == PartnerStateData.IntegrityState.TURD
		and state.level == int(expected.get("level", -1))
		and state.current_exp == int(expected.get("current_exp", -1))
		and state.affinity == int(expected.get("affinity", -1))
		and Array(state.active_module_ids) == expected.get("active_module_ids", []),
		"%s TURD did not preserve progression, affinity and equipped Modules."
		% boundary.capitalize()
	)


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Gyu"
	profile.last_name = "Commitment"
	profile.nickname = "Operator"
	profile.username = "commitment_operator"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_commitment"
	appearance.face_id = "face_commitment"
	appearance.eye_id = "eyes_commitment"
	appearance.outer_layer_id = "outer_commitment"
	appearance.middle_layer_id = "middle_commitment"
	appearance.lower_layer_id = "lower_commitment"
	appearance.hat_id = "hat_commitment"
	appearance.facial_accessory_id = "accessory_commitment"
	return appearance


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)

	if _failures.is_empty():
		print("PARTNER_LOSS_TURD_CONTINUITY_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"PARTNER_LOSS_TURD_CONTINUITY_TEST: FAIL (%d)"
		% _failures.size()
	)
	get_tree().quit(1)
