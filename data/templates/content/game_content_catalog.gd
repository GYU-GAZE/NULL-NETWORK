extends Resource
class_name GameContentCatalog


@export_category("Creatures and Equipment")
@export var apks: Array[APKData] = []
@export var modules: Array[ModuleData] = []
@export var items: Array[ItemData] = []

@export_category("Combat Runtime Content")
@export var combat_encounters: Array[CombatEncounter] = []
@export var character_loadouts: Array[CharacterLoadout] = []
@export var status_effects: Array[StatusEffectData] = []
@export var dummies: Array[DummyData] = []

@export_category("Operator and KubuOS")
@export var occupations: Array[OccupationData] = []
@export var app_catalog: AppCatalog

@export_category("World and Narrative")
@export var locations: Array[MapLocation] = []
@export var dialogues: Array[DialogueData] = []
@export var story_event_catalog: StoryEventCatalog
@export var lead_catalog: LeadCatalog
@export var incidents: Array[IncidentData] = []


func get_content_groups() -> Array[Dictionary]:
	var registered_apps: Array[AppResource] = []
	var registered_story_events: Array[StoryEventData] = []
	var registered_leads: Array[LeadData] = []

	if app_catalog != null:
		registered_apps = app_catalog.apps

	if story_event_catalog != null:
		registered_story_events = story_event_catalog.events

	if lead_catalog != null:
		registered_leads = lead_catalog.leads

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
		_create_group(
			&"story_events",
			&"event_id",
			registered_story_events
		),
		_create_group(&"leads", &"lead_id", registered_leads),
		_create_group(&"incidents", &"incident_id", incidents)
	]


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if app_catalog == null:
		errors.append("app_catalog cannot be null.")
	else:
		for error: String in app_catalog.validate_data():
			errors.append("App catalog: %s" % error)

	if story_event_catalog == null:
		errors.append("story_event_catalog cannot be null.")
	else:
		for error: String in story_event_catalog.validate_data():
			errors.append("StoryEvent catalog: %s" % error)

	if lead_catalog == null:
		errors.append("lead_catalog cannot be null.")
	else:
		for error: String in lead_catalog.validate_data():
			errors.append("Lead catalog: %s" % error)

	for index: int in range(incidents.size()):
		var incident: IncidentData = incidents[index]

		if incident == null:
			errors.append("Incident %d is null." % index)
			continue

		for error: String in incident.validate_data():
			errors.append("Incident %d: %s" % [index, error])

	for index: int in range(dialogues.size()):
		var dialogue: DialogueData = dialogues[index]

		if dialogue == null:
			errors.append("Dialogue %d is null." % index)
			continue

		for error: String in dialogue.validate_data():
			errors.append("Dialogue %d: %s" % [index, error])

	for index: int in range(occupations.size()):
		var occupation: OccupationData = occupations[index]

		if occupation == null:
			errors.append("Occupation %d is null." % index)
			continue

		for error: String in occupation.validate_data():
			errors.append("Occupation %d: %s" % [index, error])

	var known_apk_ids: Dictionary = {}

	for index: int in range(apks.size()):
		var apk: APKData = apks[index]

		if apk == null:
			errors.append("APK %d is null." % index)
			continue

		var apk_id: String = apk.apk_id.strip_edges()

		if not apk_id.is_empty():
			known_apk_ids[apk_id] = true

		for error: String in apk.validate_data():
			errors.append("APK %d: %s" % [index, error])

	for index: int in range(items.size()):
		var item: ItemData = items[index]

		if item == null:
			errors.append("Item %d is null." % index)
			continue

		for error: String in item.validate_data():
			errors.append("Item %d: %s" % [index, error])

	for index: int in range(combat_encounters.size()):
		var encounter: CombatEncounter = combat_encounters[index]

		if encounter == null:
			errors.append("Combat encounter %d is null." % index)
			continue

		for error: String in encounter.validate_data():
			errors.append("Combat encounter %d: %s" % [index, error])

		_validate_encounter_apk_references(
			errors,
			encounter,
			known_apk_ids
		)

	return errors


func _validate_encounter_apk_references(
	errors: PackedStringArray,
	encounter: CombatEncounter,
	known_apk_ids: Dictionary
) -> void:
	var slots: Array[CombatSlotData] = []
	slots.append_array(encounter.ally_slots)
	slots.append_array(encounter.enemy_slots)

	for slot: CombatSlotData in slots:
		if slot == null \
			or slot.participant_source \
			!= CombatSlotData.ParticipantSource.CATALOG_APK:
			continue

		var apk_id: String = slot.apk_id.strip_edges()

		if not known_apk_ids.has(apk_id):
			errors.append(
				"Combat encounter '%s' references unknown catalog APK '%s'."
				% [encounter.encounter_id, apk_id]
			)


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
