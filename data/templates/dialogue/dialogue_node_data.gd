extends Resource
class_name DialogueNodeData


const MAX_CHOICES: int = 6

@export_category("Identity")
@export var node_id: String = ""
@export var speaker_id: String = ""
@export_multiline var text: String = ""

@export_category("Presentation")
@export var portrait_states: Array[DialoguePortraitState] = []

@export_category("Rules")
@export var conditions: ConditionSetData
@export var effects_on_enter: Array[GameEffectData] = []
@export var choices: Array[DialogueChoiceData] = []
@export var next_node_id: String = ""


func get_display_id() -> String:
	return node_id.strip_edges()


func is_available(context: GameEffectContext) -> bool:
	if context == null:
		return false

	return (
		conditions == null
		or conditions.is_met(context.to_condition_context())
	)


func get_choice(choice_id: String) -> DialogueChoiceData:
	var clean_id: String = choice_id.strip_edges()

	for choice: DialogueChoiceData in choices:
		if choice != null and choice.get_display_id() == clean_id:
			return choice

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_slots: Dictionary = {}
	var seen_choice_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("node_id cannot be empty.")

	if speaker_id.strip_edges().is_empty():
		errors.append("speaker_id cannot be empty.")

	if text.strip_edges().is_empty():
		errors.append("text cannot be empty.")

	if conditions != null:
		for error: String in conditions.validate_data():
			errors.append("Condition: %s" % error)

	for index: int in range(portrait_states.size()):
		var state: DialoguePortraitState = portrait_states[index]

		if state == null:
			errors.append("Portrait state %d is null." % index)
			continue

		var slot_key: String = state.get_slot_key()

		if seen_slots.has(slot_key):
			errors.append("Duplicate portrait slot '%s'." % slot_key)
		else:
			seen_slots[slot_key] = true

		for error: String in state.validate_data():
			errors.append("Portrait state %d: %s" % [index, error])

	for index: int in range(effects_on_enter.size()):
		var effect: GameEffectData = effects_on_enter[index]

		if effect == null:
			errors.append("Enter effect %d is null." % index)
			continue

		for error: String in effect.validate_data():
			errors.append("Enter effect %d: %s" % [index, error])

	if choices.size() > MAX_CHOICES:
		errors.append("A dialogue node supports at most six choices.")

	for index: int in range(choices.size()):
		var choice: DialogueChoiceData = choices[index]

		if choice == null:
			errors.append("Choice %d is null." % index)
			continue

		var clean_choice_id: String = choice.get_display_id()

		if not clean_choice_id.is_empty() and seen_choice_ids.has(clean_choice_id):
			errors.append("Duplicate choice_id '%s'." % clean_choice_id)
		else:
			seen_choice_ids[clean_choice_id] = true

		for error: String in choice.validate_data():
			errors.append("Choice %d: %s" % [index, error])

	return errors
