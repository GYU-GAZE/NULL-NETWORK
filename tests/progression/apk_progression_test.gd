extends Node

const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)

var _failures := PackedStringArray()
var _test_root: String

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_test_root = "user://null_network/tests/progression_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	var registry_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(registry_errors.is_empty(), "Default catalog failed: %s" % registry_errors)
	var create_errors: PackedStringArray = SaveManager.create_campaign(
		"phase9_partner_progression",
		CampaignState.SaveMode.SAFE,
		"Phase 9 Partner"
	)
	_check(create_errors.is_empty(), "Phase 9 campaign creation failed: %s" % create_errors)
	CampaignState.operator.operator_id = "phase9_operator"
	CampaignState.operator.profile.first_name = "Gyu"
	CampaignState.operator.profile.nickname = "Operator"

	_test_canonical_formulas()
	_test_starter_selection()
	_test_inventory_entries()
	_test_combat_snapshot_and_progression()
	_test_save_restart()
	_finish_test()

func _test_canonical_formulas() -> void:
	_check(
		APKProgressionService.get_exp_for_next_level(1) == 7
		and APKProgressionService.get_total_exp_for_level(80) == 511999
		and APKProgressionService.get_exp_for_next_level(80) == 1944100,
		"Canonical EXP curve or the post-80 barrier is incorrect."
	)
	var apk: APKData = ContentRegistry.get_apk("novire_init")
	var partner := PartnerStateData.new()
	partner.apk_id = "novire_init"
	partner.level = 100
	var stats: Dictionary = APKStatCalculator.calculate_stats(apk, partner)
	_check(
		int(stats.get("max_hp", 0)) == 240
		and int(stats.get("atk", 0)) == 70
		and int(stats.get("def", 0)) == 50
		and int(stats.get("matk", 0)) == 60
		and int(stats.get("mdef", 0)) == 55
		and int(stats.get("max_stability", 0)) == 100,
		"NOVIRE level-100 stats do not match the GDD profile."
	)

func _test_starter_selection() -> void:
	var errors: PackedStringArray = APKProgressionService.select_starter(
		"novire_init",
		"Novi",
		1,
		2
	)
	_check(errors.is_empty(), "Starter selection failed: %s" % errors)
	var apk: APKData = ContentRegistry.get_apk("novire_init")
	var term: AddressTermData = apk.get_address_term(CampaignState.partner.address_term_id)
	_check(
		CampaignState.partner.apk_id == "novire_init"
		and CampaignState.partner.nickname == "Novi"
		and CampaignState.partner.personality_id == "brave"
		and CampaignState.partner.address_term_id == "boss"
		and term != null
		and term.resolve_text(CampaignState.operator.profile) == "Boss"
		and CampaignState.partner.active_module_ids.size() == 4
		and CampaignState.partner.level == APKProgressionService.ONBOARDING_STARTER_LEVEL
		and CampaignState.partner.current_exp == APKProgressionService.get_total_exp_for_level(3)
		and CampaignState.partner.allocation_points == 2
		and CampaignState.partner.known_active_module_ids.has("basic_heal"),
		"Controlled personality, address term, level-3 state or starter Modules were not generated."
	)
	_check(
		not APKProgressionService.select_starter("novire_init").is_empty(),
		"A second starter replaced the active partner."
	)

func _test_inventory_entries() -> void:
	CampaignState.grant_item("healing_patch", 3)
	var entry: InventoryEntryData = CampaignState.inventory.get_entry("healing_patch")
	_check(
		entry != null
		and entry.amount == 3
		and ContentRegistry.get_item(entry.item_id) != null,
		"Typed inventory entry was not created or resolved."
	)

func _test_combat_snapshot_and_progression() -> void:
	CampaignState.partner.affinity = 7
	var hp_before: int = CampaignState.partner.current_hp
	var stability_before: int = CampaignState.partner.current_stability
	_check(CombatManager.load_encounter(TEST_ENCOUNTER), "CombatManager rejected the PLAYER_PARTNER encounter.")
	var actor: Variant = CombatManager.get_player_actor()
	_check(actor is Dictionary, "PLAYER_PARTNER did not create a combat actor.")
	if actor is not Dictionary:
		return

	_check(
		int(actor.get("source_kind", -1)) == CombatSlotData.ParticipantSource.PLAYER_PARTNER
		and str(actor.get("character_id", "")) == "novire_init"
		and int(actor.get("hp", 0)) == hp_before
		and int(actor.get("stability", 0)) == stability_before,
		"Combat did not start from the persistent partner snapshot."
	)
	actor["hp"] = maxi(1, int(actor["max_hp"]) - 1)
	actor["stability"] = 43.0
	actor["modules"][3] = ContentRegistry.get_module("basic_dodge")
	_check(
		CampaignState.partner.current_stability == stability_before
		and CampaignState.partner.active_module_ids[3] == "basic_attack",
		"Combat mutated PartnerState before the stable write-back boundary."
	)
	var commit_errors: PackedStringArray = CombatManager.commit_player_partner_state(7)
	_check(commit_errors.is_empty(), "Partner write-back failed: %s" % commit_errors)
	_check(
		CampaignState.partner.level == 3
		and CampaignState.partner.current_exp == 33
		and CampaignState.partner.allocation_points == 2
		and CampaignState.partner.current_stability == 43
		and CampaignState.partner.affinity == 7
		and CampaignState.partner.active_module_ids[3] == "basic_dodge"
		and CampaignState.partner.known_active_module_ids.has("basic_heal"),
		"HP/Stability/EXP/affinity/Modules did not return to the level-3 PartnerState."
	)
	_check(
		CombatManager.commit_player_partner_state(7).is_empty()
		and CampaignState.partner.current_exp == 33,
		"Partner write-back was not idempotent."
	)
	var allocation_errors: PackedStringArray = APKProgressionService.allocate_stat("atk", 1)
	_check(
		allocation_errors.is_empty()
		and CampaignState.partner.allocation_points == 1
		and CampaignState.partner.get_allocated_stat("atk") == 1,
		"One of the starter's two initial Allocation Points was not distributed."
	)
	_check(
		not APKProgressionService.allocate_stat("atk", 1).is_empty()
		and CampaignState.partner.allocation_points == 1,
		"Level-3 per-stat concentration limit was not enforced."
	)
	CombatManager.reset_encounter()

func _test_save_restart() -> void:
	var expected: Dictionary = CampaignState.partner.to_save_data()
	_check(SaveManager.save_checkpoint(&"phase9.partner", true), "Could not save the Phase 9 partner checkpoint.")
	CampaignState.reset_campaign()
	CombatManager.reset_encounter()
	var load_errors: PackedStringArray = SaveManager.load_campaign("phase9_partner_progression")
	_check(load_errors.is_empty(), "Phase 9 reload failed: %s" % load_errors)
	_check(
		CampaignState.partner.to_save_data() == expected
		and CampaignState.inventory.get_item_count("healing_patch") == 3,
		"Partner or inventory did not survive save/restart exactly."
	)
	_check(CombatManager.load_encounter(TEST_ENCOUNTER), "Restored partner could not re-enter combat.")
	var restored_actor: Variant = CombatManager.get_player_actor()
	var restored_modules: Array = restored_actor.get("modules", []) if restored_actor is Dictionary else []
	var restored_module: ModuleData = restored_modules[3] as ModuleData if restored_modules.size() > 3 else null
	_check(
		restored_actor is Dictionary
		and int(restored_actor.get("hp", -1)) == CampaignState.partner.current_hp
		and int(restored_actor.get("stability", -1)) == 43
		and restored_module != null
		and str(restored_module.module_id) == "basic_dodge",
		"Restored combat snapshot diverged from authoritative PartnerState."
	)
	CombatManager.reset_encounter()
	var legacy_state: Dictionary = CampaignState.export_save_data()
	legacy_state["schema_version"] = 3
	legacy_state["partner_id"] = CampaignState.partner.apk_id
	legacy_state.erase("partner")
	var legacy_errors: PackedStringArray = CampaignState.restore_save_data(legacy_state)
	_check(
		legacy_errors.is_empty()
		and CampaignState.partner.apk_id == "novire_init"
		and APKProgressionService.validate_partner_state(CampaignState.partner).is_empty()
		and CampaignState.validate_save_data(CampaignState.export_save_data()).is_empty(),
		"Legacy partner_id did not migrate to a valid PartnerStateData."
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish_test() -> void:
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)
	if _failures.is_empty():
		print("APK_PROGRESSION_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("APK_PROGRESSION_TEST: FAIL (%d)" % _failures.size())
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
