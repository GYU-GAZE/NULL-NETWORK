extends Resource
class_name LeadStageData


@export_category("Identity")
@export var stage_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export_category("Routing")
@export var location_id: String = ""
@export var incident_id: String = ""
@export var next_stage_id: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData
@export var completion_effects: Array[GameEffectData] = []


func get_display_id() -> String:
	return stage_id.strip_edges()


func is_available(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return conditions == null or conditions.is_met(
		context.to_condition_context()
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if get_display_id().is_empty():
		errors.append("stage_id cannot be empty.")

	if location_id.strip_edges().is_empty():
		errors.append("location_id cannot be empty.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	for index: int in range(completion_effects.size()):
		var effect: GameEffectData = completion_effects[index]

		if effect == null:
			errors.append("Completion effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Completion effect %d: %s" % [index, error])

	return errors
