extends SocialGameContentCatalog
class_name EncyclopediaGameContentCatalog


@export_category("Encyclopedia")
@export var encyclopedia_catalog: EncyclopediaCatalog


func get_content_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = super.get_content_groups()
	var registered_entries: Array[EncyclopediaEntryData] = []

	if encyclopedia_catalog != null:
		registered_entries = encyclopedia_catalog.entries

	groups.append({
		"category": &"encyclopedia_entries",
		"id_property": &"entry_id",
		"resources": registered_entries
	})
	return groups


func validate_data() -> PackedStringArray:
	var errors: PackedStringArray = super.validate_data()

	if encyclopedia_catalog == null:
		errors.append("encyclopedia_catalog cannot be null.")
		return errors

	for error: String in encyclopedia_catalog.validate_data():
		errors.append("Encyclopedia catalog: %s" % error)

	var known_apk_ids: Dictionary = {}
	var known_module_ids: Dictionary = {}
	var known_location_ids: Dictionary = {}
	var known_entry_ids: Dictionary = {}

	for apk: APKData in apks:
		if apk != null:
			known_apk_ids[apk.apk_id.strip_edges()] = true

	for module: ModuleData in modules:
		if module != null:
			known_module_ids[str(module.module_id).strip_edges()] = true

	for location: MapLocation in locations:
		if location != null:
			known_location_ids[location.location_id.strip_edges()] = true

	for entry: EncyclopediaEntryData in encyclopedia_catalog.entries:
		if entry == null:
			continue

		known_entry_ids[entry.get_display_id()] = true
		_validate_entry_references(
			errors,
			entry,
			known_apk_ids,
			known_module_ids,
			known_location_ids
		)

	for encounter: CombatEncounter in combat_encounters:
		if encounter != null:
			_validate_encounter_entries(errors, encounter, known_entry_ids)

	return errors


func _validate_entry_references(
	errors: PackedStringArray,
	entry: EncyclopediaEntryData,
	known_apk_ids: Dictionary,
	known_module_ids: Dictionary,
	known_location_ids: Dictionary
) -> void:
	var subject_apk_id: String = entry.subject_apk_id.strip_edges()

	if not subject_apk_id.is_empty() and not known_apk_ids.has(subject_apk_id):
		errors.append(
			"Encyclopedia entry '%s' references unknown APK '%s'."
			% [entry.get_display_id(), subject_apk_id]
		)

	for module_id: String in entry.related_module_ids:
		if not known_module_ids.has(module_id.strip_edges()):
			errors.append(
				"Encyclopedia entry '%s' references unknown Module '%s'."
				% [entry.get_display_id(), module_id]
			)

	for location_id: String in entry.related_location_ids:
		if not known_location_ids.has(location_id.strip_edges()):
			errors.append(
				"Encyclopedia entry '%s' references unknown location '%s'."
				% [entry.get_display_id(), location_id]
			)

	for evolution_id: String in entry.related_evolution_ids:
		if not known_apk_ids.has(evolution_id.strip_edges()):
			errors.append(
				"Encyclopedia entry '%s' references unknown evolution APK '%s'."
				% [entry.get_display_id(), evolution_id]
			)


func _validate_encounter_entries(
	errors: PackedStringArray,
	encounter: CombatEncounter,
	known_entry_ids: Dictionary
) -> void:
	var slots: Array[CombatSlotData] = []
	slots.append_array(encounter.ally_slots)
	slots.append_array(encounter.enemy_slots)

	for slot: CombatSlotData in slots:
		if slot == null or slot.reward_profile == null:
			continue

		var entry_id: String = (
			slot.reward_profile.encyclopedia_entry_id.strip_edges()
		)

		if not entry_id.is_empty() and not known_entry_ids.has(entry_id):
			errors.append(
				"Combat encounter '%s' reward references unknown Encyclopedia entry '%s'."
				% [encounter.encounter_id, entry_id]
			)
