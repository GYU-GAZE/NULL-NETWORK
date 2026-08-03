extends Resource
class_name StoryEventCatalog


@export var events: Array[StoryEventData] = []


func get_event(event_id: String) -> StoryEventData:
	var clean_id: String = event_id.strip_edges()

	if clean_id.is_empty():
		return null

	for event: StoryEventData in events:
		if event != null and event.get_display_id() == clean_id:
			return event

	return null


func get_ordered_events() -> Array[StoryEventData]:
	var result: Array[StoryEventData] = []

	for event: StoryEventData in events:
		if event != null:
			result.append(event)

	result.sort_custom(_sort_events)
	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}

	for index: int in range(events.size()):
		var event: StoryEventData = events[index]

		if event == null:
			errors.append("Event %d is null." % index)
			continue

		var clean_id: String = event.get_display_id()

		if not clean_id.is_empty() and seen_ids.has(clean_id):
			errors.append("Duplicate event_id '%s'." % clean_id)
		else:
			seen_ids[clean_id] = true

		for error: String in event.validate_data():
			errors.append("Event %d: %s" % [index, error])

	return errors


func _sort_events(first: StoryEventData, second: StoryEventData) -> bool:
	if first.priority == second.priority:
		return first.get_display_id().naturalnocasecmp_to(
			second.get_display_id()
		) < 0

	return first.priority > second.priority
