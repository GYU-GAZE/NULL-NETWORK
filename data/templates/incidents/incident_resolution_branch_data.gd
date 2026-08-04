extends Resource
class_name IncidentResolutionBranchData


@export var outcome: CombatResult.Outcome = CombatResult.Outcome.VICTORY
@export var conditions: ConditionSetData
@export var effects: Array[GameEffectData] = []
@export var completes_incident: bool = true
@export var completes_lead: bool = true


func is_available(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return conditions == null or conditions.is_met(
		context.to_condition_context()
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

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
