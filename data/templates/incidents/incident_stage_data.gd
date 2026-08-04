extends Resource
class_name IncidentStageData


@export_category("Identity")
@export var stage_id: String = ""
@export var title: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData
@export var activity_definition: ActivityDefinitionData

@export_category("Content")
@export var dialogue: DialogueData
@export var encounter: CombatEncounter
@export var effects: Array[GameEffectData] = []
@export var next_stage_id: String = ""


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

	if activity_definition != null:
		for error: String in activity_definition.validate_data():
			errors.append("Activity: %s" % error)

	if dialogue == null and encounter == null and effects.is_empty():
		errors.append("A stage requires dialogue, encounter or effects.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]

		if effect == null:
			errors.append("Effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Effect %d: %s" % [index, error])

	return errors
