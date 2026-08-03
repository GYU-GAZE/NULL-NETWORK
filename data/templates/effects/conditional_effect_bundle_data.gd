extends Resource
class_name ConditionalEffectBundleData


@export var bundle_id: String = ""
@export var conditions: ConditionSetData
@export var effects: Array[GameEffectData] = []


func can_execute(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return (
		conditions == null
		or conditions.is_met(context.to_condition_context())
	)


func execute(context: GameEffectContext) -> bool:
	if not can_execute(context):
		return false

	return GameEffectData.apply_all(effects, context).is_empty()


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if bundle_id.strip_edges().is_empty():
		errors.append("bundle_id cannot be empty.")

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
