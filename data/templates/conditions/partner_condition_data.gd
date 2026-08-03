extends ConditionRuleData
class_name PartnerConditionData


enum Requirement {
	HAS_ANY,
	HAS_NONE,
	MATCHES,
	DOES_NOT_MATCH
}

@export var requirement: Requirement = Requirement.HAS_ANY
@export var partner_id: String = ""


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	var current_id: String = CampaignState.partner_id.strip_edges()
	var expected_id: String = partner_id.strip_edges()

	match requirement:
		Requirement.HAS_ANY:
			return not current_id.is_empty()
		Requirement.HAS_NONE:
			return current_id.is_empty()
		Requirement.MATCHES:
			return not expected_id.is_empty() and current_id == expected_id
		Requirement.DOES_NOT_MATCH:
			return not expected_id.is_empty() and current_id != expected_id

	return false


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if requirement in [Requirement.MATCHES, Requirement.DOES_NOT_MATCH] \
		and partner_id.strip_edges().is_empty():
		errors.append("partner_id is required for the selected requirement.")

	return errors
