extends Resource
class_name SocialInteractionData


enum RepeatPolicy {
	ONCE,
	REPEATABLE
}


@export_category("Identity")
@export var interaction_id: String = ""
@export var conversation_id: String = ""
@export var npc_id: String = ""

@export_category("Execution")
@export var repeat_policy: RepeatPolicy = RepeatPolicy.ONCE
## Zero means unlimited when repeat_policy is REPEATABLE.
@export_range(0, 999, 1) var max_executions: int = 1
@export var requires_contact: bool = true
@export var activity: ActivityDefinitionData
@export var conditions: ConditionSetData

@export_category("Conversation Result")
@export var player_message_id: String = ""
@export var response_message_ids: PackedStringArray = PackedStringArray()
@export var effects: ConditionalEffectBundleData


func get_display_id() -> String:
	return interaction_id.strip_edges()


func get_conversation_id() -> String:
	return conversation_id.strip_edges()


func get_npc_id() -> String:
	return npc_id.strip_edges()


func can_execute(
	context: Dictionary,
	execution_count: int
) -> bool:
	if repeat_policy == RepeatPolicy.ONCE and execution_count > 0:
		return false

	if repeat_policy == RepeatPolicy.REPEATABLE \
		and max_executions > 0 \
		and execution_count >= max_executions:
		return false

	return conditions == null or conditions.is_met(context)


func execute_effects(context: GameEffectContext) -> bool:
	if effects == null:
		return true

	return effects.execute(context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_response_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("interaction_id cannot be empty.")

	if get_conversation_id().is_empty():
		errors.append("conversation_id cannot be empty.")

	if get_npc_id().is_empty():
		errors.append("npc_id cannot be empty.")

	if player_message_id.strip_edges().is_empty():
		errors.append("player_message_id cannot be empty.")

	if repeat_policy == RepeatPolicy.ONCE and max_executions != 1:
		errors.append("ONCE interactions require max_executions = 1.")

	for response_id: String in response_message_ids:
		var clean_id: String = response_id.strip_edges()

		if clean_id.is_empty():
			errors.append("response_message_ids cannot contain an empty ID.")
		elif seen_response_ids.has(clean_id):
			errors.append("Duplicate response message '%s'." % clean_id)
		else:
			seen_response_ids[clean_id] = true

	if activity != null:
		for error: String in activity.validate_data():
			errors.append("Activity: %s" % error)

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	if effects != null:
		for error: String in effects.validate_data():
			errors.append("Effect bundle: %s" % error)

	return errors
