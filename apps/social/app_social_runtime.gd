extends "res://apps/social/app_social.gd"
class_name SocialRuntimeApp


func _ready() -> void:
	super._ready()
	contacts_title.text = "FRIENDS"
	contact_search.placeholder_text = "SEARCH FRIENDS"


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
			or conversation.get_profile_id() != clean_profile_id \
			or not SocialService.is_friend(conversation.get_npc_id()):
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


func _render_selected_conversation() -> void:
	super._render_selected_conversation()

	var conversation: ChatConversationData = (
		SocialService.get_chat_conversation(
			get_selected_conversation_id()
		)
	)

	if conversation == null:
		return

	var npc_id: String = conversation.get_npc_id()
	var partner_state: NPCPartyPartnerStateData = (
		SocialService.get_party_partner_state(npc_id)
	)

	if partner_state == null:
		return

	if partner_state.lost:
		presence_label.text = "%s // PARTNER LOST" % presence_label.text
		return

	var party_status: String = (
		" // IN PARTY"
		if SocialService.is_party_member(npc_id)
		else ""
	)
	presence_label.text = "%s%s // APK LV.%d" % [
		presence_label.text,
		party_status,
		partner_state.level
	]
