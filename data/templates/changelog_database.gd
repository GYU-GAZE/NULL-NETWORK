extends Resource
class_name ChangelogDatabase

@export_category("Content")
@export var entries: Array[ChangelogEntryData] = []


func get_visible_entries() -> Array[ChangelogEntryData]:
	var result: Array[ChangelogEntryData] = []

	for entry in entries:
		if entry == null:
			continue

		if entry.is_visible():
			result.append(entry)

	result.sort_custom(_sort_entries)
	return result


func get_visibility_signature() -> String:
	var visible_entries: Array[ChangelogEntryData] = get_visible_entries()
	var parts: Array[String] = []

	for i in range(visible_entries.size()):
		var entry: ChangelogEntryData = visible_entries[i]
		parts.append(entry.get_signature_id(i))

	return "|".join(parts)


func _sort_entries(a: ChangelogEntryData, b: ChangelogEntryData) -> bool:
	if a == null:
		return false

	if b == null:
		return true

	return a.get_release_action_index() > b.get_release_action_index()
