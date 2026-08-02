extends Node


var _failures := PackedStringArray()
var _test_root: String


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_root = "user://null_network/tests/save_manager_%d" % Time.get_ticks_usec()
	SaveManager.configure_storage_root(_test_root)

	_test_provider_contract()
	_test_safe_mode_round_trip_and_history()
	_test_atomic_backup_recovery()
	_test_commit_mode_policy()
	_test_future_version_rejection()

	CampaignState.reset_campaign()
	AppSessionStore.reset_save_data()
	SaveManager.configure_storage_root(SaveConstants.DEFAULT_STORAGE_ROOT)
	_remove_directory_recursive(_test_root)

	if _failures.is_empty():
		print("SAVE_MANAGER_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("SAVE_MANAGER_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)


func _test_provider_contract() -> void:
	var invalid_provider := Node.new()
	var errors: PackedStringArray = SaveManager.register_save_section(
		invalid_provider
	)
	_check(
		errors.size() == 4,
		"SaveSectionRegistry accepted a provider without the four required methods."
	)
	invalid_provider.free()


func _test_safe_mode_round_trip_and_history() -> void:
	var errors: PackedStringArray = SaveManager.create_campaign(
		"phase_3_safe",
		CampaignState.SaveMode.SAFE,
		"Phase 3 SAFE"
	)
	_check(errors.is_empty(), "SAFE campaign creation failed: %s" % errors)

	CampaignState.operator.operator_id = "operator_safe"
	CampaignState.operator.display_name = "SAFE TESTER"
	CampaignState.install_app("browser")
	GameState.mark_thread_as_read("welcome_new_players", "visible:v1")
	GameState.register_browser_visit("home", "Home")
	AppSessionStore.save_app_state("browser", {
		"version": 1,
		"current_tab_index": 0,
		"tabs": [{"url": "home"}]
	})
	TimeManager.days_passed = 3
	TimeManager.current_period = TimeManager.TimePeriod.NIGHT
	TimeManager.current_action_block = 7

	_check(
		SaveManager.save_checkpoint(&"after_travel"),
		"SAFE after_travel checkpoint failed."
	)
	var checkpoints: Array[Dictionary] = SaveManager.list_checkpoints(
		"phase_3_safe"
	)
	var travel_checkpoint_id: String = _find_checkpoint_file_id(
		checkpoints,
		"after_travel"
	)
	_check(
		not travel_checkpoint_id.is_empty(),
		"SAFE mode did not expose the historical after_travel checkpoint."
	)

	CampaignState.operator.display_name = "MUTATED"
	GameState.mark_thread_as_unread("welcome_new_players")
	AppSessionStore.clear_all_app_states()
	TimeManager.days_passed = 9
	TimeManager.current_period = TimeManager.TimePeriod.DAY
	TimeManager.current_action_block = 1
	_check(
		SaveManager.save_checkpoint(&"after_cycle"),
		"SAFE after_cycle checkpoint failed."
	)

	errors = SaveManager.load_campaign(
		"phase_3_safe",
		travel_checkpoint_id
	)
	_check(errors.is_empty(), "Historical SAFE load failed: %s" % errors)
	_check(
		CampaignState.operator.display_name == "SAFE TESTER"
		and GameState.has_read_thread("welcome_new_players")
		and AppSessionStore.has_app_state("browser")
		and TimeManager.days_passed == 3
		and TimeManager.current_period == TimeManager.TimePeriod.NIGHT
		and TimeManager.current_action_block == 7,
		"SAFE historical checkpoint did not restore all aggregate sections."
	)

	var live_result: Dictionary = SaveManager._read_document(
		SaveConstants.live_path(_test_root, "phase_3_safe")
	)
	_check(
		bool(live_result.get("ok", false)),
		"The current SAFE live document is not readable."
	)

	if bool(live_result.get("ok", false)):
		var document: Dictionary = live_result.get("document", {})
		_check(
			_is_plain_save_value(document),
			"Aggregate save contains a Node, Resource or unsupported value."
		)
		var sections: Dictionary = document.get("sections", {})

		for section_id: StringName in SaveConstants.REQUIRED_CORE_SECTIONS:
			_check(
				sections.has(str(section_id)),
				"Aggregate save is missing required section '%s'." % section_id
			)


func _test_atomic_backup_recovery() -> void:
	CampaignState.set_money(100)
	_check(
		SaveManager.save_checkpoint(&"backup_source"),
		"Could not create the backup source save."
	)
	CampaignState.set_money(200)
	_check(
		SaveManager.save_checkpoint(&"live_after_backup"),
		"Could not rotate the technical backup."
	)

	var live_path: String = SaveConstants.live_path(
		_test_root,
		"phase_3_safe"
	)
	var corrupt_file := FileAccess.open(live_path, FileAccess.WRITE)

	if corrupt_file == null:
		_check(false, "Could not simulate an interrupted live replacement.")
		return

	corrupt_file.store_string("{ interrupted replacement")
	corrupt_file.close()
	CampaignState.set_money(999)

	var errors: PackedStringArray = SaveManager.load_campaign("phase_3_safe")
	_check(errors.is_empty(), "Technical backup recovery failed: %s" % errors)
	_check(
		CampaignState.money == 100,
		"Backup recovery did not restore the last valid pre-replacement state."
	)
	_check(
		bool(SaveManager._read_document(live_path).get("ok", false)),
		"Backup recovery did not repair the official live file."
	)


func _test_commit_mode_policy() -> void:
	var errors: PackedStringArray = SaveManager.create_campaign(
		"phase_3_commit",
		CampaignState.SaveMode.COMMIT,
		"Phase 3 COMMIT"
	)
	_check(errors.is_empty(), "COMMIT campaign creation failed: %s" % errors)

	CampaignState.operator.operator_id = "operator_commit"
	CampaignState.set_money(10)
	_check(
		SaveManager.save_checkpoint(&"irreversible_choice", true),
		"COMMIT irreversible checkpoint failed."
	)
	CampaignState.set_money(20)
	_check(
		SaveManager.save_checkpoint(&"day_advanced", true),
		"COMMIT live record update failed."
	)
	_check(
		SaveManager.list_checkpoints("phase_3_commit").is_empty(),
		"COMMIT mode exposed historical checkpoints."
	)
	_check(
		not SaveManager.manual_save(),
		"COMMIT mode accepted a manual save."
	)

	errors = SaveManager.load_campaign(
		"phase_3_commit",
		"forbidden_history"
	)
	_check(
		not errors.is_empty(),
		"COMMIT mode accepted an earlier checkpoint selection."
	)
	errors = SaveManager.load_campaign("phase_3_commit")
	_check(
		errors.is_empty() and CampaignState.money == 20,
		"COMMIT mode did not restore its single living record."
	)


func _test_future_version_rejection() -> void:
	var future_document: Dictionary = {
		"save_version": SaveConstants.SAVE_VERSION + 1,
		"metadata": {
			"campaign_id": "future",
			"save_mode": int(CampaignState.SaveMode.SAFE)
		},
		"sections": {}
	}
	var result: Dictionary = SaveMigrator.new().migrate_document(
		future_document
	)
	_check(
		not bool(result.get("ok", false)),
		"SaveMigrator accepted a save from an unsupported future version."
	)


func _find_checkpoint_file_id(
	checkpoints: Array[Dictionary],
	checkpoint_name: String
) -> String:
	for metadata: Dictionary in checkpoints:
		if str(metadata.get("last_checkpoint", "")) == checkpoint_name:
			return str(metadata.get("checkpoint_file_id", ""))

	return ""


func _is_plain_save_value(value: Variant) -> bool:
	if value is Object:
		return false

	if value is Dictionary:
		for key: Variant in value:
			if not _is_plain_save_value(key) \
				or not _is_plain_save_value(value[key]):
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


func _remove_directory_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if directory == null:
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()

	while not entry_name.is_empty():
		var entry_path: String = "%s/%s" % [path, entry_name]

		if directory.current_is_dir():
			_remove_directory_recursive(entry_path)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(entry_path))

		entry_name = directory.get_next()

	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
