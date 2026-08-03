extends Resource
class_name GameEffectData


@export var effect_id: String = ""
@export var conditions: ConditionSetData


func can_apply(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return (
		conditions == null
		or conditions.is_met(context.to_condition_context())
	)


func apply(context: GameEffectContext) -> bool:
	if context == null:
		return false

	if not can_apply(context):
		return true

	return _apply_effect(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	if effect_id.strip_edges().is_empty():
		errors.append("effect_id cannot be empty.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	errors.append_array(_validate_effect())
	return errors


static func apply_all(
	effects: Array[GameEffectData],
	context: GameEffectContext
) -> PackedStringArray:
	var failed_effect_ids := PackedStringArray()

	if context == null:
		failed_effect_ids.append("<missing_context>")
		return failed_effect_ids

	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]

		if effect == null:
			failed_effect_ids.append("<null:%d>" % index)
			continue

		if not effect.apply(context):
			var clean_id: String = effect.effect_id.strip_edges()
			failed_effect_ids.append(
				clean_id if not clean_id.is_empty() else "<effect:%d>" % index
			)

	return failed_effect_ids


func _apply_effect(_context: GameEffectContext) -> bool:
	push_error("GameEffectData must be specialized before application.")
	return false


func _validate_effect() -> PackedStringArray:
	return PackedStringArray()
