extends RefCounted
class_name SocialInboxProjectionService


## Projects newly unlocked immutable chat content into the persistent inbox.
##
## This service deliberately does not open conversations. Delivery and read
## state are separate operations, so opening the Social App cannot mark every
## contact as read before the player actually selects that conversation.

static func synchronize_available_conversations() -> int:
	if not CampaignState.has_campaign():
		return 0

	var delivered_count: int = 0

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_CONVERSATIONS
	):
		var conversation := resource as ChatConversationData

		if conversation == null:
			continue

		var context: Dictionary = _make_condition_context(conversation)

		if not conversation.is_unlocked(context):
			continue

		if not SocialService.has_contact(conversation.get_npc_id()) \
			and not SocialService.discover_contact(
				conversation.get_npc_id(),
				context
			):
			continue

		for message_id: String in conversation.initial_message_ids:
			var message: ChatMessageData = conversation.get_message(message_id)

			if message == null or not message.can_deliver(context):
				continue

			var entry_id: String = "initial::%s::%s" % [
				conversation.get_display_id(),
				message.get_display_id()
			]

			if _history_has_entry(
				conversation.get_display_id(),
				entry_id
			):
				continue

			if SocialService.append_message(
				conversation.get_display_id(),
				_build_saved_message(conversation, message, entry_id),
				message.unread_when_delivered
			):
				delivered_count += 1

	return delivered_count


static func _history_has_entry(
	conversation_id: String,
	entry_id: String
) -> bool:
	for entry: Dictionary in SocialService.get_conversation_history(
		conversation_id
	):
		if str(entry.get("entry_id", "")).strip_edges() \
			== entry_id.strip_edges():
			return true

	return false


static func _build_saved_message(
	conversation: ChatConversationData,
	message: ChatMessageData,
	entry_id: String
) -> Dictionary:
	return {
		"entry_id": entry_id.strip_edges(),
		"message_id": message.get_display_id(),
		"npc_id": conversation.get_npc_id(),
		"delivered_action_index": TimeManager.get_total_action_index(),
		"delivered_day": TimeManager.days_passed,
		"delivered_period": int(TimeManager.current_period),
		"delivered_action_block": TimeManager.current_action_block
	}


static func _make_condition_context(
	conversation: ChatConversationData
) -> Dictionary:
	return GameEffectContext.create(
		"social.inbox.sync",
		conversation.get_npc_id(),
		CampaignState.current_location_id,
		"",
		conversation.get_display_id()
	).to_condition_context()
