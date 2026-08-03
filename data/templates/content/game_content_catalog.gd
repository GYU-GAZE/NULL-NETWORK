extends Resource
class_name GameContentCatalog


@export_category("Creatures and Equipment")
@export var apks: Array[Resource] = []
@export var modules: Array[ModuleData] = []
@export var items: Array[Resource] = []

@export_category("Combat Runtime Content")
@export var combat_encounters: Array[CombatEncounter] = []
@export var character_loadouts: Array[CharacterLoadout] = []
@export var status_effects: Array[StatusEffectData] = []
@export var dummies: Array[DummyData] = []

@export_category("Operator and KubuOS")
@export var occupations: Array[Resource] = []
@export var app_catalog: AppCatalog

@export_category("World and Narrative")
@export var locations: Array[MapLocation] = []
@export var dialogues: Array[Resource] = []
@export var story_events: Array[Resource] = []
@export var leads: Array[Resource] = []
@export var incidents: Array[Resource] = []


func get_content_groups() -> Array[Dictionary]:
	var registered_apps: Array[AppResource] = []

	if app_catalog != null:
		registered_apps = app_catalog.apps

	return [
		_create_group(&"apks", &"apk_id", apks),
		_create_group(&"modules", &"module_id", modules),
		_create_group(&"items", &"item_id", items),
		_create_group(
			&"combat_encounters",
			&"encounter_id",
			combat_encounters
		),
		_create_group(
			&"character_loadouts",
			&"character_id",
			character_loadouts
		),
		_create_group(
			&"status_effects",
			&"status_id",
			status_effects
		),
		_create_group(&"dummies", &"dummy_id", dummies),
		_create_group(&"occupations", &"occupation_id", occupations),
		_create_group(&"apps", &"app_id", registered_apps),
		_create_group(&"locations", &"location_id", locations),
		_create_group(&"dialogues", &"dialogue_id", dialogues),
		_create_group(&"story_events", &"story_event_id", story_events),
		_create_group(&"leads", &"lead_id", leads),
		_create_group(&"incidents", &"incident_id", incidents)
	]


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if app_catalog == null:
		errors.append("app_catalog cannot be null.")
	else:
		for error: String in app_catalog.validate_data():
			errors.append("App catalog: %s" % error)

	return errors


func _create_group(
	category: StringName,
	id_property: StringName,
	resources: Array
) -> Dictionary:
	return {
		"category": category,
		"id_property": id_property,
		"resources": resources
	}
