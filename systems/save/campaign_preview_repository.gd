extends RefCounted
class_name CampaignPreviewRepository


static func list_profiles(
	storage_root: String = SaveConstants.DEFAULT_STORAGE_ROOT
) -> Array[Dictionary]:
	var profiles: Array[Dictionary] = []
	var root := DirAccess.open(storage_root)

	if root == null:
		return profiles

	root.list_dir_begin()
	var entry_name: String = root.get_next()

	while not entry_name.is_empty():
		if root.current_is_dir() and not entry_name.begins_with("."):
			var profile := _read_campaign_preview(storage_root, entry_name)

			if not profile.is_empty():
				profiles.append(profile)

		entry_name = root.get_next()

	root.list_dir_end()
	profiles.sort_custom(_sort_newest_first)
	return profiles


static func get_initial_period(
	storage_root: String = SaveConstants.DEFAULT_STORAGE_ROOT
) -> int:
	var profiles: Array[Dictionary] = list_profiles(storage_root)

	if profiles.is_empty():
		return TimeManager.TimePeriod.DAY

	return int(
		profiles[0].get("current_period", TimeManager.TimePeriod.DAY)
	)


static func _read_campaign_preview(
	storage_root: String,
	campaign_id: String
) -> Dictionary:
	var live_path: String = SaveConstants.live_path(storage_root, campaign_id)
	var document: Dictionary = _read_json_document(live_path)

	if document.is_empty():
		document = _read_json_document(
			SaveConstants.technical_backup_path(storage_root, campaign_id)
		)

	if document.is_empty():
		return {}

	var metadata_value: Variant = document.get("metadata", {})
	var sections_value: Variant = document.get("sections", {})

	if metadata_value is not Dictionary or sections_value is not Dictionary:
		return {}

	var metadata := metadata_value as Dictionary
	var sections := sections_value as Dictionary
	var time_section := _dictionary_from(
		sections.get(str(SaveConstants.SECTION_TIME), {})
	)
	var campaign_section := _dictionary_from(
		sections.get(str(SaveConstants.SECTION_CAMPAIGN_STATE), {})
	)
	var operator := _dictionary_from(campaign_section.get("operator", {}))
	var profile := _dictionary_from(operator.get("profile", {}))

	var operator_name: String = str(
		operator.get("display_name", "")
	).strip_edges()
	var username: String = str(profile.get("username", "")).strip_edges()

	if operator_name.is_empty():
		operator_name = str(metadata.get("display_name", "New User")).strip_edges()

	if operator_name.is_empty():
		operator_name = "New User"

	return {
		"campaign_id": str(metadata.get("campaign_id", campaign_id)),
		"display_name": operator_name,
		"username": username,
		"save_mode": int(
			metadata.get("save_mode", CampaignState.SaveMode.UNSET)
		),
		"updated_at": str(metadata.get("updated_at", "")),
		"current_period": int(
			time_section.get("current_period", TimeManager.TimePeriod.DAY)
		),
		"days_passed": maxi(1, int(time_section.get("days_passed", 1))),
		"current_action_block": maxi(
			0,
			int(time_section.get("current_action_block", 0))
		),
		"has_operator": not str(
			operator.get("operator_id", "")
		).strip_edges().is_empty()
	}


static func _read_json_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return {}

	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)

	if parsed is Dictionary:
		return parsed as Dictionary

	return {}


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}


static func _sort_newest_first(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("updated_at", "")) > str(b.get("updated_at", ""))
