extends Resource
class_name IncidentData


@export_category("Identity")
@export var incident_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var location_id: String = ""

@export_category("Rules")
@export var conditions: ConditionSetData
@export var activity_definition: ActivityDefinitionData

@export_category("Primary Content")
@export var dialogue: DialogueData
@export var encounter: CombatEncounter
@export var effects: Array[GameEffectData] = []

@export_category("Extended Stages")
@export var initial_stage_id: String = ""
@export var stages: Array[IncidentStageData] = []

@export_category("Resolution")
@export var resolution_branches: Array[IncidentResolutionBranchData] = []


func get_display_id() -> String:
	return incident_id.strip_edges()


func can_start(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return conditions == null or conditions.is_met(
		context.to_condition_context()
	)


func get_initial_stage() -> IncidentStageData:
	return get_stage(initial_stage_id)


func get_stage(stage_id: String) -> IncidentStageData:
	var clean_id: String = stage_id.strip_edges()

	for stage: IncidentStageData in stages:
		if stage != null and stage.get_display_id() == clean_id:
			return stage

	return null


func get_resolution_branch(
	requested_outcome: CombatResult.Outcome,
	context: GameEffectContext
) -> IncidentResolutionBranchData:
	for branch: IncidentResolutionBranchData in resolution_branches:
		if branch != null \
			and branch.outcome == requested_outcome \
			and branch.is_available(context):
			return branch

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var stage_ids: Dictionary = {}
	var outcome_counts: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("incident_id cannot be empty.")

	if title.strip_edges().is_empty():
		errors.append("title cannot be empty.")

	if location_id.strip_edges().is_empty():
		errors.append("location_id cannot be empty.")

	if activity_definition == null:
		errors.append("activity_definition cannot be null.")
	else:
		for error: String in activity_definition.validate_data():
			errors.append("Activity: %s" % error)

	if dialogue == null and encounter == null and stages.is_empty():
		errors.append("Incident requires primary content or stages.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	_validate_effects(errors, effects, "Incident")

	for index: int in range(stages.size()):
		var stage: IncidentStageData = stages[index]

		if stage == null:
			errors.append("Stage %d is null." % index)
			continue

		var stage_id: String = stage.get_display_id()

		if stage_ids.has(stage_id):
			errors.append("Duplicate stage_id '%s'." % stage_id)
		else:
			stage_ids[stage_id] = true

		for error: String in stage.validate_data():
			errors.append("Stage %d: %s" % [index, error])

	if not stages.is_empty():
		if initial_stage_id.strip_edges().is_empty():
			errors.append("initial_stage_id is required when stages exist.")
		elif not stage_ids.has(initial_stage_id.strip_edges()):
			errors.append("initial_stage_id does not resolve inside the Incident.")

	for stage: IncidentStageData in stages:
		if stage == null:
			continue

		var next_id: String = stage.next_stage_id.strip_edges()

		if not next_id.is_empty() and not stage_ids.has(next_id):
			errors.append(
				"Stage '%s' references unknown next_stage_id '%s'."
				% [stage.get_display_id(), next_id]
			)

	for index: int in range(resolution_branches.size()):
		var branch: IncidentResolutionBranchData = resolution_branches[index]

		if branch == null:
			errors.append("Resolution branch %d is null." % index)
			continue

		var outcome_key: int = int(branch.outcome)
		outcome_counts[outcome_key] = int(outcome_counts.get(outcome_key, 0)) + 1

		for error: String in branch.validate_data():
			errors.append("Resolution branch %d: %s" % [index, error])

	return errors


func _validate_effects(
	errors: PackedStringArray,
	effect_list: Array[GameEffectData],
	label: String
) -> void:
	for index: int in range(effect_list.size()):
		var effect: GameEffectData = effect_list[index]

		if effect == null:
			errors.append("%s effect %d is null." % [label, index])
			continue

		for error: String in effect.validate_data():
			errors.append("%s effect %d: %s" % [label, index, error])
