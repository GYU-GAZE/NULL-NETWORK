extends "res://core/autoloads/social_service.gd"


signal friendship_changed(npc_id: String, is_friend: bool)


## Concrete campaign runtime for the Social domain.
##
## World discovery and friendship are deliberately distinct:
## - known contact: the Operator has identified the NPC;
## - friend: the NPC is present in the Social friend list and may chat/party.
##
## The legacy SocialService.has_contact() contract is narrowed here to mean a
## usable Social contact, therefore a friend. World systems can query
## has_known_contact() when friendship is not required.

func _ready() -> void:
	_state = FriendListSocialStateData.new()
	super._ready()


func add_friend(
	npc_id: String,
	context: Dictionary = {}
) -> bool:
	if not CampaignState.has_campaign():
		return false

	var npc: NPCData = get_npc(npc_id)

	if npc == null or not npc.can_unlock_contact(context):
		return false

	var state: FriendListSocialStateData = _get_friend_state()

	if state == null:
		return false

	var was_known: bool = state.has_contact(npc.get_display_id())

	if not state.add_friend(npc.get_display_id()):
		return false

	_commit(npc.get_display_id())

	if not was_known:
		contact_discovered.emit(npc.get_display_id())

	friendship_changed.emit(npc.get_display_id(), true)
	return true


func remove_friend(npc_id: String) -> bool:
	var clean_id: String = npc_id.strip_edges()
	var state: FriendListSocialStateData = _get_friend_state()

	if clean_id.is_empty() \
		or state == null \
		or not state.is_friend(clean_id):
		return false

	# Party membership is a privilege of the friendship relation. Removing a
	# friend cannot leave an invisible combat ally behind.
	if state.is_party_member(clean_id):
		state.remove_party_member(clean_id)
		party_changed.emit(clean_id, false)

	state.remove_friend(clean_id)
	_commit(clean_id)
	friendship_changed.emit(clean_id, false)
	return true


func is_friend(npc_id: String) -> bool:
	var state: FriendListSocialStateData = _get_friend_state()
	return state != null and state.is_friend(npc_id)


func has_contact(npc_id: String) -> bool:
	# Social contacts are exactly the player's friends.
	return is_friend(npc_id)


func has_known_contact(npc_id: String) -> bool:
	return _state.has_contact(npc_id)


func get_friend_ids() -> PackedStringArray:
	var state: FriendListSocialStateData = _get_friend_state()
	return state.get_friend_ids() if state != null else PackedStringArray()


func get_friends() -> Array[NPCData]:
	var result: Array[NPCData] = []

	for npc_id: String in get_friend_ids():
		var npc: NPCData = get_npc(npc_id)

		if npc != null:
			result.append(npc)

	return result


func get_contacts() -> Array[NPCData]:
	return get_friends()


func get_visible_chat_profiles(
	context: Dictionary = {}
) -> Array[ChatProfileData]:
	var result: Array[ChatProfileData] = []

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_PROFILES
	):
		var profile := resource as ChatProfileData

		if profile == null \
			or not is_friend(profile.get_npc_id()) \
			or not profile.is_visible(context):
			continue

		result.append(profile)

	result.sort_custom(
		func(left: ChatProfileData, right: ChatProfileData) -> bool:
			if left.pinned != right.pinned:
				return left.pinned

			if left.sort_order != right.sort_order:
				return left.sort_order < right.sort_order

			return left.get_display_id() < right.get_display_id()
	)
	return result


func open_conversation(conversation_id: String) -> bool:
	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)

	if conversation == null:
		return false

	if not is_friend(conversation.get_npc_id()):
		if not conversation.auto_add_friend_on_unlock:
			return false

		var context: Dictionary = GameEffectContext.create(
			"social.conversation.friendship",
			conversation.get_npc_id(),
			CampaignState.current_location_id,
			"",
			conversation.get_display_id()
		).to_condition_context()

		if not conversation.is_unlocked(context) \
			or not add_friend(conversation.get_npc_id(), context):
			return false

	return super.open_conversation(conversation_id)


func get_available_chat_choices(
	conversation_id: String
) -> Array[ChatChoiceData]:
	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)
	var empty_result: Array[ChatChoiceData] = []

	if conversation == null or not is_friend(conversation.get_npc_id()):
		return empty_result

	return super.get_available_chat_choices(conversation_id)


func add_party_member(
	npc_id: String,
	owner_id: String
) -> bool:
	if not is_friend(npc_id):
		return false

	return super.add_party_member(npc_id, owner_id)


func get_party_membership(npc_id: String) -> Dictionary:
	return _state.get_party_membership(npc_id)


func get_state_snapshot() -> SocialStateData:
	var snapshot := FriendListSocialStateData.new()
	snapshot.load_save_data(_state.to_save_data())
	return snapshot


func _commit(npc_id: String) -> void:
	super._commit(npc_id)

	var checkpoint_suffix: String = npc_id.strip_edges()

	if checkpoint_suffix.is_empty():
		checkpoint_suffix = "global"

	SaveManager.request_checkpoint(
		StringName("social.state.%s" % checkpoint_suffix),
		false
	)


func _get_friend_state() -> FriendListSocialStateData:
	return _state as FriendListSocialStateData
