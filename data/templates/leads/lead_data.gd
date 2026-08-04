extends Resource
class_name LeadData


enum LeadType {
	RUMOUR,
	HELP,
	SOCIAL,
	DATA_CENTER,
	ANOMALY,
	GUIDE,
	UPDATE,
	APK,
	RANKING
}

enum SourceType {
	FORUM_THREAD,
	SOCIAL_MESSAGE,
	CALENDAR,
	PARTNER,
	MICRO_UPDATE,
	RANKING,
	NAVIGATOR
}

@export_category("Identity")
@export var lead_id: String = ""
@export var lead_type: LeadType = LeadType.RUMOUR
@export var title: String = ""
@export_multiline var description: String = ""

@export_category("Source")
@export var source_type: SourceType = SourceType.FORUM_THREAD
@export var source_id: String = ""

@export_category("World Routing")
@export var location_id: String = ""
@export var discover_location_on_activation: bool = true
@export var navigator_badge: NavigatorMarkerBadge

@export_category("Progression")
@export var initial_stage_id: String = ""
@export var stages: Array[LeadStageData] = []

@export_category("Rules")
@export var conditions: ConditionSetData
@export var expiration_conditions: ConditionSetData
@export var activation_effects: Array[GameEffectData] = []
@export var completion_effects: Array[GameEffectData] = []


func get_display_id() -> String:
	return lead_id.strip_edges()


func get_initial_stage() -> LeadStageData:
	return get_stage(initial_stage_id)


func get_stage(requested_stage_id: String) -> LeadStageData:
	var clean_id: String = requested_stage_id.strip_edges()

	for stage: LeadStageData in stages:
		if stage != null and stage.get_display_id() == clean_id:
			return stage

	return null


func can_activate(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return conditions == null or conditions.is_met(
		context.to_condition_context()
	)


func is_expired(context: GameEffectContext) -> bool:
	return (
		context != null
		and expiration_conditions != null
		and expiration_conditions.is_met(context.to_condition_context())
	)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var stage_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("lead_id cannot be empty.")

	if title.strip_edges().is_empty():
		errors.append("title cannot be empty.")

	if source_id.strip_edges().is_empty():
		errors.append("source_id cannot be empty.")

	if location_id.strip_edges().is_empty():
		errors.append("location_id cannot be empty.")

	if initial_stage_id.strip_edges().is_empty():
		errors.append("initial_stage_id cannot be empty.")

	if stages.is_empty():
		errors.append("stages cannot be empty.")

	for index: int in range(stages.size()):
		var stage: LeadStageData = stages[index]

		if stage == null:
			errors.append("Stage %d is null." % index)
			continue

		var clean_stage_id: String = stage.get_display_id()

		if stage_ids.has(clean_stage_id):
			errors.append("Duplicate stage_id '%s'." % clean_stage_id)
		else:
			stage_ids[clean_stage_id] = true

		for error: String in stage.validate_data():
			errors.append("Stage %d: %s" % [index, error])

	if not initial_stage_id.strip_edges().is_empty() \
		and not stage_ids.has(initial_stage_id.strip_edges()):
		errors.append("initial_stage_id does not resolve inside the Lead.")

	for stage: LeadStageData in stages:
		if stage == null:
			continue

		var next_id: String = stage.next_stage_id.strip_edges()

		if not next_id.is_empty() and not stage_ids.has(next_id):
			errors.append(
				"Stage '%s' references unknown next_stage_id '%s'."
				% [stage.get_display_id(), next_id]
			)

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	if expiration_conditions != null:
		for error: String in expiration_conditions.validate_data():
			errors.append("Expiration condition: %s" % error)

	_validate_effects(errors, activation_effects, "Activation")
	_validate_effects(errors, completion_effects, "Completion")
	return errors


func _validate_effects(
	errors: PackedStringArray,
	effects: Array[GameEffectData],
	label: String
) -> void:
	for index: int in range(effects.size()):
		var effect: GameEffectData = effects[index]

		if effect == null:
			errors.append("%s effect %d is null." % [label, index])
			continue

		for error: String in effect.validate_data():
			errors.append("%s effect %d: %s" % [label, index, error])
