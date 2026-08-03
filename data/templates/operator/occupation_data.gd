extends Resource
class_name OccupationData


@export_category("Identity")
@export var occupation_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Economy")
@export_range(0, 1000000000, 1, "or_greater") var initial_money: int = 0
@export_range(0, 1000000000, 1, "or_greater") var recurring_income: int = 0
@export_range(1, 365, 1, "or_greater") var income_interval_days: int = 7

@export_category("Routine")
@export var schedule: OccupationScheduleData
@export var starting_location_id: String = ""
@export var routine_event_ids: PackedStringArray = PackedStringArray()


func get_display_id() -> String:
	return occupation_id.strip_edges()


func get_display_name() -> String:
	var clean_name: String = display_name.strip_edges()

	if not clean_name.is_empty():
		return clean_name

	return get_display_id()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_event_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("occupation_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append("display_name cannot be empty.")

	if initial_money < 0:
		errors.append("initial_money cannot be negative.")

	if recurring_income < 0:
		errors.append("recurring_income cannot be negative.")

	if income_interval_days < 1:
		errors.append("income_interval_days must be at least 1.")

	if schedule == null:
		errors.append("schedule cannot be null.")
	else:
		for error: String in schedule.validate_data():
			errors.append("Schedule: %s" % error)

	if starting_location_id.strip_edges().is_empty():
		errors.append("starting_location_id cannot be empty.")

	for raw_event_id: String in routine_event_ids:
		var event_id: String = raw_event_id.strip_edges()

		if event_id.is_empty():
			errors.append("routine_event_ids cannot contain an empty ID.")
		elif seen_event_ids.has(event_id):
			errors.append("Duplicate routine event ID '%s'." % event_id)
		else:
			seen_event_ids[event_id] = true

	return errors
