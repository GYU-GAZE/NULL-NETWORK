extends Resource
class_name CalendarCatalog


@export var events: Array[CalendarEventData] = []


func get_event(event_id: String) -> CalendarEventData:
	var clean_id: String = event_id.strip_edges()

	for event: CalendarEventData in events:
		if event != null and event.get_display_id() == clean_id:
			return event

	return null


func get_visible_events(context: Dictionary = {}) -> Array[CalendarEventData]:
	var result: Array[CalendarEventData] = []

	for event: CalendarEventData in events:
		if event != null \
			and event.is_visible(context) \
			and event.is_available(context):
			result.append(event)

	result.sort_custom(
		func(left: CalendarEventData, right: CalendarEventData) -> bool:
			if left.priority != right.priority:
				return left.priority > right.priority

			return left.get_display_id() < right.get_display_id()
	)
	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var event_ids: Dictionary = {}

	for index: int in range(events.size()):
		var event: CalendarEventData = events[index]

		if event == null:
			errors.append("Event %d is null." % index)
			continue

		var event_id: String = event.get_display_id()

		if event_ids.has(event_id):
			errors.append("Duplicate calendar event_id '%s'." % event_id)
		else:
			event_ids[event_id] = true

		for error: String in event.validate_data():
			errors.append("Event %d: %s" % [index, error])

	return errors
