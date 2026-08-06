extends Resource
class_name NPCRoutineEntryData


enum PresenceState {
	OFFLINE,
	AWAY,
	ONLINE,
	DO_NOT_DISTURB
}


@export_category("Identity")
@export var routine_id: String = ""
@export var priority: int = 0

@export_category("Schedule")
## Sunday = 0, Monday = 1, ..., Saturday = 6.
@export var weekday_indices: PackedInt32Array = PackedInt32Array()
## Absolute daily blocks: DAY 0-11, then NIGHT 12-23.
@export var day_blocks: PackedInt32Array = PackedInt32Array()

@export_category("Projection")
@export var location_id: String = ""
@export var presence_state: PresenceState = PresenceState.OFFLINE
@export var physically_present: bool = false
@export var status_text: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData


func get_display_id() -> String:
	return routine_id.strip_edges()


func matches(
	weekday_index: int,
	day_block: int,
	context: Dictionary = {}
) -> bool:
	if not weekday_indices.is_empty() \
		and not weekday_indices.has(clampi(weekday_index, 0, 6)):
		return false

	if not day_blocks.is_empty() \
		and not day_blocks.has(clampi(
			day_block,
			0,
			TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY - 1
		)):
		return false

	return conditions == null or conditions.is_met(context)


func matches_current_time(context: Dictionary = {}) -> bool:
	return matches(
		TimeManager.current_weekday_index,
		TimeManager.get_current_day_block_index(),
		context
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_weekdays: Dictionary = {}
	var seen_blocks: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("routine_id cannot be empty.")

	for weekday: int in weekday_indices:
		if weekday < 0 or weekday > 6:
			errors.append("Routine weekday must be between 0 and 6.")
		elif seen_weekdays.has(weekday):
			errors.append("Routine weekday %d is duplicated." % weekday)
		else:
			seen_weekdays[weekday] = true

	for day_block: int in day_blocks:
		if day_block < 0 \
			or day_block >= TimeManager.TOTAL_ACTION_BLOCKS_PER_DAY:
			errors.append("Routine day block must be between 0 and 23.")
		elif seen_blocks.has(day_block):
			errors.append("Routine day block %d is duplicated." % day_block)
		else:
			seen_blocks[day_block] = true

	if physically_present and location_id.strip_edges().is_empty():
		errors.append(
			"A physically present routine requires location_id."
		)

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Conditions: %s" % error)

	return errors
