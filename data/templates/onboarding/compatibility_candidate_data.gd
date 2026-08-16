extends Resource
class_name CompatibilityCandidateData

enum CandidateClass { STANDARD, EXTENDED }

@export var candidate_id: String = ""
@export var display_name: String = ""
@export var apk_id: String = ""
@export var candidate_class: CandidateClass = CandidateClass.EXTENDED
@export var axis_targets: Dictionary = {}
@export var axis_importance: Dictionary = {}
@export_multiline var compatibility_fantasy: String = ""

func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	if candidate_id.strip_edges().is_empty():
		errors.append("Compatibility candidate requires an id.")
	if display_name.strip_edges().is_empty():
		errors.append("Compatibility candidate '%s' requires a display name." % candidate_id)
	var axes := PackedStringArray(["INI", "STR", "SOC", "EXP", "ATT", "CUR", "ASP"])
	for axis: String in axes:
		if not axis_targets.has(axis):
			errors.append("Candidate '%s' is missing target %s." % [candidate_id, axis])
		if not axis_importance.has(axis):
			errors.append("Candidate '%s' is missing importance %s." % [candidate_id, axis])
		elif int(axis_importance.get(axis, -1)) not in [0, 1, 2]:
			errors.append("Candidate '%s' has invalid importance for %s." % [candidate_id, axis])
	return errors
