extends Node


const CAMPAIGN_ID: String = "phase14_operator_loss_succession"
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const IDLE_MODULE: ModuleData = preload(
	"res://data/content/combat/modules/idle.tres"
)
const AKIHABARA_AREA_SCENE: PackedScene = preload(
	"res://data/content/navigator/areas/akihabara/akihabara_local_area.tscn"
)

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/operator_loss_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	ContentRegistry.reset_to_default_catalog()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	CombatManager.reset_encounter()

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 14 Operator Succession"
	)
	_check(
		create_errors.is_empty(),
		"Could not create the Operator Loss campaign: %s" % create_errors
	)
	TimeManager.import_save_data({
		"version": TimeManager.SAVE_DATA_VERSION,
		"days_passed": 12,
		"days_until_update": 0,
		"current_period": int(TimeManager.TimePeriod.NIGHT),
		"current_action_block": 5
	})

	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile("first_operator", "First"),
		_make_appearance("first"),
		{"valour": 6, "logic": 4, "sync": 3, "self": 2}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register the first Operator: %s" % registration_errors
	)
	var starter_errors: PackedStringArray = APKProgressionService.select_starter(
		"novire_init",
		"Novi",
		0,
		0
	)
	_check(
		starter_errors.is_empty(),
		"Could not select the first Operator starter: %s" % starter_errors
	)
	CampaignState.campaign_phase = CampaignState.CampaignPhase.MAIN_CAMPAIGN
	CampaignState.set_current_location("akihabara")
	CampaignState.install_app("navigator")
	CampaignState.completed_lead_ids.append("aquarium_signal")
	CampaignState.world_state.mark_incident_completed(
		"akihabara_aquarium_relay"
	)
	CampaignState.world_state.set_flag("world_survives_operator_loss", true)

	CampaignState.partner.current_hp = 0
	CampaignState.notify_partner_changed()
	var first_loss: Dictionary = PartnerLossService.resolve_after_combat(
		CombatResult.Outcome.DEFEAT,
		"phase14.primary_loss",
		1
	)
	var first_loss_errors: PackedStringArray = first_loss.get(
		"errors",
		PackedStringArray()
	)
	_check(
		first_loss_errors.is_empty(),
		"Primary Partner Loss failed: %s" % first_loss_errors
	)
	_check(
		PartnerContinuityService.is_turd_active(),
		"Primary Partner Loss did not activate TURD."
	)

	CampaignState.set_money(777)
	CampaignState.grant_item("healing_patch", 4)
	CampaignState.learn_module("heavy_attack")
	CampaignState.set_affinity("ganbarekun", 9)
	CampaignState.encyclopedia_state = {
		"entries": {
			"exe.rattildus": {
				"entry_id": "exe.rattildus",
				"seen": true,
				"defeated": true
			}
		}
	}
	CampaignState.campaign_changed.emit(&"encyclopedia")

	var preserved_day: int = TimeManager.days_passed
	var preserved_period: int = int(TimeManager.current_period)
	var preserved_block: int = TimeManager.current_action_block
	var preserved_world: Dictionary = CampaignState.world_state.to_save_data()

	var combat_errors: PackedStringArray = _resolve_definitive_turd_defeat()
	_check(
		combat_errors.is_empty(),
		"Definitive TURD defeat failed: %s" % combat_errors
	)
	var metadata: Dictionary = CombatManager.get_result_metadata()
	var legacy_site_id: String = str(
		metadata.get("legacy_site_id", "")
	).strip_edges()
	_check(
		bool(metadata.get("operator_lost", false))
		and bool(metadata.get("irreversible", false))
		and str(metadata.get("archived_operator_id", "")) == "first_operator"
		and not legacy_site_id.is_empty(),
		"Combat resolution did not return complete Operator Loss metadata."
	)
	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.OPERATOR_LOSS
		and CampaignState.operator.is_empty()
		and CampaignState.partner.is_empty(),
		"Operator Loss did not archive the active Operator and TURD."
	)
	_check(
		CampaignState.tendencies.get_total() == 0
		and CampaignState.money == 0
		and CampaignState.inventory.entries.is_empty()
		and CampaignState.known_module_ids.is_empty()
		and CampaignState.social_state.is_empty()
		and CampaignState.encyclopedia_state.is_empty(),
		"Operator-scoped progression was not cleared for succession."
	)
	_check(
		TimeManager.days_passed == preserved_day
		and int(TimeManager.current_period) == preserved_period
		and TimeManager.current_action_block == preserved_block,
		"Operator Loss changed the campaign clock or countdown position."
	)
	_check(
		CampaignState.world_state.get_flag("world_survives_operator_loss")
		and CampaignState.has_completed_incident("akihabara_aquarium_relay")
		and CampaignState.completed_lead_ids.has("aquarium_signal")
		and CampaignState.installed_app_ids.has("navigator"),
		"Operator Loss erased campaign/world progression that belongs to the network."
	)
	_check(
		CampaignState.world_state.get_infestation("akihabara") == 4,
		"Partner Loss +1 and Operator Loss +3 were not applied exactly once."
	)
	_check(
		CampaignState.operator_history.size() == 1,
		"Archived Operator history did not receive exactly one succession record."
	)

	var legacy_site: LegacySiteStateData = OperatorLossService.get_legacy_site(
		legacy_site_id
	)
	_check(legacy_site != null, "Operator Loss did not create a valid Legacy Site.")

	if legacy_site != null:
		var recovered_inventory := InventoryStateData.new()
		recovered_inventory.load_save_data(
			legacy_site.recoverable_data.get("inventory", {}) as Dictionary
		)
		var recovered_modules: Array = legacy_site.recoverable_data.get(
			"known_module_ids",
			[]
		) as Array
		_check(
			legacy_site.operator_id == "first_operator"
			and legacy_site.location_id == "akihabara"
			and legacy_site.game_day == preserved_day
			and int(legacy_site.recoverable_data.get("money", 0)) == 777
			and recovered_inventory.get_item_count("healing_patch") == 4
			and recovered_modules.has("heavy_attack")
			and not (
				legacy_site.recoverable_data.get(
					"encyclopedia_state",
					{}
				) as Dictionary
			).is_empty(),
			"Legacy Site did not seal the recoverable material data."
		)

	_check(
		CombatManager.finalize_resolved_encounter(),
		"Operator Loss combat did not finalize cleanly."
	)
	await _test_legacy_site_projection(legacy_site_id)

	var successor_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile("successor_operator", "Successor"),
		_make_appearance("successor"),
		{"valour": 3, "logic": 5, "sync": 4, "self": 3}
	)
	_check(
		successor_errors.is_empty(),
		"Could not register the successor Operator: %s" % successor_errors
	)
	_check(
		CampaignState.campaign_phase
		== CampaignState.CampaignPhase.OPERATOR_CREATION
		and CampaignState.operator.operator_id == "successor_operator"
		and CampaignState.partner.is_empty(),
		"Successor registration did not enter the starter-selection boundary."
	)
	_check(
		TimeManager.days_passed == preserved_day
		and CampaignState.world_state.to_save_data() == preserved_world.merged(
			{
				"location_infestation": CampaignState.world_state.location_infestation.duplicate(true),
				"persistent_objects": CampaignState.world_state.persistent_objects.duplicate(true)
			},
			true
		),
		"Successor registration reset the campaign clock or world."
	)
	_check(
		CampaignState.get_affinity("ganbarekun") == 0
		and not CampaignState.known_module_ids.has("heavy_attack")
		and CampaignState.inventory.get_item_count("healing_patch") == 0,
		"The successor inherited personal or material progress before Legacy Recovery."
	)

	var successor_starter_errors: PackedStringArray = (
		APKProgressionService.select_starter(
			"novire_init",
			"Second Novi",
			1,
			0
		)
	)
	_check(
		successor_starter_errors.is_empty(),
		"Could not select the successor starter: %s"
		% successor_starter_errors
	)
	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.MAIN_CAMPAIGN
		and CampaignState.partner.apk_id == "novire_init"
		and CampaignState.operator_history.size() == 1
		and OperatorLossService.get_legacy_site(legacy_site_id) != null,
		"Starter selection did not complete succession in the same campaign."
	)

	await get_tree().process_frame
	await get_tree().process_frame
	_check(
		SaveManager.save_checkpoint(&"phase14.operator_succession", true),
		"Could not save the completed Operator succession."
	)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	CombatManager.reset_encounter()
	var load_errors: PackedStringArray = SaveManager.load_campaign(CAMPAIGN_ID)
	_check(
		load_errors.is_empty(),
		"Could not reload the succession campaign: %s" % load_errors
	)
	_check(
		CampaignState.campaign_phase == CampaignState.CampaignPhase.MAIN_CAMPAIGN
		and CampaignState.operator.operator_id == "successor_operator"
		and CampaignState.partner.apk_id == "novire_init"
		and CampaignState.operator_history.size() == 1
		and TimeManager.days_passed == preserved_day
		and CampaignState.world_state.get_infestation("akihabara") == 4
		and OperatorLossService.get_legacy_site(legacy_site_id) != null
		and CampaignState.get_affinity("ganbarekun") == 0
		and not CampaignState.known_module_ids.has("heavy_attack"),
		"Save/reload did not preserve the successor/world separation."
	)

	_finish_test()


func _resolve_definitive_turd_defeat() -> PackedStringArray:
	var errors := PackedStringArray()

	if not CombatManager.load_encounter(TEST_ENCOUNTER):
		errors.append("CombatManager rejected the definitive TURD encounter.")
		return errors

	var player: Variant = CombatManager.get_player_actor()
	var enemy: Variant = _first_actor(CombatManager.enemy_team)

	if player is not Dictionary or enemy is not Dictionary:
		errors.append("The definitive TURD encounter did not create both actors.")
		return errors

	for slot_index: int in range(4):
		(enemy as Dictionary)["modules"][slot_index] = IDLE_MODULE

	(player as Dictionary)["hp"] = 0.0
	CombatManager.rebuild_timeline()
	CombatManager.execute_cycle(false)

	if not CombatManager.is_awaiting_resolution() \
		or CombatManager.get_pending_outcome() != CombatResult.Outcome.DEFEAT:
		errors.append("Destroyed TURD did not reach the DEFEAT resolution boundary.")
		return errors

	errors.append_array(
		CombatManager.resolve_encounter(CombatResult.Outcome.DEFEAT)
	)
	return errors


func _test_legacy_site_projection(legacy_site_id: String) -> void:
	var area := AKIHABARA_AREA_SCENE.instantiate()
	add_child(area)
	await get_tree().process_frame
	var controller := area.get_node_or_null(
		"PopulationController"
	) as LocalAreaPopulationController
	var location: MapLocation = ContentRegistry.get_location("akihabara")
	_check(
		controller != null and location != null,
		"Akihabara Legacy Site projection fixture is incomplete."
	)

	if controller != null and location != null:
		_check(
			controller.populate(location),
			"Akihabara population rejected the preserved world state."
		)
		var actor: LocalAreaInteractable = controller.get_population_actor(
			legacy_site_id
		)
		_check(
			actor is LocalAreaLegacySiteActor,
			"The broken KubuOS Handtop did not appear in the loss location."
		)

	area.queue_free()
	await get_tree().process_frame


func _make_profile(username: String, nickname: String) -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = nickname
	profile.last_name = "Operator"
	profile.nickname = nickname
	profile.username = username
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance(prefix: String) -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "%s_body" % prefix
	appearance.face_id = "%s_face" % prefix
	appearance.eye_id = "%s_eyes" % prefix
	appearance.outer_layer_id = "%s_outer" % prefix
	appearance.middle_layer_id = "%s_middle" % prefix
	appearance.lower_layer_id = "%s_lower" % prefix
	appearance.hat_id = "%s_hat" % prefix
	appearance.facial_accessory_id = "%s_accessory" % prefix
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
		print("OPERATOR_LOSS_SUCCESSION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print(
		"OPERATOR_LOSS_SUCCESSION_TEST: FAIL (%d)"
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
