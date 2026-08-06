extends Resource
class_name ChatConversationData


@export_category("Identity")
@export var conversation_id: String = ""
@export var profile_id: String = ""
@export var npc_id: String = ""
@export var title: String = ""

@export_category("Availability")
@export var unlock_conditions: ConditionSetData
## Integration and story-triggered conversations may establish friendship when
## they become available. Normal conversations require an existing friend.
@export var auto_add_friend_on_unlock: bool = false

@export_category("Content")
@export var initial_message_ids: PackedStringArray = PackedStringArray()
@export var messages: Array[ChatMessageData] = []
@export var choices: Array[ChatChoiceData] = []


func get_display_id() -> String:
	return conversation_id.strip_edges()


func get_profile_id() -> String:
	return profile_id.strip_edges()


func get_npc_id() -> String:
	return npc_id.strip_edges()


func get_title() -> String:
	var clean_title: String = title.strip_edges()

	if not clean_title.is_empty():
		return clean_title

	return get_display_id()


func is_unlocked(context: Dictionary = {}) -> bool:
	return unlock_conditions == null \
		or unlock_conditions.is_met(context)


func get_message(message_id: String) -> ChatMessageData:
	var clean_id: String = message_id.strip_edges()

	for message: ChatMessageData in messages:
		if message != null and message.get_display_id() == clean_id:
			return message

	return null


func get_choice(choice_id: String) -> ChatChoiceData:
	var clean_id: String = choice_id.strip_edges()

	for choice: ChatChoiceData in choices:
		if choice != null and choice.get_display_id() == clean_id:
			return choice

	return null


func get_available_choices(context: Dictionary = {}) -> Array[ChatChoiceData]:
	var result: Array[ChatChoiceData] = []

	for choice: ChatChoiceData in choices:
		if choice != null and choice.is_available(context):
			result.append(choice)

	result.sort_custom(
		func(left: ChatChoiceData, right: ChatChoiceData) -> bool:
			return left.sort_order < right.sort_order
	)
	return result


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var message_ids: Dictionary = {}
	var choice_ids: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("conversation_id cannot be empty.")

	if get_profile_id().is_empty():
		errors.append("profile_id cannot be empty.")

	if get_npc_id().is_empty():
		errors.append("npc_id cannot be empty.")

	if unlock_conditions != null:
		for error: String in unlock_conditions.validate_data():
			errors.append("Unlock condition: %s" % error)

	for index: int in range(messages.size()):
		var message: ChatMessageData = messages[index]

		if message == null:
			errors.append("Message %d is null." % index)
			continue

		var message_id: String = message.get_display_id()

		if message_ids.has(message_id):
			errors.append("Duplicate message_id '%s'." % message_id)
		else:
			message_ids[message_id] = true

		for error: String in message.validate_data():
			errors.append("Message %d: %s" % [index, error])

	for initial_message_id: String in initial_message_ids:
		var clean_id: String = initial_message_id.strip_edges()

		if clean_id.is_empty():
			errors.append("initial_message_ids cannot contain an empty ID.")
		elif not message_ids.has(clean_id):
			errors.append(
				"Initial message '%s' is not present in messages."
				% clean_id
			)

	for index: int in range(choices.size()):
		var choice: ChatChoiceData = choices[index]

		if choice == null:
			errors.append("Choice %d is null." % index)
			continue

		var choice_id: String = choice.get_display_id()

		if choice_ids.has(choice_id):
			errors.append("Duplicate choice_id '%s'." % choice_id)
		else:
			choice_ids[choice_id] = true

		for error: String in choice.validate_data():
			errors.append("Choice %d: %s" % [index, error])

	return errors
