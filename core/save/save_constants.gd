extends RefCounted
class_name SaveConstants


const SAVE_VERSION: int = 1
const MIN_SUPPORTED_SAVE_VERSION: int = 1

const DEFAULT_STORAGE_ROOT: String = "user://null_network/saves"
const LIVE_FILE_NAME: String = "live.json"
const TEMP_FILE_NAME: String = "live.tmp.json"
const TECHNICAL_BACKUP_FILE_NAME: String = "live.backup.json"
const CHECKPOINTS_DIRECTORY_NAME: String = "checkpoints"
const CHECKPOINT_FILE_EXTENSION: String = ".json"

const SECTION_TIME: StringName = &"time"
const SECTION_GAME_STATE: StringName = &"game_state"
const SECTION_CAMPAIGN_STATE: StringName = &"campaign_state"
const SECTION_APP_SESSIONS: StringName = &"app_sessions"
const SECTION_WINDOW_STATES: StringName = &"window_states"
const SECTION_NAVIGATOR_STATE: StringName = &"navigator_state"
const SECTION_WORLD_STATE: StringName = &"world_state"
const SECTION_COMBAT_SESSION: StringName = &"combat_session"
const SECTION_DIALOGUE_SESSION: StringName = &"dialogue_session"

const REQUIRED_CORE_SECTIONS: Array[StringName] = [
	SECTION_TIME,
	SECTION_GAME_STATE,
	SECTION_CAMPAIGN_STATE,
	SECTION_APP_SESSIONS
]

const CHECKPOINT_CAMPAIGN_CREATED: StringName = &"campaign_created"
const CHECKPOINT_MANUAL: StringName = &"manual"


static func campaign_directory(
	storage_root: String,
	campaign_id: String
) -> String:
	return "%s/%s" % [
		storage_root.trim_suffix("/"),
		sanitize_identifier(campaign_id)
	]


static func live_path(
	storage_root: String,
	campaign_id: String
) -> String:
	return "%s/%s" % [
		campaign_directory(storage_root, campaign_id),
		LIVE_FILE_NAME
	]


static func temporary_path(
	storage_root: String,
	campaign_id: String
) -> String:
	return "%s/%s" % [
		campaign_directory(storage_root, campaign_id),
		TEMP_FILE_NAME
	]


static func technical_backup_path(
	storage_root: String,
	campaign_id: String
) -> String:
	return "%s/%s" % [
		campaign_directory(storage_root, campaign_id),
		TECHNICAL_BACKUP_FILE_NAME
	]


static func checkpoints_directory(
	storage_root: String,
	campaign_id: String
) -> String:
	return "%s/%s" % [
		campaign_directory(storage_root, campaign_id),
		CHECKPOINTS_DIRECTORY_NAME
	]


static func checkpoint_path(
	storage_root: String,
	campaign_id: String,
	checkpoint_file_id: String
) -> String:
	return "%s/%s%s" % [
		checkpoints_directory(storage_root, campaign_id),
		sanitize_identifier(checkpoint_file_id),
		CHECKPOINT_FILE_EXTENSION
	]


static func sanitize_identifier(raw_value: String) -> String:
	var clean_value: String = raw_value.strip_edges().to_lower()
	var result: String = ""

	for index in range(clean_value.length()):
		var character: String = clean_value.substr(index, 1)

		if character.is_valid_int() \
			or (character >= "a" and character <= "z") \
			or character in ["-", "_"]:
			result += character
		elif character in [" ", "."] and not result.ends_with("_"):
			result += "_"

	return result.trim_prefix("_").trim_suffix("_")
