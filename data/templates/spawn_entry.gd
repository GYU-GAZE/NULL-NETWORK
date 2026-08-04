extends Resource
class_name SpawnEntry

@export_category("Identity")
@export var spawn_id: String = ""
@export var display_name: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData
@export var encounter: CombatEncounter
@export var activity: ActivityDefinitionData
@export_range(1, 100000, 1, "or_greater")
var weight: int = 10


func get_display_id() -> String:
	return spawn_id.strip_edges()


func is_available(context: Dictionary = {}) -> bool:
	return conditions == null or conditions.is_met(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("spawn_id cannot be empty.")

	if encounter == null:
		errors.append("encounter cannot be null.")

	if activity == null:
		errors.append("activity cannot be null.")
	else:
		for error: String in activity.validate_data():
			errors.append("Activity: %s" % error)

	if weight <= 0:
		errors.append("weight must be greater than zero.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	return errors
