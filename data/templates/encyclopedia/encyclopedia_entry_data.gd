extends Resource
class_name EncyclopediaEntryData


enum EntryKind {
	APK,
	EXE,
	LOCATION,
	LORE
}

@export_category("Identity")
@export var entry_id: String = ""
@export var entry_kind: EntryKind = EntryKind.EXE
@export var display_name: String = ""
@export var subtitle: String = ""
@export_range(0, 100000, 1) var sort_order: int = 0

@export_category("Subject")
@export var subject_apk_id: String = ""
@export var icon: Texture2D
@export var portrait: Texture2D

@export_category("Confirmed Information")
@export_multiline var summary: String = ""
@export_multiline var scan_notes: String = ""
@export_multiline var defeat_notes: String = ""
@export_multiline var purge_notes: String = ""
@export_multiline var purify_notes: String = ""
@export_multiline var tame_notes: String = ""
@export_multiline var loss_notes: String = ""

@export_category("Catalog Relationships")
@export var related_module_ids: PackedStringArray = PackedStringArray()
@export var related_location_ids: PackedStringArray = PackedStringArray()
@export var related_evolution_ids: PackedStringArray = PackedStringArray()


func get_display_id() -> String:
	return entry_id.strip_edges()


func get_display_name() -> String:
	var clean_name: String = display_name.strip_edges()
	return clean_name if not clean_name.is_empty() else get_display_id()


func get_kind_label() -> String:
	return EntryKind.keys()[entry_kind]


func get_primary_texture() -> Texture2D:
	return portrait if portrait != null else icon


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("entry_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append("display_name cannot be empty.")

	if entry_kind in [EntryKind.APK, EntryKind.EXE] \
		and subject_apk_id.strip_edges().is_empty():
		errors.append("APK and EXE entries require subject_apk_id.")

	_validate_ids(errors, related_module_ids, "related_module_ids")
	_validate_ids(errors, related_location_ids, "related_location_ids")
	_validate_ids(errors, related_evolution_ids, "related_evolution_ids")
	return errors


func _validate_ids(
	errors: PackedStringArray,
	values: PackedStringArray,
	field_name: String
) -> void:
	var seen: Dictionary = {}

	for raw_id: String in values:
		var clean_id: String = raw_id.strip_edges()

		if clean_id.is_empty():
			errors.append("%s cannot contain an empty ID." % field_name)
		elif seen.has(clean_id):
			errors.append("%s repeats ID '%s'." % [field_name, clean_id])
		else:
			seen[clean_id] = true
