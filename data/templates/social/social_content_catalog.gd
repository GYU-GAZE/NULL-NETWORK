extends Resource
class_name SocialContentCatalog


@export var profiles: Array[ChatProfileData] = []
@export var conversations: Array[ChatConversationData] = []
@export var interactions: Array[SocialInteractionData] = []


func get_profile(profile_id: String) -> ChatProfileData:
	var clean_id: String = profile_id.strip_edges()

	for profile: ChatProfileData in profiles:
		if profile != null and profile.get_display_id() == clean_id:
			return profile

	return null


func get_conversation(conversation_id: String) -> ChatConversationData:
	var clean_id: String = conversation_id.strip_edges()

	for conversation: ChatConversationData in conversations:
		if conversation != null \
			and conversation.get_display_id() == clean_id:
			return conversation

	return null


func get_interaction(interaction_id: String) -> SocialInteractionData:
	var clean_id: String = interaction_id.strip_edges()

	for interaction: SocialInteractionData in interactions:
		if interaction != null \
			and interaction.get_display_id() == clean_id:
			return interaction

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var profile_ids: Dictionary = {}
	var conversation_ids: Dictionary = {}
	var interaction_ids: Dictionary = {}

	for index: int in range(profiles.size()):
		var profile: ChatProfileData = profiles[index]

		if profile == null:
			errors.append("Profile %d is null." % index)
			continue

		var profile_id: String = profile.get_display_id()

		if profile_ids.has(profile_id):
			errors.append("Duplicate profile_id '%s'." % profile_id)
		else:
			profile_ids[profile_id] = true

		for error: String in profile.validate_data():
			errors.append("Profile %d: %s" % [index, error])

	for index: int in range(conversations.size()):
		var conversation: ChatConversationData = conversations[index]

		if conversation == null:
			errors.append("Conversation %d is null." % index)
			continue

		var conversation_id: String = conversation.get_display_id()

		if conversation_ids.has(conversation_id):
			errors.append(
				"Duplicate conversation_id '%s'." % conversation_id
			)
		else:
			conversation_ids[conversation_id] = true

		for error: String in conversation.validate_data():
			errors.append("Conversation %d: %s" % [index, error])

	for index: int in range(interactions.size()):
		var interaction: SocialInteractionData = interactions[index]

		if interaction == null:
			errors.append("Interaction %d is null." % index)
			continue

		var interaction_id: String = interaction.get_display_id()

		if interaction_ids.has(interaction_id):
			errors.append(
				"Duplicate interaction_id '%s'." % interaction_id
			)
		else:
			interaction_ids[interaction_id] = true

		for error: String in interaction.validate_data():
			errors.append("Interaction %d: %s" % [index, error])

	for conversation: ChatConversationData in conversations:
		if conversation == null:
			continue

		if not profile_ids.has(conversation.get_profile_id()):
			errors.append(
				"Conversation '%s' references unknown profile '%s'."
				% [
					conversation.get_display_id(),
					conversation.get_profile_id()
				]
			)

		for choice: ChatChoiceData in conversation.choices:
			if choice == null:
				continue

			var interaction: SocialInteractionData = get_interaction(
				choice.get_interaction_id()
			)

			if interaction == null:
				errors.append(
					"Conversation '%s' choice '%s' references unknown interaction '%s'."
					% [
						conversation.get_display_id(),
						choice.get_display_id(),
						choice.get_interaction_id()
					]
				)
				continue

			if interaction.get_conversation_id() \
				!= conversation.get_display_id():
				errors.append(
					"Interaction '%s' belongs to conversation '%s', not '%s'."
					% [
						interaction.get_display_id(),
						interaction.get_conversation_id(),
						conversation.get_display_id()
					]
				)

			if interaction.get_npc_id() != conversation.get_npc_id():
				errors.append(
					"Interaction '%s' NPC does not match conversation '%s'."
					% [
						interaction.get_display_id(),
						conversation.get_display_id()
					]
				)

			_validate_interaction_messages(
				errors,
				conversation,
				interaction
			)

	return errors


func _validate_interaction_messages(
	errors: PackedStringArray,
	conversation: ChatConversationData,
	interaction: SocialInteractionData
) -> void:
	var player_message_id: String = interaction.player_message_id.strip_edges()

	if conversation.get_message(player_message_id) == null:
		errors.append(
			"Interaction '%s' references unknown player message '%s'."
			% [interaction.get_display_id(), player_message_id]
		)

	for response_id: String in interaction.response_message_ids:
		var clean_id: String = response_id.strip_edges()

		if conversation.get_message(clean_id) == null:
			errors.append(
				"Interaction '%s' references unknown response message '%s'."
				% [interaction.get_display_id(), clean_id]
			)
