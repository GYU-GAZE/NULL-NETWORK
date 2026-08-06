extends ConditionRuleData
class_name EncyclopediaConditionData


enum Requirement {
	HAS_ANY_ENTRY,
	HAS_ENTRY,
	HAS_MILESTONE
}

enum Milestone {
	SEEN,
	SCANNED,
	DEFEATED,
	PURGED,
	PURIFIED,
	TAMED,
	LOST
}

@export var requirement: Requirement = Requirement.HAS_ANY_ENTRY
@export var entry_id: String = ""
@export var milestone: Milestone = Milestone.SEEN


func _evaluate_rule(
	_context: Dictionary,
	_active_path: Dictionary
) -> bool:
	match requirement:
		Requirement.HAS_ANY_ENTRY:
			return EncyclopediaService.has_any_entry()
		Requirement.HAS_ENTRY:
			return EncyclopediaService.has_milestone(entry_id, "seen")
		Requirement.HAS_MILESTONE:
			return EncyclopediaService.has_milestone(
				entry_id,
				Milestone.keys()[milestone].to_lower()
			)

	return false


func _validate_rule(_active_path: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if requirement != Requirement.HAS_ANY_ENTRY \
		and entry_id.strip_edges().is_empty():
		errors.append("entry_id is required for the selected requirement.")

	return errors
