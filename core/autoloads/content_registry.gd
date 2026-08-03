extends Node


signal registry_rebuilt
signal registry_rejected(errors: PackedStringArray)


const DEFAULT_CATALOG: GameContentCatalog = preload(
	"res://data/content/game_content_catalog.tres"
)

const CATEGORY_APKS: StringName = &"apks"
const CATEGORY_MODULES: StringName = &"modules"
const CATEGORY_ITEMS: StringName = &"items"
const CATEGORY_COMBAT_ENCOUNTERS: StringName = &"combat_encounters"
const CATEGORY_CHARACTER_LOADOUTS: StringName = &"character_loadouts"
const CATEGORY_STATUS_EFFECTS: StringName = &"status_effects"
const CATEGORY_DUMMIES: StringName = &"dummies"
const CATEGORY_OCCUPATIONS: StringName = &"occupations"
const CATEGORY_APPS: StringName = &"apps"
const CATEGORY_LOCATIONS: StringName = &"locations"
const CATEGORY_DIALOGUES: StringName = &"dialogues"
const CATEGORY_STORY_EVENTS: StringName = &"story_events"
const CATEGORY_LEADS: StringName = &"leads"
const CATEGORY_INCIDENTS: StringName = &"incidents"

var catalog: GameContentCatalog
var _indexes: Dictionary = {}
var _last_errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	configure_catalog(DEFAULT_CATALOG)


func configure_catalog(new_catalog: GameContentCatalog) -> PackedStringArray:
	var build_result: Dictionary = _build_indexes(new_catalog)
	var errors: PackedStringArray = build_result.get(
		"errors",
		PackedStringArray()
	)
	_last_errors = errors.duplicate()

	if not errors.is_empty():
		registry_rejected.emit(errors)
		return errors

	catalog = new_catalog
	_indexes = build_result.get("indexes", {})
	registry_rebuilt.emit()
	return errors


func reset_to_default_catalog() -> PackedStringArray:
	return configure_catalog(DEFAULT_CATALOG)


func get_last_errors() -> PackedStringArray:
	return _last_errors.duplicate()


func has(category: StringName, content_id: String) -> bool:
	var clean_id: String = content_id.strip_edges()

	if clean_id.is_empty() or not _indexes.has(category):
		return false

	var category_index: Dictionary = _indexes[category]
	return category_index.has(clean_id)


func resolve(category: StringName, content_id: String) -> Resource:
	var clean_id: String = content_id.strip_edges()

	if clean_id.is_empty() or not _indexes.has(category):
		return null

	var category_index: Dictionary = _indexes[category]
	return category_index.get(clean_id) as Resource


func get_all(category: StringName) -> Array[Resource]:
	var result: Array[Resource] = []

	if not _indexes.has(category):
		return result

	var category_index: Dictionary = _indexes[category]

	for resource: Variant in category_index.values():
		if resource is Resource:
			result.append(resource)

	return result


func get_apk(apk_id: String) -> Resource:
	return resolve(CATEGORY_APKS, apk_id)


func get_module(module_id: String) -> ModuleData:
	return resolve(CATEGORY_MODULES, module_id) as ModuleData


func get_item(item_id: String) -> Resource:
	return resolve(CATEGORY_ITEMS, item_id)


func get_combat_encounter(encounter_id: String) -> CombatEncounter:
	return resolve(
		CATEGORY_COMBAT_ENCOUNTERS,
		encounter_id
	) as CombatEncounter


func get_character_loadout(character_id: String) -> CharacterLoadout:
	return resolve(
		CATEGORY_CHARACTER_LOADOUTS,
		character_id
	) as CharacterLoadout


func get_status_effect(status_id: String) -> StatusEffectData:
	return resolve(CATEGORY_STATUS_EFFECTS, status_id) as StatusEffectData


func get_dummy(dummy_id: String) -> DummyData:
	return resolve(CATEGORY_DUMMIES, dummy_id) as DummyData


func get_occupation(occupation_id: String) -> Resource:
	return resolve(CATEGORY_OCCUPATIONS, occupation_id)


func get_app(app_id: String) -> AppResource:
	return resolve(CATEGORY_APPS, app_id) as AppResource


func get_app_catalog() -> AppCatalog:
	if catalog == null:
		return null

	return catalog.app_catalog


func get_location(location_id: String) -> MapLocation:
	return resolve(CATEGORY_LOCATIONS, location_id) as MapLocation


func get_dialogue(dialogue_id: String) -> Resource:
	return resolve(CATEGORY_DIALOGUES, dialogue_id)


func get_story_event(story_event_id: String) -> Resource:
	return resolve(CATEGORY_STORY_EVENTS, story_event_id)


func get_lead(lead_id: String) -> Resource:
	return resolve(CATEGORY_LEADS, lead_id)


func get_incident(incident_id: String) -> Resource:
	return resolve(CATEGORY_INCIDENTS, incident_id)


func _build_indexes(new_catalog: GameContentCatalog) -> Dictionary:
	var errors := PackedStringArray()
	var proposed_indexes: Dictionary = {}

	if new_catalog == null:
		errors.append("ContentRegistry requires a GameContentCatalog.")
		return {
			"errors": errors,
			"indexes": proposed_indexes
		}

	var catalog_errors: PackedStringArray = new_catalog.validate_data()

	if not catalog_errors.is_empty():
		errors.append_array(catalog_errors)
		return {
			"errors": errors,
			"indexes": proposed_indexes
		}

	for group: Dictionary in new_catalog.get_content_groups():
		var category: StringName = group.get("category", &"")
		var id_property: StringName = group.get("id_property", &"")
		var resources: Array = group.get("resources", [])
		var category_index: Dictionary = {}

		for resource: Resource in resources:
			if resource == null:
				errors.append(
					"Content category '%s' contains a null Resource."
					% category
				)
				continue

			if not _resource_has_property(resource, id_property):
				errors.append(
					"Resource '%s' in category '%s' has no '%s' property."
					% [resource.resource_path, category, id_property]
				)
				continue

			var content_id: String = str(
				resource.get(id_property)
			).strip_edges()

			if content_id.is_empty():
				errors.append(
					"Content category '%s' contains an empty ID."
					% category
				)
				continue

			if category_index.has(content_id):
				errors.append(
					"Duplicate content ID '%s' in category '%s'."
					% [content_id, category]
				)
				continue

			category_index[content_id] = resource

		proposed_indexes[category] = category_index

	return {
		"errors": errors,
		"indexes": proposed_indexes
	}


func _resource_has_property(
	resource: Resource,
	property_name: StringName
) -> bool:
	for property_info: Dictionary in resource.get_property_list():
		if property_info.get("name", &"") == property_name:
			return true

	return false
