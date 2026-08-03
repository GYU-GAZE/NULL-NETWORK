extends ConditionRuleData
class_name AffinityConditionData


@export var npc_id: String = ""
@export var use_context_target_when_empty: bool = true
@export var minimum_value: int = 0
@export var maximum_value: int = -1


func _evaluate_rule(
	context: Dictionary,
	_active_path: Dictionary
) -> bool:
	var resolved_id: String = _resolve_npc_id(context)

	if resolved_id.is_empty():
		return false

	var value: int = CampaignState.get_affinity(resolved_id)
	return (
		value >= minimum_value
		and (maximum_value == -1 or value <= maximum_value)
	)


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if npc_id.strip_edges().is_empty() and not use_context_target_when_empty:
		errors.append(
			"npc_id cannot be empty when context target fallback is disabled."
		)

	if maximum_value != -1 and maximum_value < minimum_value:
		errors.append(
			"maximum_value must be -1 or greater than or equal to minimum_value."
		)

	return errors


func _resolve_npc_id(context: Dictionary) -> String:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() and use_context_target_when_empty:
		clean_id = str(context.get("target_id", "")).strip_edges()

	return clean_id
