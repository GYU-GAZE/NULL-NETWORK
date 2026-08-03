extends ConditionRuleData
class_name LocationConditionData


enum CurrentLocationRequirement {
	ANY,
	MATCH,
	DIFFERENT
}

enum DiscoveryRequirement {
	ANY,
	DISCOVERED,
	UNDISCOVERED
}

@export var location_id: String = ""
@export var current_location: CurrentLocationRequirement = (
	CurrentLocationRequirement.MATCH
)
@export var discovery: DiscoveryRequirement = DiscoveryRequirement.ANY


func _evaluate_rule(
	context: Dictionary,
	_active_path: Dictionary
) -> bool:
	var clean_id: String = location_id.strip_edges()

	if clean_id.is_empty():
		return false

	var context_location: String = str(
		context.get("location_id", "")
	).strip_edges()

	match current_location:
		CurrentLocationRequirement.MATCH:
			if context_location != clean_id:
				return false
		CurrentLocationRequirement.DIFFERENT:
			if context_location == clean_id:
				return false

	var is_discovered: bool = (
		CampaignState.discovered_location_ids.has(clean_id)
	)

	match discovery:
		DiscoveryRequirement.DISCOVERED:
			return is_discovered
		DiscoveryRequirement.UNDISCOVERED:
			return not is_discovered

	return true


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if location_id.strip_edges().is_empty():
		errors.append("location_id cannot be empty.")

	return errors
