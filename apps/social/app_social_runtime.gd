extends "res://apps/social/app_social.gd"
class_name SocialRuntimeApp


func _synchronize_unlocked_conversations() -> void:
	SocialInboxProjectionService.synchronize_available_conversations()


func _get_primary_conversation(profile_id: String) -> ChatConversationData:
	var candidates: Array[ChatConversationData] = []
	var clean_profile_id: String = profile_id.strip_edges()

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_CONVERSATIONS
	):
		var conversation := resource as ChatConversationData

		if conversation == null \
			or conversation.get_profile_id() != clean_profile_id:
			continue

		var context: Dictionary = GameEffectContext.create(
			"social.app.profile",
			conversation.get_npc_id(),
			CampaignState.current_location_id,
			"",
			conversation.get_display_id()
		).to_condition_context()

		if conversation.is_unlocked(context):
			candidates.append(conversation)

	candidates.sort_custom(
		func(left: ChatConversationData, right: ChatConversationData) -> bool:
			return left.get_display_id() < right.get_display_id()
	)
	return candidates[0] if not candidates.is_empty() else null
