extends Resource
class_name EncyclopediaCatalog


@export var entries: Array[EncyclopediaEntryData] = []


func get_entry(entry_id: String) -> EncyclopediaEntryData:
	var clean_id: String = entry_id.strip_edges()

	for entry: EncyclopediaEntryData in entries:
		if entry != null and entry.get_display_id() == clean_id:
			return entry

	return null


func get_ordered_entries() -> Array[EncyclopediaEntryData]:
	var result: Array[EncyclopediaEntryData] = []

	for entry: EncyclopediaEntryData in entries:
		if entry != null:
			result.append(entry)

	result.sort_custom(
		func(left: EncyclopediaEntryData, right: EncyclopediaEntryData) -> bool:
			if left.sort_order != right.sort_order:
				return left.sort_order < right.sort_order

			return left.get_display_name().naturalnocasecmp_to(
				right.get_display_name()
			) < 0
	)
	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}

	for index: int in range(entries.size()):
		var entry: EncyclopediaEntryData = entries[index]

		if entry == null:
			errors.append("Entry %d is null." % index)
			continue

		var entry_id: String = entry.get_display_id()

		if not entry_id.is_empty() and seen_ids.has(entry_id):
			errors.append("Duplicate encyclopedia entry_id '%s'." % entry_id)
		else:
			seen_ids[entry_id] = true

		for error: String in entry.validate_data():
			errors.append("Entry %d: %s" % [index, error])

	return errors
