extends Resource
class_name OccupationScheduleData


@export_category("Identity")
@export var schedule_id: String = ""
@export_multiline var occupied_reason: String = "Operator routine is in progress."

@export_category("Weekly Routine")
## Sunday = 0, Monday = 1, ..., Saturday = 6.
@export var occupied_weekday_indices: PackedInt32Array = PackedInt32Array()
## Absolute daily blocks: DAY 0-11, then NIGHT 12-23.
@export var occupied_day_blocks: PackedInt32Array = PackedInt32Array()


func get_display_id() -> String:
	return schedule_id.strip_edges()


func is_block_occupied(weekday_index: int, day_block: int) -> bool:
	return (
		occupied_weekday_indices.has(clampi(weekday_index, 0, 6))
		and occupied_day_blocks.has(
			clampi(
				day_block,
				0,
				TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY - 1
			)
		)
	)


func get_occupied_reason() -> String:
	var clean_reason: String = occupied_reason.strip_edges()

	if not clean_reason.is_empty():
		return clean_reason

	return "Operator routine is in progress."


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_weekdays: Dictionary = {}
	var seen_blocks: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("schedule_id cannot be empty.")

	for weekday: int in occupied_weekday_indices:
		if weekday < 0 or weekday > 6:
			errors.append("Occupied weekday must be between 0 and 6.")
		elif seen_weekdays.has(weekday):
			errors.append("Occupied weekday %d is duplicated." % weekday)
		else:
			seen_weekdays[weekday] = true

	for day_block: int in occupied_day_blocks:
		if day_block < 0 or day_block >= TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY:
			errors.append("Occupied day block must be between 0 and 23.")
		elif seen_blocks.has(day_block):
			errors.append("Occupied day block %d is duplicated." % day_block)
		else:
			seen_blocks[day_block] = true

	if occupied_day_blocks.is_empty() != occupied_weekday_indices.is_empty():
		errors.append(
			"Weekdays and occupied blocks must both be empty or both configured."
		)

	return errors
