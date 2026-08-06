extends "res://core/autoloads/social_service.gd"


signal friendship_changed(npc_id: String, is_friend: bool)
signal party_partner_progressed(
	npc_id: String,
	experience_gain: int,
	old_level: int,
	new_level: int
)
signal party_partner_lost(
	npc_id: String,
	character_id: String,
	encounter_id: String
)


## Concrete campaign runtime for the Social domain.
##
## World discovery and friendship are deliberately distinct:
## - known contact: the Operator has identified the NPC;
## - friend: the NPC is present in the Social friend list and may chat/party.
##
## NPC party membership and NPC partner progression are also distinct. Leaving
## the party keeps EXP and HP. Reaching 0 HP marks that partner as permanently
## lost and prevents the same state from being re-added.

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
	# friend cannot leave an invisible combat ally behind. Partner progression
	# remains stored so re-friending cannot reset EXP or erase a death.
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

	var partner_state: NPCPartyPartnerStateData = (
		ensure_party_partner_state(npc_id)
	)

	if partner_state == null or not partner_state.is_alive():
		return false

	return super.add_party_member(npc_id, owner_id)


func is_party_member(npc_id: String) -> bool:
	if not _state.is_party_member(npc_id):
		return false

	var partner_state: NPCPartyPartnerStateData = (
		ensure_party_partner_state(npc_id)
	)
	return partner_state != null and partner_state.is_alive()


func get_party_member_ids() -> PackedStringArray:
	var result := PackedStringArray()

	for npc_id: String in _state.get_party_member_ids():
		var partner_state: NPCPartyPartnerStateData = (
			ensure_party_partner_state(npc_id)
		)

		if partner_state != null and partner_state.is_alive():
			result.append(npc_id)

	result.sort()
	return result


func get_party_membership(npc_id: String) -> Dictionary:
	return _state.get_party_membership(npc_id)


func ensure_party_partner_state(
	npc_id: String
) -> NPCPartyPartnerStateData:
	var clean_id: String = npc_id.strip_edges()
	var npc: NPCData = get_npc(clean_id)

	if clean_id.is_empty() \
		or npc == null \
		or npc.party_loadout == null:
		return null

	var existing: NPCPartyPartnerStateData = (
		_state.get_party_partner_state(clean_id)
	)

	if existing != null:
		if existing.is_compatible_with(clean_id, npc.party_loadout):
			return existing

		# A different character_id represents a replacement partner. Replacing
		# a permanently lost APK must be an explicit narrative Effect, not an
		# implicit migration performed while loading combat.
		return null

	var created := NPCPartyPartnerStateData.new()

	if not created.initialize_from_loadout(clean_id, npc.party_loadout):
		return null

	if not _state.set_party_partner_state(created):
		return null

	_commit(clean_id)
	return created.duplicate_state()


func get_party_partner_state(
	npc_id: String
) -> NPCPartyPartnerStateData:
	var state: NPCPartyPartnerStateData = _state.get_party_partner_state(npc_id)
	return state.duplicate_state() if state != null else null


func is_party_partner_lost(npc_id: String) -> bool:
	var state: NPCPartyPartnerStateData = _state.get_party_partner_state(npc_id)
	return state != null and state.lost


func create_party_partner_combat_loadout(
	npc_id: String
) -> CharacterLoadout:
	var clean_id: String = npc_id.strip_edges()
	var npc: NPCData = get_npc(clean_id)
	var state: NPCPartyPartnerStateData = ensure_party_partner_state(clean_id)

	if npc == null \
		or npc.party_loadout == null \
		or state == null \
		or not state.is_alive():
		return null

	var loadout := npc.party_loadout.duplicate(true) as CharacterLoadout

	if loadout == null:
		return null

	loadout.level = state.level
	loadout.starting_hp = clampi(state.current_hp, 0, maxi(1, loadout.max_hp))
	loadout.starting_stability = clampi(
		state.current_stability,
		0,
		maxi(1, loadout.max_stability)
	)
	return loadout


func commit_party_partner_combat_actor(
	npc_id: String,
	actor: Dictionary,
	encounter_id: String
) -> Dictionary:
	var clean_id: String = npc_id.strip_edges()
	var result := {
		"npc_id": clean_id,
		"lost": false,
		"membership_removed": false
	}

	if clean_id.is_empty() \
		or actor.is_empty() \
		or int(actor.get("source_kind", -1)) \
		!= CombatSlotData.ParticipantSource.PARTY_MEMBER:
		return result

	var state: NPCPartyPartnerStateData = ensure_party_partner_state(clean_id)

	if state == null:
		return result

	state.update_combat_vitals(
		roundi(float(actor.get("hp", 0.0))),
		roundi(float(actor.get("stability", 0.0))),
		roundi(float(actor.get("max_hp", 1.0))),
		roundi(float(actor.get("max_stability", 100.0)))
	)
	var defeated: bool = (
		float(actor.get("hp", 0.0)) <= 0.0
		or bool(actor.get("defeated", false))
		or bool(actor.get("defeated_in_combat", false))
	)
	var newly_lost: bool = false

	if defeated:
		newly_lost = state.mark_lost(
			encounter_id,
			TimeManager.get_total_action_index()
		)

	if not _state.set_party_partner_state(state):
		return result

	if state.lost and _state.is_party_member(clean_id):
		_state.remove_party_member(clean_id)
		result["membership_removed"] = true

	_commit(clean_id)

	if bool(result["membership_removed"]):
		party_changed.emit(clean_id, false)

	if newly_lost:
		party_partner_lost.emit(
			clean_id,
			state.character_id,
			encounter_id.strip_edges()
		)

	result["lost"] = state.lost
	return result


func grant_party_partner_experience(
	npc_id: String,
	amount: int
) -> Dictionary:
	var clean_id: String = npc_id.strip_edges()
	var state: NPCPartyPartnerStateData = ensure_party_partner_state(clean_id)
	var empty_result := {
		"npc_id": clean_id,
		"granted": 0,
		"old_level": 0,
		"new_level": 0
	}

	if state == null or amount <= 0 or not state.is_alive():
		return empty_result

	var progression: Dictionary = state.grant_experience(amount)
	var granted: int = int(progression.get("granted", 0))

	if granted <= 0 or not _state.set_party_partner_state(state):
		return empty_result

	_commit(clean_id)
	party_partner_progressed.emit(
		clean_id,
		granted,
		int(progression.get("old_level", state.level)),
		int(progression.get("new_level", state.level))
	)
	return {
		"npc_id": clean_id,
		"granted": granted,
		"old_level": int(progression.get("old_level", state.level)),
		"new_level": int(progression.get("new_level", state.level))
	}


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
