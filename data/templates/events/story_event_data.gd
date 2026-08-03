extends Resource
class_name StoryEventData


enum RepeatPolicy {
	ONCE,
	ONCE_PER_DAY,
	REPEATABLE
}

enum InterruptionPolicy {
	QUEUE,
	QUEUE_FRONT,
	IGNORE_WHILE_BUSY
}

@export_category("Identity")
@export var event_id: String = ""
@export var priority: int = 0

@export_category("Eligibility")
@export var conditions: ConditionSetData
@export var trigger: StoryEventTriggerData
@export var repeat_policy: RepeatPolicy = RepeatPolicy.ONCE

@export_category("Execution")
@export var steps: Array[StoryEventStepData] = []
@export var completion_effects: Array[GameEffectData] = []
@export var interruption_policy: InterruptionPolicy = InterruptionPolicy.QUEUE


func get_display_id() -> String:
	return event_id.strip_edges()


func is_eligible(trigger_context: Dictionary) -> bool:
	if trigger == null or not trigger.matches(trigger_context):
		return false

	return conditions == null or conditions.is_met(trigger_context)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_step_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("event_id cannot be empty.")

	if trigger == null:
		errors.append("trigger cannot be null.")
	else:
		for error: String in trigger.validate_data():
			errors.append("Trigger: %s" % error)

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	if steps.is_empty():
		errors.append("steps cannot be empty.")

	for index: int in range(steps.size()):
		var step: StoryEventStepData = steps[index]

		if step == null:
			errors.append("Step %d is null." % index)
			continue

		var clean_step_id: String = step.get_display_id()

		if not clean_step_id.is_empty() and seen_step_ids.has(clean_step_id):
			errors.append("Duplicate step_id '%s'." % clean_step_id)
		else:
			seen_step_ids[clean_step_id] = true

		for error: String in step.validate_data():
			errors.append("Step %d: %s" % [index, error])

	for index: int in range(completion_effects.size()):
		var effect: GameEffectData = completion_effects[index]

		if effect == null:
			errors.append("Completion effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Completion effect %d: %s" % [index, error])

	return errors
