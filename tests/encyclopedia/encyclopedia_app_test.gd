extends Node


const ENCYCLOPEDIA_SCENE: PackedScene = preload(
	"res://apps/encyclopedia/encyclopedia_app.tscn"
)
const TEST_ENCOUNTER: CombatEncounter = preload(
	"res://data/content/combat/1v1.tres"
)
const CAMPAIGN_ID: String = "phase13_encyclopedia"

var _failures := PackedStringArray()
var _test_root: String = ""


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_root = "user://null_network/tests/encyclopedia_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)
	UniversalNotifications.clear_history()
	var catalog_errors: PackedStringArray = ContentRegistry.reset_to_default_catalog()
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected Encyclopedia content: %s" % catalog_errors
	)
	_check(
		EncyclopediaService.get_entry("exe.rattildus") != null,
		"Rattildus Encyclopedia entry is not registered."
	)

	var create_errors: PackedStringArray = SaveManager.create_campaign(
		CAMPAIGN_ID,
		CampaignState.SaveMode.SAFE,
		"Phase 13 Encyclopedia"
	)
	_check(
		create_errors.is_empty(),
		"Could not create Encyclopedia fixture campaign: %s" % create_errors
	)
	var registration_errors: PackedStringArray = OperatorService.register_operator(
		_make_profile(),
		_make_appearance(),
		{"valour": 4, "logic": 4, "sync": 4, "self": 3}
	)
	_check(
		registration_errors.is_empty(),
		"Could not register Encyclopedia fixture Operator: %s"
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
		"Could not select Encyclopedia fixture starter: %s" % starter_errors
	)
	await _wait_frames(8)
	_check(
		not CampaignState.has_installed_app("encyclopedia"),
		"Encyclopedia installed before any confirmed record existed."
	)

	CampaignState.set_current_location("akihabara")
	_test_combat_observation()
	await _wait_frames(10)
	_check(
		CampaignState.has_installed_app("encyclopedia"),
		"First combat record did not auto-install Encyclopedia."
	)
	var combat_record: EncyclopediaRecordData = EncyclopediaService.get_record(
		"exe.rattildus"
	)
	_check(
		combat_record != null
		and combat_record.seen
		and combat_record.defeated
		and combat_record.known_location_ids.has("akihabara"),
		"Combat did not persist seen, defeated and known location separately."
	)

	_test_typed_milestones()
	_test_legacy_migration()

	var app := ENCYCLOPEDIA_SCENE.instantiate() as EncyclopediaApp
	_check(
		app != null,
		"Encyclopedia scene did not instantiate EncyclopediaApp."
	)

	if app == null:
		_finish_test()
		return

	add_child(app)
	app.size = Vector2(820, 560)
	await _wait_frames(8)
	_assert_app_projection(app, "initial")

	_check(
		SaveManager.save_checkpoint(&"phase13.encyclopedia", true),
		"Could not save Encyclopedia checkpoint."
	)
	app.queue_free()
	await _wait_frames(3)
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	CombatManager.reset_encounter()
	var load_errors: PackedStringArray = SaveManager.load_campaign(CAMPAIGN_ID)
	_check(
		load_errors.is_empty(),
		"Encyclopedia campaign reload failed: %s" % load_errors
	)
	await _wait_frames(8)
	_check(
		CampaignState.has_installed_app("encyclopedia"),
		"Encyclopedia installation did not survive reload."
	)
	var restored: EncyclopediaRecordData = EncyclopediaService.get_record(
		"exe.rattildus"
	)
	_check(
		restored != null
		and restored.scanned
		and restored.purged
		and restored.purified
		and restored.tamed
		and restored.lost
		and restored.known_module_ids.has("heavy_attack")
		and restored.known_location_ids.has("akihabara")
		and restored.known_evolution_ids.has("novire_valour"),
		"Typed Encyclopedia milestones or known IDs did not survive reload."
	)

	var reopened := ENCYCLOPEDIA_SCENE.instantiate() as EncyclopediaApp
	_check(reopened != null, "Encyclopedia could not reopen after reload.")

	if reopened != null:
		add_child(reopened)
		reopened.size = Vector2(820, 560)
		await _wait_frames(8)
		_assert_app_projection(reopened, "restored")
		reopened.queue_free()

	await _wait_frames(2)
	_finish_test()


func _test_combat_observation() -> void:
	_check(
		CombatManager.load_encounter(TEST_ENCOUNTER),
		"CombatManager rejected the Encyclopedia fixture encounter."
	)
	var player: Variant = CombatManager.get_player_actor()
	var enemy: Variant = _first_actor(CombatManager.enemy_team)

	if player is not Dictionary or enemy is not Dictionary:
		_failures.append("Encyclopedia combat fixture did not create both actors.")
		CombatManager.reset_encounter()
		return

	(enemy as Dictionary)["hp"] = 0.0
	(enemy as Dictionary)["defeated"] = true
	var result: Dictionary = CombatResolutionService.resolve(
		CombatResult.Outcome.VICTORY,
		TEST_ENCOUNTER,
		player as Dictionary,
		[enemy as Dictionary],
		[],
		CombatTendencyLog.new()
	)
	_check(
		(result.get("errors", PackedStringArray()) as PackedStringArray).is_empty(),
		"Combat Encyclopedia observation failed: %s"
		% result.get("errors", PackedStringArray())
	)
	CombatManager.reset_encounter()


func _test_typed_milestones() -> void:
	_check(
		EncyclopediaService.record_observation(
			"exe.rattildus",
			{
				"scanned": true,
				"known_modules": ["heavy_attack"]
			},
			"test.scan"
		),
		"Typed SCAN observation was rejected."
	)
	_check(
		EncyclopediaService.record_observation(
			"exe.rattildus",
			{"purged": true},
			"test.purge"
		),
		"Typed PURGE observation was rejected."
	)
	_check(
		EncyclopediaService.record_observation(
			"exe.rattildus",
			{"purified": true},
			"test.purify"
		),
		"Typed PURIFY observation was rejected."
	)
	_check(
		EncyclopediaService.record_observation(
			"exe.rattildus",
			{
				"tamed": true,
				"known_evolutions": ["novire_valour"]
			},
			"test.tame"
		),
		"Typed TAME observation was rejected."
	)
	_check(
		EncyclopediaService.mark_lost("exe.rattildus", "test.loss"),
		"Typed loss observation was rejected."
	)
	var before_duplicate: EncyclopediaRecordData = EncyclopediaService.get_record(
		"exe.rattildus"
	)
	var encounter_count_before: int = before_duplicate.encounter_count
	_check(
		not EncyclopediaService.record_observation(
			"exe.rattildus",
			{"purged": true},
			"test.purge"
		),
		"Duplicate observation ID was applied twice."
	)
	var after_duplicate: EncyclopediaRecordData = EncyclopediaService.get_record(
		"exe.rattildus"
	)
	_check(
		after_duplicate.encounter_count == encounter_count_before,
		"Duplicate observation changed Encyclopedia counters."
	)


func _test_legacy_migration() -> void:
	var legacy := EncyclopediaStateData.new()
	legacy.load_save_data({
		"entries": {
			"exe.rattildus": {
				"discovered": true,
				"encountered": true,
				"scanned": true,
				"defeated": true
			}
		}
	})
	var migrated: EncyclopediaRecordData = legacy.get_record("exe.rattildus")
	var normalized: Dictionary = legacy.to_save_data()
	_check(
		migrated != null
		and migrated.seen
		and migrated.scanned
		and migrated.defeated
		and int(normalized.get("version", 0)) == EncyclopediaStateData.SAVE_VERSION,
		"Legacy discovered/encountered Encyclopedia data did not migrate."
	)


func _assert_app_projection(app: EncyclopediaApp, boundary: String) -> void:
	var snapshot: Dictionary = EncyclopediaProjectionService.build_entry_snapshot(
		"exe.rattildus"
	)
	var milestones: Array = snapshot.get("milestones", []) as Array
	var known_modules: Array = snapshot.get("known_modules", []) as Array
	var known_locations: Array = snapshot.get("known_locations", []) as Array
	var known_evolutions: Array = snapshot.get("known_evolutions", []) as Array
	_check(
		app.get_entry_count() == 1
		and app.get_selected_entry_id() == "exe.rattildus",
		"%s Encyclopedia did not list and select Rattildus."
		% boundary.capitalize()
	)
	_check(
		app.get_rendered_milestone_count() == 7
		and milestones.size() == 7,
		"%s Encyclopedia did not render seven independent milestones."
		% boundary.capitalize()
	)
	_check(
		not known_modules.is_empty()
		and not known_locations.is_empty()
		and not known_evolutions.is_empty(),
		"%s Encyclopedia did not resolve known Modules, locations and evolutions."
		% boundary.capitalize()
	)


func _make_profile() -> OperatorProfileData:
	var profile := OperatorProfileData.new()
	profile.first_name = "Gyu"
	profile.last_name = "Encyclopedia"
	profile.nickname = "Operator"
	profile.username = "encyclopedia_operator"
	profile.server_id = "tokyo_japan"
	profile.occupation_id = "neet"
	profile.gender = "other"
	profile.pronoun_set_id = "they_them"
	profile.avatar_id = "avatar_01"
	return profile


func _make_appearance() -> AppearanceData:
	var appearance := AppearanceData.new()
	appearance.body_type_id = "body_encyclopedia"
	appearance.face_id = "face_encyclopedia"
	appearance.eye_id = "eyes_encyclopedia"
	appearance.outer_layer_id = "outer_encyclopedia"
	appearance.middle_layer_id = "middle_encyclopedia"
	appearance.lower_layer_id = "lower_encyclopedia"
	appearance.hat_id = "hat_encyclopedia"
	appearance.facial_accessory_id = "accessory_encyclopedia"
	return appearance


func _first_actor(team: Array) -> Variant:
	for actor: Variant in team:
		if actor is Dictionary:
			return actor

	return null


func _wait_frames(count: int) -> void:
	for _index: int in range(count):
		await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	UniversalNotifications.clear_history()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("ENCYCLOPEDIA_APP_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("ENCYCLOPEDIA_APP_TEST: FAIL (%d)" % _failures.size())
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
