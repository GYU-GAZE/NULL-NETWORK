extends EncyclopediaGameContentCatalog
class_name CalendarGameContentCatalog


@export_category("Calendar")
@export var calendar_catalog: CalendarCatalog


func get_content_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = super.get_content_groups()
	var registered_events: Array[CalendarEventData] = []

	if calendar_catalog != null:
		registered_events = calendar_catalog.events

	groups.append({
		"category": &"calendar_events",
		"id_property": &"event_id",
		"resources": registered_events
	})
	return groups


func validate_data() -> PackedStringArray:
	var errors: PackedStringArray = super.validate_data()

	if calendar_catalog == null:
		errors.append("calendar_catalog cannot be null.")
		return errors

	for error: String in calendar_catalog.validate_data():
		errors.append("Calendar catalog: %s" % error)

	var known_location_ids: Dictionary = {}
	var known_story_event_ids: Dictionary = {}
	var known_lead_ids: Dictionary = {}
	var known_incident_ids: Dictionary = {}

	for location: MapLocation in locations:
		if location != null:
			known_location_ids[location.location_id.strip_edges()] = true

	if story_event_catalog != null:
		for story_event: StoryEventData in story_event_catalog.events:
			if story_event != null:
				known_story_event_ids[story_event.get_display_id()] = true

	if lead_catalog != null:
		for lead: LeadData in lead_catalog.leads:
			if lead != null:
				known_lead_ids[lead.get_display_id()] = true

	for incident: IncidentData in incidents:
		if incident != null:
			known_incident_ids[incident.get_display_id()] = true

	for event: CalendarEventData in calendar_catalog.events:
		if event == null:
			continue

		var location_id: String = event.location_id.strip_edges()
		var source_id: String = event.source_id.strip_edges()

		if not location_id.is_empty() and not known_location_ids.has(location_id):
			errors.append(
				"Calendar event '%s' references unknown location '%s'."
				% [event.get_display_id(), location_id]
			)

		if source_id.is_empty():
			continue

		match event.event_kind:
			CalendarEventData.EventKind.STORY:
				if not known_story_event_ids.has(source_id):
					errors.append(
					"Calendar event '%s' references unknown StoryEvent '%s'."
					% [event.get_display_id(), source_id]
				)
			CalendarEventData.EventKind.LEAD:
				if not known_lead_ids.has(source_id):
					errors.append(
					"Calendar event '%s' references unknown Lead '%s'."
					% [event.get_display_id(), source_id]
				)
			CalendarEventData.EventKind.INCIDENT:
				if not known_incident_ids.has(source_id):
					errors.append(
					"Calendar event '%s' references unknown Incident '%s'."
					% [event.get_display_id(), source_id]
				)

	return errors
