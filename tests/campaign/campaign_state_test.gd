extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_campaign_round_trip_and_reset()
	_test_content_registry()

	CampaignState.reset_campaign()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("CAMPAIGN_STATE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("CAMPAIGN_STATE_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _test_campaign_round_trip_and_reset() -> void:
	CampaignState.reset_campaign()
	_assert(
		not CampaignState.has_campaign(),
		"CampaignState did not start from an empty state."
	)

	var created: bool = CampaignState.create_campaign(
		"vertical_slice_safe_01",
		CampaignState.SaveMode.SAFE,
		CampaignState.CampaignPhase.PROLOGUE
	)
	_assert(created, "CampaignState rejected a valid campaign.")

	CampaignState.operator.operator_id = "operator_gyu"
	CampaignState.operator.display_name = "GYU"
	CampaignState.operator.occupation_id = "highschooler"
	CampaignState.partner_id = "novire_init"
	CampaignState.tendencies.valour = 6
	CampaignState.tendencies.logic = 4
	CampaignState.tendencies.sync = 3
	CampaignState.tendencies.self_value = 2
	CampaignState.set_money(1250)
	CampaignState.inventory.add_item("healing_patch", 3)
	CampaignState.learn_module("basic_attack")
	CampaignState.install_app("navigator")
	CampaignState.discover_location("akihabara")
	CampaignState.activate_lead("aquarium_signal")
	CampaignState.social_state["npc_tenya"] = {"affinity": 2}
	CampaignState.encyclopedia_state["known_apk_ids"] = ["rattildus"]
	CampaignState.world_state.set_infestation("akihabara", 4)
	CampaignState.world_state.persistent_objects["akihabara.exe.test"] = {
		"defeated": true
	}
	GameState.set_flag("aquarium_signal_found", true)
	GameState.set_number("aquarium_clues", 2)

	_assert(
		CampaignState.world_state.get_flag("aquarium_signal_found"),
		"GameState did not delegate flags to CampaignState.world_state."
	)
	_assert(
		GameState.get_number("aquarium_clues") == 2,
		"GameState did not delegate numeric variables to WorldStateData."
	)

	var exported: Dictionary = CampaignState.export_save_data()
	var restore_copy: Dictionary = exported.duplicate(true)
	_assert(
		_is_plain_save_value(exported),
		"CampaignState exported an Object, Resource or unsupported save value."
	)
	_assert(
		not JSON.stringify(exported).is_empty(),
		"CampaignState export could not be encoded as JSON."
	)

	var exported_world: Dictionary = exported["world_state"]
	var exported_flags: Dictionary = exported_world["story_flags"]
	exported_flags["aquarium_signal_found"] = false
	_assert(
		GameState.get_flag("aquarium_signal_found"),
		"CampaignState export leaked a mutable reference to runtime state."
	)

	CampaignState.reset_campaign()
	_assert(
		CampaignState.campaign_phase \
			== CampaignState.CampaignPhase.NO_CAMPAIGN,
		"Campaign phase did not reset to NO_CAMPAIGN."
	)
	_assert(
		CampaignState.operator.is_empty()
		and CampaignState.tendencies.get_total() == 0
		and CampaignState.money == 0
		and CampaignState.inventory.item_counts.is_empty()
		and CampaignState.known_module_ids.is_empty()
		and CampaignState.world_state.story_flags.is_empty(),
		"CampaignState reset left mutable campaign data behind."
	)

	var restore_errors: PackedStringArray = (
		CampaignState.restore_save_data(restore_copy)
	)
	_assert(
		restore_errors.is_empty(),
		"CampaignState rejected its own exported schema: %s"
		% ", ".join(restore_errors)
	)
	_assert(
		CampaignState.has_campaign()
		and CampaignState.campaign_id == "vertical_slice_safe_01"
		and CampaignState.operator.operator_id == "operator_gyu"
		and CampaignState.partner_id == "novire_init"
		and CampaignState.tendencies.get_total() == 15
		and CampaignState.money == 1250
		and CampaignState.inventory.get_item_count("healing_patch") == 3
		and CampaignState.known_module_ids.has("basic_attack")
		and CampaignState.installed_app_ids.has("navigator")
		and CampaignState.discovered_location_ids.has("akihabara")
		and CampaignState.world_state.get_infestation("akihabara") == 4
		and GameState.get_flag("aquarium_signal_found"),
		"CampaignState round-trip did not restore all tested sections."
	)


func _test_content_registry() -> void:
	var default_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_assert(
		default_errors.is_empty(),
		"Default GameContentCatalog is invalid: %s"
		% ", ".join(default_errors)
	)

	var basic_attack: ModuleData = ContentRegistry.get_module("basic_attack")
	_assert(
		basic_attack != null and basic_attack.module_id == &"basic_attack",
		"ContentRegistry could not resolve the existing basic_attack Module."
	)
	_assert(
		ContentRegistry.get_app("navigator") != null,
		"ContentRegistry could not resolve the Navigator AppResource."
	)
	_assert(
		ContentRegistry.get_location("akihabara") != null,
		"ContentRegistry could not resolve the Akihabara MapLocation."
	)

	var duplicate_catalog := GameContentCatalog.new()
	duplicate_catalog.modules.append(basic_attack)
	duplicate_catalog.modules.append(basic_attack)
	var duplicate_errors: PackedStringArray = (
		ContentRegistry.configure_catalog(duplicate_catalog)
	)
	_assert(
		_contains_text(duplicate_errors, "Duplicate content ID 'basic_attack'"),
		"ContentRegistry did not reject a duplicate Module ID."
	)
	_assert(
		ContentRegistry.get_module("basic_attack") == basic_attack,
		"Rejected catalog replaced the last valid registry atomically."
	)

	var empty_id_module := ModuleData.new()
	empty_id_module.module_id = &""
	var empty_id_catalog := GameContentCatalog.new()
	empty_id_catalog.modules.append(empty_id_module)
	var empty_id_errors: PackedStringArray = (
		ContentRegistry.configure_catalog(empty_id_catalog)
	)
	_assert(
		_contains_text(empty_id_errors, "contains an empty ID"),
		"ContentRegistry did not reject an empty Module ID."
	)


func _is_plain_save_value(value: Variant) -> bool:
	if value is Object:
		return false

	if value is Dictionary:
		for key: Variant in value:
			if not _is_plain_save_value(key):
				return false

			if not _is_plain_save_value(value[key]):
				return false

		return true

	if value is Array:
		for entry: Variant in value:
			if not _is_plain_save_value(entry):
				return false

		return true

	return typeof(value) in [
		TYPE_NIL,
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_STRING
	]


func _contains_text(lines: PackedStringArray, needle: String) -> bool:
	for line: String in lines:
		if line.contains(needle):
			return true

	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
