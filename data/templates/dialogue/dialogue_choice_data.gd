extends Resource
class_name DialogueChoiceData


const TENDENCY_COUNT: int = 4

@export_category("Identity")
@export var choice_id: String = ""
@export_multiline var text: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData
@export var effects: Array[GameEffectData] = []
## Ordered as VALOUR, LOGIC, SYNC and SELF.
@export var tendency_changes: Array[int] = [0, 0, 0, 0]
@export var next_node_id: String = ""
@export var activity_definition: ActivityDefinitionData


func get_display_id() -> String:
	return choice_id.strip_edges()


func is_available(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return (
		conditions == null
		or conditions.is_met(context.to_condition_context())
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("choice_id cannot be empty.")

	if text.strip_edges().is_empty():
		errors.append("text cannot be empty.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	if tendency_changes.size() != TENDENCY_COUNT:
		errors.append(
			"tendency_changes must contain VALOUR, LOGIC, SYNC and SELF."
		)

	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]

		if effect == null:
			errors.append("Effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Effect %d: %s" % [index, error])

	if activity_definition != null:
		for error: String in activity_definition.validate_data():
			errors.append("Activity: %s" % error)

	return errors
