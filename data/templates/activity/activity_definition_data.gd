extends Resource
class_name ActivityDefinitionData


@export_category("Identity")
@export var activity_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Time")
@export_range(0, 24, 1, "or_greater")
var action_cost: int = 0
@export var allow_cross_period: bool = true
@export var allow_cross_day: bool = false

@export_category("Confirmation")
@export var requires_confirmation: bool = true
@export_multiline var insufficient_time_message: String = ""
@export_multiline var confirmation_message: String = ""


func get_display_id() -> String:
	return activity_id.strip_edges()


func get_display_name() -> String:
	var clean_name: String = display_name.strip_edges()

	if not clean_name.is_empty():
		return clean_name

	return get_display_id()


func get_confirmation_message() -> String:
	var clean_message: String = confirmation_message.strip_edges()

	if not clean_message.is_empty():
		return clean_message

	var clean_description: String = description.strip_edges()

	if not clean_description.is_empty():
		return clean_description

	return "Begin %s?" % get_display_name()


func get_insufficient_time_message(
	required_blocks: int,
	available_blocks: int
) -> String:
	var clean_message: String = (
		insufficient_time_message.strip_edges()
	)

	if not clean_message.is_empty():
		return clean_message

	return (
		"Not enough time remaining. Required: %d blocks. "
		% required_blocks
		+ "Available: %d blocks."
		% available_blocks
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("activity_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append("display_name cannot be empty.")

	if action_cost < 0:
		errors.append("action_cost cannot be negative.")

	if allow_cross_day and not allow_cross_period:
		errors.append(
			"allow_cross_day requires allow_cross_period."
		)

	return errors
