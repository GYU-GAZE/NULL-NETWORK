extends Node


signal save_started(campaign_id: String, checkpoint: StringName)
signal save_completed(
	campaign_id: String,
	checkpoint: StringName,
	checkpoint_file_id: String
)
signal save_failed(campaign_id: String, errors: PackedStringArray)
signal campaign_loaded(campaign_id: String, recovered_from_backup: bool)
signal campaign_load_failed(campaign_id: String, errors: PackedStringArray)


var storage_root: String = SaveConstants.DEFAULT_STORAGE_ROOT

var _registry := SaveSectionRegistry.new()
var _migrator := SaveMigrator.new()
var _active_metadata: Dictionary = {}
var _checkpoint_sequence: int = 0
var _save_in_progress: bool = false
var _is_loading: bool = false
var _queued_checkpoint: StringName = &""
var _queued_irreversible: bool = false
var _last_observed_day: int = 1
var _last_observed_period: int = 0


func _ready() -> void:
	register_save_section(TimeManager)
	register_save_section(CampaignState)
	register_save_section(GameState)
	register_save_section(AppSessionStore)
	register_save_section(CombatManager)
	_last_observed_day = TimeManager.days_passed
	_last_observed_period = int(TimeManager.current_period)

	if not ActivityManager.activity_started.is_connected(_on_activity_started):
		ActivityManager.activity_started.connect(_on_activity_started)

	if not ActivityManager.activity_completed.is_connected(
		_on_activity_completed
	):
		ActivityManager.activity_completed.connect(_on_activity_completed)

	if not CombatManager.cycle_completed.is_connected(_on_combat_cycle_completed):
		CombatManager.cycle_completed.connect(_on_combat_cycle_completed)

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)


func register_save_section(provider: Object) -> PackedStringArray:
	return _registry.register_provider(provider)


func unregister_save_section(provider: Object) -> void:
	_registry.unregister_provider(provider)


func configure_storage_root(new_root: String) -> bool:
	var clean_root: String = new_root.strip_edges().trim_suffix("/")

	if clean_root.is_empty() or _save_in_progress:
		return false

	storage_root = clean_root
	return true


func create_campaign(
	campaign_id: String,
	save_mode: CampaignState.SaveMode,
	display_name: String = ""
) -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = SaveConstants.sanitize_identifier(campaign_id)

	if clean_id.is_empty():
		errors.append("Campaign ID is empty or contains no valid characters.")
		return errors

	if save_mode not in [
		CampaignState.SaveMode.SAFE,
		CampaignState.SaveMode.COMMIT
	]:
		errors.append("A campaign requires SAFE or COMMIT save mode.")
		return errors

	if campaign_exists(clean_id):
		errors.append("Campaign '%s' already exists." % clean_id)
		return errors

	_registry.reset_registered_providers()
	_registry.clear_pending_sections()

	if not CampaignState.create_campaign(clean_id, save_mode):
		errors.append("CampaignState rejected campaign creation.")
		return errors

	var created_at: String = _timestamp_now()
	_active_metadata = {
		"campaign_id": clean_id,
		"display_name": (
			display_name.strip_edges()
			if not display_name.strip_edges().is_empty()
			else clean_id
		),
		"save_mode": int(save_mode),
		"created_at": created_at,
		"updated_at": created_at,
		"last_checkpoint": str(
			SaveConstants.CHECKPOINT_CAMPAIGN_CREATED
		),
		"last_checkpoint_file_id": "",
		"checkpoint_order": 0
	}

	if not _ensure_campaign_directories(clean_id):
		errors.append("Could not create the campaign save directories.")
		return errors

	if not save_checkpoint(
		SaveConstants.CHECKPOINT_CAMPAIGN_CREATED,
		true
	):
		errors.append_array(get_last_errors())

	return errors


func save_checkpoint(
	checkpoint: StringName,
	irreversible: bool = false,
	manual: bool = false
) -> bool:
	var errors := PackedStringArray()

	if _save_in_progress:
		errors.append("A save operation is already in progress.")
		_fail_save(errors)
		return false

	errors.append_array(_registry.validate_save_readiness())

	if not errors.is_empty():
		_fail_save(errors)
		return false

	if not CampaignState.has_campaign():
		errors.append("Cannot save without an active campaign.")
		_fail_save(errors)
		return false

	if manual and CampaignState.save_mode != CampaignState.SaveMode.SAFE:
		errors.append("Manual saves are available only in SAFE MODE.")
		_fail_save(errors)
		return false

	var clean_checkpoint := StringName(str(checkpoint).strip_edges())

	if clean_checkpoint.is_empty():
		errors.append("Checkpoint ID cannot be empty.")
		_fail_save(errors)
		return false

	_save_in_progress = true
	save_started.emit(CampaignState.campaign_id, clean_checkpoint)
	_checkpoint_sequence += 1

	var checkpoint_file_id: String = _make_checkpoint_file_id(
		clean_checkpoint
	)
	var metadata: Dictionary = _active_metadata.duplicate(true)
	metadata["campaign_id"] = CampaignState.campaign_id
	metadata["save_mode"] = int(CampaignState.save_mode)
	metadata["updated_at"] = _timestamp_now()
	metadata["last_checkpoint"] = str(clean_checkpoint)
	metadata["last_checkpoint_file_id"] = checkpoint_file_id
	metadata["checkpoint_order"] = int(
		metadata.get("checkpoint_order", 0)
	) + 1
	metadata["irreversible"] = irreversible
	metadata["manual"] = manual

	var document: Dictionary = _build_document(metadata)
	errors.append_array(validate_document(document))

	if not errors.is_empty():
		_save_in_progress = false
		_fail_save(errors)
		return false

	var live_path: String = SaveConstants.live_path(
		storage_root,
		CampaignState.campaign_id
	)
	var backup_path: String = SaveConstants.technical_backup_path(
		storage_root,
		CampaignState.campaign_id
	)

	if not _write_document_atomically(document, live_path, backup_path):
		errors.append("Atomic replacement of the live save failed.")
		_save_in_progress = false
		_fail_save(errors)
		return false

	if CampaignState.save_mode == CampaignState.SaveMode.SAFE:
		var checkpoint_path: String = SaveConstants.checkpoint_path(
			storage_root,
			CampaignState.campaign_id,
			checkpoint_file_id
		)

		if not _write_new_document(document, checkpoint_path):
			errors.append(
				"The live save succeeded, but its SAFE checkpoint copy failed."
			)

	_active_metadata = metadata
	_save_in_progress = false

	if not errors.is_empty():
		_fail_save(errors)
		return false

	save_completed.emit(
		CampaignState.campaign_id,
		clean_checkpoint,
		checkpoint_file_id
	)
	return true


func manual_save() -> bool:
	return save_checkpoint(SaveConstants.CHECKPOINT_MANUAL, false, true)


func load_campaign(
	campaign_id: String,
	checkpoint_file_id: String = ""
) -> PackedStringArray:
	var errors := PackedStringArray()
	var clean_id: String = SaveConstants.sanitize_identifier(campaign_id)

	if clean_id.is_empty():
		errors.append("Campaign ID is invalid.")
		_fail_load(clean_id, errors)
		return errors

	var live_result: Dictionary = _read_live_document(clean_id)

	if not bool(live_result.get("ok", false)):
		errors.append_array(live_result.get("errors", PackedStringArray()))
		_fail_load(clean_id, errors)
		return errors

	var live_document: Dictionary = live_result.get("document", {})
	var live_metadata: Dictionary = live_document.get("metadata", {})
	var save_mode: int = int(
		live_metadata.get("save_mode", CampaignState.SaveMode.UNSET)
	)
	var requested_checkpoint: String = checkpoint_file_id.strip_edges()
	var document: Dictionary = live_document

	if not requested_checkpoint.is_empty():
		if save_mode != CampaignState.SaveMode.SAFE:
			errors.append("COMMIT MODE cannot load historical checkpoints.")
			_fail_load(clean_id, errors)
			return errors

		var checkpoint_path: String = SaveConstants.checkpoint_path(
			storage_root,
			clean_id,
			requested_checkpoint
		)
		var checkpoint_result: Dictionary = _read_document(checkpoint_path)

		if not bool(checkpoint_result.get("ok", false)):
			errors.append_array(
				checkpoint_result.get("errors", PackedStringArray())
			)
			_fail_load(clean_id, errors)
			return errors

		document = checkpoint_result.get("document", {})

	_is_loading = true
	errors.append_array(_restore_document(document))
	_is_loading = false

	if not errors.is_empty():
		_fail_load(clean_id, errors)
		return errors

	_active_metadata = (document.get("metadata", {}) as Dictionary).duplicate(true)
	_checkpoint_sequence = int(
		_active_metadata.get("checkpoint_order", 0)
	)
	_last_observed_day = TimeManager.days_passed
	_last_observed_period = int(TimeManager.current_period)
	campaign_loaded.emit(
		clean_id,
		bool(live_result.get("recovered_from_backup", false))
	)
	return errors


func campaign_exists(campaign_id: String) -> bool:
	var clean_id: String = SaveConstants.sanitize_identifier(campaign_id)

	if clean_id.is_empty():
		return false

	return FileAccess.file_exists(
		SaveConstants.live_path(storage_root, clean_id)
	) or FileAccess.file_exists(
		SaveConstants.technical_backup_path(storage_root, clean_id)
	)


func list_campaigns() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var root := DirAccess.open(storage_root)

	if root == null:
		return result

	root.list_dir_begin()
	var entry_name: String = root.get_next()

	while not entry_name.is_empty():
		if root.current_is_dir() and not entry_name.begins_with("."):
			var read_result: Dictionary = _read_live_document(entry_name, false)

			if bool(read_result.get("ok", false)):
				var document: Dictionary = read_result.get("document", {})
				var metadata: Dictionary = document.get("metadata", {})
				result.append(metadata.duplicate(true))

		entry_name = root.get_next()

	root.list_dir_end()
	result.sort_custom(_sort_metadata_newest_first)
	return result


func list_checkpoints(campaign_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var clean_id: String = SaveConstants.sanitize_identifier(campaign_id)
	var directory_path: String = SaveConstants.checkpoints_directory(
		storage_root,
		clean_id
	)
	var directory := DirAccess.open(directory_path)

	if directory == null:
		return result

	directory.list_dir_begin()
	var file_name: String = directory.get_next()

	while not file_name.is_empty():
		if not directory.current_is_dir() \
			and file_name.ends_with(SaveConstants.CHECKPOINT_FILE_EXTENSION):
			var read_result: Dictionary = _read_document(
				"%s/%s" % [directory_path, file_name]
			)

			if bool(read_result.get("ok", false)):
				var document: Dictionary = read_result.get("document", {})
				var metadata: Dictionary = (
					document.get("metadata", {}) as Dictionary
				).duplicate(true)
				metadata["checkpoint_file_id"] = file_name.trim_suffix(
					SaveConstants.CHECKPOINT_FILE_EXTENSION
				)
				result.append(metadata)

		file_name = directory.get_next()

	directory.list_dir_end()
	result.sort_custom(_sort_metadata_newest_first)
	return result


func validate_document(document: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if not _is_plain_save_value(document):
		errors.append("Save document contains a runtime Object or unsupported value.")
		return errors

	var save_version: int = int(document.get("save_version", -1))

	if save_version != SaveConstants.SAVE_VERSION:
		errors.append("Save document version is not current.")

	var metadata: Variant = document.get("metadata", null)
	var sections: Variant = document.get("sections", null)

	if metadata is not Dictionary:
		errors.append("Save document has no valid metadata Dictionary.")
	else:
		var metadata_dictionary := metadata as Dictionary
		var metadata_campaign_id: String = SaveConstants.sanitize_identifier(
			str(metadata_dictionary.get("campaign_id", ""))
		)
		var metadata_save_mode: int = int(
			metadata_dictionary.get(
				"save_mode",
				CampaignState.SaveMode.UNSET
			)
		)

		if metadata_campaign_id.is_empty():
			errors.append("Save metadata has an invalid campaign_id.")

		if metadata_save_mode not in [
			CampaignState.SaveMode.SAFE,
			CampaignState.SaveMode.COMMIT
		]:
			errors.append("Save metadata has an invalid save_mode.")

	if sections is not Dictionary:
		errors.append("Save document has no valid sections Dictionary.")
		return errors

	var section_dictionary := sections as Dictionary

	for required_section: StringName in SaveConstants.REQUIRED_CORE_SECTIONS:
		if not section_dictionary.has(str(required_section)):
			errors.append(
				"Save document is missing required section '%s'."
				% required_section
			)

	errors.append_array(_registry.validate_sections(section_dictionary))
	return errors


func get_active_metadata() -> Dictionary:
	return _active_metadata.duplicate(true)


func get_last_errors() -> PackedStringArray:
	var value: Variant = get_meta(&"last_errors", PackedStringArray())

	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()

	return PackedStringArray()


func request_checkpoint(
	checkpoint: StringName,
	irreversible: bool = false
) -> void:
	if _is_loading or not CampaignState.has_campaign():
		return

	var clean_checkpoint := StringName(str(checkpoint).strip_edges())

	if clean_checkpoint.is_empty():
		return

	_queued_checkpoint = clean_checkpoint
	_queued_irreversible = _queued_irreversible or irreversible

	if not is_queued_for_deletion():
		call_deferred("_flush_requested_checkpoint")


func _flush_requested_checkpoint() -> void:
	if _queued_checkpoint.is_empty() or _is_loading:
		return

	if _save_in_progress:
		call_deferred("_flush_requested_checkpoint")
		return

	var checkpoint: StringName = _queued_checkpoint
	var irreversible: bool = _queued_irreversible
	_queued_checkpoint = &""
	_queued_irreversible = false
	save_checkpoint(checkpoint, irreversible)


func _on_activity_started(
	_transaction_id: String,
	activity_id: String,
	_source_id: String,
	_request_id: String
) -> void:
	request_checkpoint(StringName("activity_started.%s" % activity_id))


func _on_activity_completed(
	_transaction_id: String,
	activity_id: String,
	_source_id: String
) -> void:
	request_checkpoint(StringName("activity_completed.%s" % activity_id))


func _on_combat_cycle_completed(cycle_index: int) -> void:
	request_checkpoint(StringName("combat_cycle.%d" % cycle_index))


func _on_time_advanced(
	period: int,
	days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	if _is_loading:
		return

	if days_passed != _last_observed_day:
		_last_observed_day = days_passed
		_last_observed_period = period
		request_checkpoint(&"day_advanced", true)
		return

	if period != _last_observed_period:
		_last_observed_period = period
		request_checkpoint(&"period_changed")


func _build_document(metadata: Dictionary) -> Dictionary:
	_registry.prepare_providers_for_save()
	return {
		"save_version": SaveConstants.SAVE_VERSION,
		"metadata": metadata.duplicate(true),
		"sections": _registry.export_sections()
	}


func _restore_document(document: Dictionary) -> PackedStringArray:
	var migration_result: Dictionary = _migrator.migrate_document(document)

	if not bool(migration_result.get("ok", false)):
		return migration_result.get("errors", PackedStringArray())

	var migrated_document: Dictionary = migration_result.get("document", {})
	var errors := validate_document(migrated_document)

	if not errors.is_empty():
		return errors

	var sections: Dictionary = migrated_document.get("sections", {})
	return _registry.import_sections(sections)


func _read_live_document(
	campaign_id: String,
	restore_official: bool = true
) -> Dictionary:
	var live_path: String = SaveConstants.live_path(storage_root, campaign_id)
	var live_result: Dictionary = _read_document(live_path)

	if bool(live_result.get("ok", false)):
		live_result["recovered_from_backup"] = false
		return live_result

	var backup_path: String = SaveConstants.technical_backup_path(
		storage_root,
		campaign_id
	)
	var backup_result: Dictionary = _read_document(backup_path)

	if not bool(backup_result.get("ok", false)):
		var errors := PackedStringArray()
		errors.append_array(live_result.get("errors", PackedStringArray()))
		errors.append_array(backup_result.get("errors", PackedStringArray()))
		return {"ok": false, "errors": errors}

	if restore_official:
		var backup_document: Dictionary = backup_result.get("document", {})

		if not _replace_official_without_rotating_backup(
			backup_document,
			live_path
		):
			return {
				"ok": false,
				"errors": PackedStringArray([
					"Technical backup was valid, but the live save could not be restored."
				])
			}

	backup_result["recovered_from_backup"] = true
	return backup_result


func _read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"errors": PackedStringArray(["Save file does not exist: %s" % path])
		}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return {
			"ok": false,
			"errors": PackedStringArray(["Could not open save file: %s" % path])
		}

	var json := JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	var parsed: Variant = json.data

	if parse_error != OK or parsed is not Dictionary:
		return {
			"ok": false,
			"errors": PackedStringArray(["Save file is not valid JSON: %s" % path])
		}

	var document := parsed as Dictionary
	var migration_result: Dictionary = _migrator.migrate_document(document)

	if not bool(migration_result.get("ok", false)):
		return migration_result

	var migrated_document: Dictionary = migration_result.get("document", {})
	var errors := validate_document(migrated_document)

	if not errors.is_empty():
		return {"ok": false, "errors": errors}

	return {
		"ok": true,
		"document": migrated_document,
		"errors": PackedStringArray()
	}


func _write_document_atomically(
	document: Dictionary,
	official_path: String,
	backup_path: String
) -> bool:
	var campaign_directory: String = official_path.get_base_dir()
	var temporary_path: String = "%s/%s" % [
		campaign_directory,
		SaveConstants.TEMP_FILE_NAME
	]

	if not _write_and_verify(document, temporary_path):
		return false

	var absolute_official: String = ProjectSettings.globalize_path(official_path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
	var absolute_temporary: String = ProjectSettings.globalize_path(temporary_path)

	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup)

	if FileAccess.file_exists(official_path):
		if DirAccess.rename_absolute(absolute_official, absolute_backup) != OK:
			DirAccess.remove_absolute(absolute_temporary)
			return false

	if DirAccess.rename_absolute(absolute_temporary, absolute_official) == OK:
		return true

	if FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(absolute_backup, absolute_official)

	return false


func _write_new_document(document: Dictionary, destination_path: String) -> bool:
	var temporary_path: String = "%s.tmp" % destination_path

	if not _write_and_verify(document, temporary_path):
		return false

	var absolute_destination: String = ProjectSettings.globalize_path(
		destination_path
	)
	var absolute_temporary: String = ProjectSettings.globalize_path(
		temporary_path
	)

	if FileAccess.file_exists(destination_path):
		DirAccess.remove_absolute(absolute_destination)

	return DirAccess.rename_absolute(
		absolute_temporary,
		absolute_destination
	) == OK


func _replace_official_without_rotating_backup(
	document: Dictionary,
	official_path: String
) -> bool:
	var temporary_path: String = "%s.recovery.tmp" % official_path

	if not _write_and_verify(document, temporary_path):
		return false

	var absolute_official: String = ProjectSettings.globalize_path(official_path)
	var absolute_temporary: String = ProjectSettings.globalize_path(temporary_path)

	if FileAccess.file_exists(official_path):
		DirAccess.remove_absolute(absolute_official)

	return DirAccess.rename_absolute(
		absolute_temporary,
		absolute_official
	) == OK


func _write_and_verify(document: Dictionary, path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		return false

	file.store_string(JSON.stringify(document, "\t", false))
	file.flush()
	file.close()

	var verification: Dictionary = _read_document(path)
	return bool(verification.get("ok", false))


func _ensure_campaign_directories(campaign_id: String) -> bool:
	var campaign_directory: String = SaveConstants.campaign_directory(
		storage_root,
		campaign_id
	)
	var checkpoints_directory: String = SaveConstants.checkpoints_directory(
		storage_root,
		campaign_id
	)

	return DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(checkpoints_directory)
	) == OK and DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(campaign_directory)
	)


func _make_checkpoint_file_id(checkpoint: StringName) -> String:
	return "%012d_%06d_%s" % [
		int(Time.get_unix_time_from_system()),
		_checkpoint_sequence,
		SaveConstants.sanitize_identifier(str(checkpoint))
	]


func _timestamp_now() -> String:
	return Time.get_datetime_string_from_system(true)


func _fail_save(errors: PackedStringArray) -> void:
	set_meta(&"last_errors", errors.duplicate())
	save_failed.emit(CampaignState.campaign_id, errors)


func _fail_load(campaign_id: String, errors: PackedStringArray) -> void:
	set_meta(&"last_errors", errors.duplicate())
	campaign_load_failed.emit(campaign_id, errors)


func _sort_metadata_newest_first(a: Dictionary, b: Dictionary) -> bool:
	var a_order: int = int(a.get("checkpoint_order", 0))
	var b_order: int = int(b.get("checkpoint_order", 0))

	if a_order != b_order:
		return a_order > b_order

	return str(a.get("updated_at", "")) > str(b.get("updated_at", ""))


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
