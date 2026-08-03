extends Node


const GATE_BUNDLE: ConditionalEffectBundleData = preload(
	"res://tests/conditions/fixtures/phase4_gate_bundle.tres"
)
const TEST_LEAD: Resource = preload(
	"res://tests/conditions/fixtures/test_phase4_lead.tres"
)
const TEST_ITEM: Resource = preload(
	"res://tests/conditions/fixtures/test_phase4_item.tres"
)

var _failures := PackedStringArray()
var _saved_campaign: Dictionary
var _saved_time: Dictionary
var _saved_catalog: GameContentCatalog


func _ready() -> void:
	_saved_campaign = CampaignState.export_save_data()
	_saved_time = TimeManager.export_save_data()
	_saved_catalog = ContentRegistry.catalog

	_run_tests()
	_restore_runtime()

	if _failures.is_empty():
		print("CONDITIONS_EFFECTS_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("CONDITIONS_EFFECTS_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _run_tests() -> void:
	_test_empty_set_semantics()
	_configure_fixture_catalog()
	_prepare_gate_state()
	_test_global_text_catalog()
	_test_composite_gate_resource()
	_test_failed_condition_blocks_all_effects()
	_test_effect_state_round_trip()


func _test_empty_set_semantics() -> void:
	var empty_all := ConditionSetData.new()
	empty_all.match_mode = ConditionSetData.MatchMode.ALL
	var empty_any := ConditionSetData.new()
	empty_any.match_mode = ConditionSetData.MatchMode.ANY
	var empty_none := ConditionSetData.new()
	empty_none.match_mode = ConditionSetData.MatchMode.NONE

	_check(empty_all.is_met(), "Empty ALL set must be true.")
	_check(not empty_any.is_met(), "Empty ANY set must be false.")
	_check(empty_none.is_met(), "Empty NONE set must be true.")


func _configure_fixture_catalog() -> void:
	var source: GameContentCatalog = _saved_catalog
	var fixture_catalog := GameContentCatalog.new()

	fixture_catalog.apks.append_array(source.apks)
	fixture_catalog.modules.append_array(source.modules)
	fixture_catalog.items.append_array(source.items)
	fixture_catalog.items.append(TEST_ITEM)
	fixture_catalog.combat_encounters.append_array(source.combat_encounters)
	fixture_catalog.character_loadouts.append_array(source.character_loadouts)
	fixture_catalog.status_effects.append_array(source.status_effects)
	fixture_catalog.dummies.append_array(source.dummies)
	fixture_catalog.occupations.append_array(source.occupations)
	fixture_catalog.app_catalog = source.app_catalog
	fixture_catalog.locations.append_array(source.locations)
	fixture_catalog.dialogues.append_array(source.dialogues)
	fixture_catalog.story_event_catalog = source.story_event_catalog
	fixture_catalog.leads.append_array(source.leads)
	fixture_catalog.leads.append(TEST_LEAD)
	fixture_catalog.incidents.append_array(source.incidents)

	var errors: PackedStringArray = ContentRegistry.configure_catalog(
		fixture_catalog
	)
	_check(errors.is_empty(), "Fixture catalog was rejected: %s" % errors)


func _prepare_gate_state() -> void:
	CampaignState.reset_campaign(false)
	_check(
		CampaignState.create_campaign(
			"phase4_conditions_effects",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the Phase 4 fixture campaign."
	)
	CampaignState.operator.operator_id = "phase4_operator"
	CampaignState.operator.occupation_id = "test_occupation"
	CampaignState.partner_id = "test_partner"
	CampaignState.set_tendency(TendencyStateData.Tendency.LOGIC, 4)
	CampaignState.set_affinity("test_npc", 2)

	GameState.set_flag("phase4.ready", true)
	GameState.set_flag("phase4.alternative", false)
	GameState.set_flag("phase4.blocked", false)
	GameState.set_flag("phase4.applied", false)
	GameState.set_number("phase4.counter", 0)

	TimeManager.days_passed = 3
	TimeManager.current_period = TimeManager.TimePeriod.NIGHT
	TimeManager.current_action_block = 3


func _test_global_text_catalog() -> void:
	var catalog: GlobalTextCatalog = GlobalTextCatalog.get_default()
	_check(catalog != null, "GlobalTextCatalog did not load.")

	if catalog == null:
		return

	_check(
		catalog.validate_data().is_empty(),
		"GlobalTextCatalog contains invalid entries."
	)
	_check(
		GlobalTextCatalog.get_default_text(
			GlobalTextCatalog.TextCategory.BUTTONS,
			"confirm"
		) == "CONFIRM",
		"Global confirm text did not resolve by category and ID."
	)


func _test_composite_gate_resource() -> void:
	var context := GameEffectContext.create(
		"phase4.fixture",
		"test_npc",
		"akihabara",
		"phase4.transaction",
		"phase4.event"
	)
	var validation_errors: PackedStringArray = GATE_BUNDLE.validate_data()
	_check(
		validation_errors.is_empty(),
		"Gate bundle validation failed: %s" % validation_errors
	)
	_check(
		GATE_BUNDLE.can_execute(context),
		"Composite ALL/ANY/NONE gate did not accept matching state."
	)
	_check(
		GATE_BUNDLE.execute(context),
		"Gate bundle did not apply every configured effect."
	)

	_check(GameState.get_flag("phase4.applied"), "Flag effect failed.")
	_check(GameState.get_number("phase4.counter") == 2, "Number effect failed.")
	_check(
		CampaignState.tendencies.get_value(TendencyStateData.Tendency.LOGIC) == 7,
		"Tendency effect failed."
	)
	_check(
		CampaignState.installed_app_ids.has("navigator"),
		"App unlock effect failed."
	)
	_check(
		CampaignState.discovered_location_ids.has("akihabara"),
		"Location discovery effect failed."
	)
	_check(
		CampaignState.inventory.get_item_count("test_phase4_item") == 2,
		"Item grant effect failed."
	)
	_check(
		CampaignState.known_module_ids.has("basic_attack"),
		"Module grant effect failed."
	)
	_check(
		CampaignState.active_lead_ids.has("test_phase4_lead"),
		"Lead activation effect failed."
	)
	_check(
		CampaignState.get_affinity("test_npc") == 6,
		"Affinity effect failed."
	)


func _test_failed_condition_blocks_all_effects() -> void:
	var context := GameEffectContext.create(
		"phase4.fixture",
		"test_npc",
		"akihabara",
		"phase4.transaction.blocked",
		"phase4.event"
	)
	var counter_before: int = GameState.get_number("phase4.counter")
	var affinity_before: int = CampaignState.get_affinity("test_npc")
	GameState.set_flag("phase4.blocked", true)

	_check(
		not GATE_BUNDLE.can_execute(context),
		"NONE condition accepted a matching blocked rule."
	)
	_check(
		not GATE_BUNDLE.execute(context),
		"Failed condition reported a successful bundle execution."
	)
	_check(
		GameState.get_number("phase4.counter") == counter_before
		and CampaignState.get_affinity("test_npc") == affinity_before,
		"A rejected condition applied one or more effects."
	)
	GameState.set_flag("phase4.blocked", false)


func _test_effect_state_round_trip() -> void:
	var snapshot: Dictionary = CampaignState.export_save_data()
	CampaignState.reset_campaign(false)
	var errors: PackedStringArray = CampaignState.restore_save_data(snapshot)

	_check(errors.is_empty(), "Effect state round-trip was rejected: %s" % errors)
	_check(
		CampaignState.get_affinity("test_npc") == 6
		and CampaignState.active_lead_ids.has("test_phase4_lead")
		and CampaignState.known_module_ids.has("basic_attack")
		and CampaignState.installed_app_ids.has("navigator")
		and CampaignState.discovered_location_ids.has("akihabara"),
		"Effect results did not survive CampaignState round-trip."
	)


func _restore_runtime() -> void:
	ContentRegistry.configure_catalog(_saved_catalog)
	CampaignState.restore_save_data(_saved_campaign)
	TimeManager.import_save_data(_saved_time)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
