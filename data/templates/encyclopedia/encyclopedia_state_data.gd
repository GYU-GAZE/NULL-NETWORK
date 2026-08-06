extends Resource
class_name EncyclopediaStateData


const SAVE_VERSION: int = 1

var records_by_id: Dictionary = {}
var metadata: Dictionary = {}


func reset() -> void:
	records_by_id.clear()
	metadata.clear()


func is_empty() -> bool:
	return records_by_id.is_empty()


func get_record(entry_id: String) -> EncyclopediaRecordData:
	var clean_id: String = entry_id.strip_edges()
	return records_by_id.get(clean_id) as EncyclopediaRecordData


func get_or_create_record(entry_id: String) -> EncyclopediaRecordData:
	var clean_id: String = entry_id.strip_edges()

	if clean_id.is_empty():
		return null

	var existing: EncyclopediaRecordData = get_record(clean_id)

	if existing != null:
		return existing

	var record := EncyclopediaRecordData.new()
	record.entry_id = clean_id
	records_by_id[clean_id] = record
	return record


func record_observation(
	entry_id: String,
	data: Dictionary,
	observation_id: String = "",
	action_index: int = -1
) -> bool:
	var record: EncyclopediaRecordData = get_or_create_record(entry_id)

	if record == null:
		return false

	var changed: bool = record.merge_observation(
		data,
		observation_id,
		action_index
	)

	if not record.has_any_progress():
		records_by_id.erase(record.entry_id)

	return changed


func get_discovered_records() -> Array[EncyclopediaRecordData]:
	var result: Array[EncyclopediaRecordData] = []

	for value: Variant in records_by_id.values():
		var record := value as EncyclopediaRecordData

		if record != null and record.seen:
			result.append(record)

	result.sort_custom(
		func(left: EncyclopediaRecordData, right: EncyclopediaRecordData) -> bool:
			return left.entry_id.naturalnocasecmp_to(right.entry_id) < 0
	)
	return result


func has_any_entry() -> bool:
	for record: EncyclopediaRecordData in get_discovered_records():
		if record.seen:
			return true

	return false


func has_milestone(entry_id: String, milestone: String) -> bool:
	var record: EncyclopediaRecordData = get_record(entry_id)
	return record != null and record.has_milestone(milestone)


func to_save_data() -> Dictionary:
	var entries: Dictionary = {}
	var ids: Array = records_by_id.keys()
	ids.sort_custom(
		func(left: Variant, right: Variant) -> bool:
			return str(left).naturalnocasecmp_to(str(right)) < 0
	)

	for raw_id: Variant in ids:
		var entry_id: String = str(raw_id)
		var record: EncyclopediaRecordData = get_record(entry_id)

		if record != null and record.has_any_progress():
			entries[entry_id] = record.to_save_data()

	return {
		"version": SAVE_VERSION,
		"entries": entries,
		"metadata": metadata.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	var entries_value: Variant = data.get("entries", null)
	var entries: Dictionary = {}

	if entries_value is Dictionary:
		entries = entries_value as Dictionary
	elif _looks_like_legacy_entry_map(data):
		entries = data

	for raw_id: Variant in entries:
		var entry_id: String = str(raw_id).strip_edges()
		var record_value: Variant = entries[raw_id]

		if entry_id.is_empty() or record_value is not Dictionary:
			continue

		var record := EncyclopediaRecordData.new()
		record.load_save_data(entry_id, record_value as Dictionary)

		if record.has_any_progress():
			records_by_id[entry_id] = record

	var metadata_value: Variant = data.get("metadata", {})

	if metadata_value is Dictionary:
		metadata = (metadata_value as Dictionary).duplicate(true)


func duplicate_state() -> EncyclopediaStateData:
	var result := EncyclopediaStateData.new()
	result.load_save_data(to_save_data())
	return result


func validate_state() -> PackedStringArray:
	var errors := PackedStringArray()

	for raw_id: Variant in records_by_id:
		var entry_id: String = str(raw_id).strip_edges()
		var record := records_by_id[raw_id] as EncyclopediaRecordData

		if entry_id.is_empty():
			errors.append("Encyclopedia state contains an empty entry ID.")
		elif record == null:
			errors.append("Encyclopedia entry '%s' has null state." % entry_id)
		elif record.entry_id != entry_id:
			errors.append(
				"Encyclopedia entry '%s' contains mismatched state ID '%s'."
				% [entry_id, record.entry_id]
			)

	return errors


func _looks_like_legacy_entry_map(data: Dictionary) -> bool:
	if data.is_empty() or data.has("version") or data.has("metadata"):
		return false

	for value: Variant in data.values():
		if value is Dictionary:
			return true

	return false
