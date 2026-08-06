extends Node


signal social_state_changed(npc_id: String)
signal contact_discovered(npc_id: String)
signal conversation_opened(conversation_id: String)
signal conversation_changed(conversation_id: String)
signal interaction_requested(interaction_id: String, request_id: String)
signal interaction_completed(interaction_id: String, conversation_id: String)
signal interaction_failed(interaction_id: String, reason: String)
signal party_changed(npc_id: String, joined: bool)


const SOCIAL_ACTIVITY_SOURCE_PREFIX: String = "social.interaction:"

var _state: SocialStateData = SocialStateData.new()
var _is_committing: bool = false
## request_id -> {interaction_id, conversation_id}
var _pending_interactions: Dictionary = {}


func _ready() -> void:
	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_changed
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_changed
		)

	if not ActivityManager.activity_started.is_connected(
		_on_activity_started
	):
		ActivityManager.activity_started.connect(
			_on_activity_started
		)

	if not ActivityManager.activity_rejected.is_connected(
		_on_activity_rejected
	):
		ActivityManager.activity_rejected.connect(
			_on_activity_rejected
		)

	if not ActivityManager.activity_cancelled.is_connected(
		_on_activity_cancelled
	):
		ActivityManager.activity_cancelled.connect(
			_on_activity_cancelled
		)

	_reload_from_campaign()


func get_npc(npc_id: String) -> NPCData:
	return ContentRegistry.get_npc(npc_id)


func get_chat_profile(profile_id: String) -> ChatProfileData:
	return ContentRegistry.get_chat_profile(profile_id)


func get_chat_conversation(conversation_id: String) -> ChatConversationData:
	return ContentRegistry.get_chat_conversation(conversation_id)


func get_social_interaction(interaction_id: String) -> SocialInteractionData:
	return ContentRegistry.get_social_interaction(interaction_id)


func get_visible_chat_profiles(context: Dictionary = {}) -> Array[ChatProfileData]:
	var result: Array[ChatProfileData] = []

	for resource: Resource in ContentRegistry.get_all(
		ContentRegistry.CATEGORY_CHAT_PROFILES
	):
		var profile := resource as ChatProfileData

		if profile == null \
			or not has_contact(profile.get_npc_id()) \
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


func get_contacts() -> Array[NPCData]:
	var result: Array[NPCData] = []

	for npc_id: String in _state.contact_ids:
		var npc: NPCData = get_npc(npc_id)

		if npc != null:
			result.append(npc)

	return result


func has_contact(npc_id: String) -> bool:
	return _state.has_contact(npc_id)


func discover_contact(
	npc_id: String,
	context: Dictionary = {}
) -> bool:
	if not CampaignState.has_campaign():
		return false

	var npc: NPCData = get_npc(npc_id)

	if npc == null or not npc.can_unlock_contact(context):
		return false

	if not _state.discover_contact(npc.get_display_id()):
		return false

	_commit(npc.get_display_id())
	contact_discovered.emit(npc.get_display_id())
	return true


func get_affinity(npc_id: String) -> int:
	return _state.get_affinity(npc_id)


func set_affinity(npc_id: String, value: int) -> int:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() or not CampaignState.has_campaign():
		return 0

	var result: int = _state.set_affinity(clean_id, value)
	_commit(clean_id)
	return result


func modify_affinity(npc_id: String, amount: int) -> int:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() or not CampaignState.has_campaign():
		return 0

	var result: int = _state.modify_affinity(clean_id, amount)
	_commit(clean_id)
	return result


func refresh_known_presence(
	npc_id: String,
	context: Dictionary = {}
) -> int:
	var npc: NPCData = get_npc(npc_id)

	if npc == null:
		return NPCRoutineEntryData.PresenceState.OFFLINE

	var presence: int = int(npc.get_current_presence(context))

	if _state.set_known_presence(npc.get_display_id(), presence):
		_commit(npc.get_display_id())

	return presence


func get_known_presence(npc_id: String) -> int:
	return _state.get_known_presence(npc_id)


func open_conversation(conversation_id: String) -> bool:
	if not CampaignState.has_campaign():
		return false

	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)

	if conversation == null:
		return false

	var context: Dictionary = _make_condition_context(conversation)

	if not conversation.is_unlocked(context):
		return false

	if not has_contact(conversation.get_npc_id()) \
		and not discover_contact(conversation.get_npc_id(), context):
		return false

	var changed: bool = false

	for message_id: String in conversation.initial_message_ids:
		var message: ChatMessageData = conversation.get_message(message_id)

		if message == null or not message.can_deliver(context):
			continue

		var entry_id: String = "initial::%s::%s" % [
			conversation.get_display_id(),
			message.get_display_id()
		]

		if _state.has_entry(conversation.get_display_id(), entry_id):
			continue

		changed = _append_message_resource(
			conversation,
			message,
			entry_id,
			message.unread_when_delivered
		) or changed

	if _state.mark_conversation_read(conversation.get_display_id()):
		changed = true

	if changed:
		_commit(conversation.get_npc_id())
		conversation_changed.emit(conversation.get_display_id())

	conversation_opened.emit(conversation.get_display_id())
	return true


func get_available_chat_choices(
	conversation_id: String
) -> Array[ChatChoiceData]:
	var result: Array[ChatChoiceData] = []
	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)

	if conversation == null or not has_contact(conversation.get_npc_id()):
		return result

	var context: Dictionary = _make_condition_context(conversation)

	if not conversation.is_unlocked(context):
		return result

	for choice: ChatChoiceData in conversation.get_available_choices(context):
		var interaction: SocialInteractionData = get_social_interaction(
			choice.get_interaction_id()
		)

		if interaction == null \
			or _is_interaction_pending(interaction.get_display_id()) \
			or (
				interaction.requires_contact
				and not has_contact(interaction.get_npc_id())
			):
			continue

		var execution_count: int = _state.get_interaction_execution_count(
			interaction.get_display_id()
		)

		if interaction.can_execute(context, execution_count):
			result.append(choice)

	return result


func select_chat_choice(
	conversation_id: String,
	choice_id: String
) -> bool:
	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)

	if conversation == null:
		return false

	var selected_choice: ChatChoiceData

	for choice: ChatChoiceData in get_available_chat_choices(conversation_id):
		if choice.get_display_id() == choice_id.strip_edges():
			selected_choice = choice
			break

	if selected_choice == null:
		return false

	var interaction: SocialInteractionData = get_social_interaction(
		selected_choice.get_interaction_id()
	)

	if interaction == null:
		return false

	if interaction.activity == null:
		return _execute_interaction(
			conversation,
			interaction,
			""
		)

	var source_id: String = (
		SOCIAL_ACTIVITY_SOURCE_PREFIX
		+ interaction.get_display_id()
	)
	var request_id: String = ActivityManager.request_activity(
		interaction.activity,
		source_id
	)
	_pending_interactions[request_id] = {
		"interaction_id": interaction.get_display_id(),
		"conversation_id": conversation.get_display_id()
	}
	interaction_requested.emit(interaction.get_display_id(), request_id)
	return true


func append_message(
	conversation_id: String,
	message_data: Dictionary,
	mark_unread: bool = false
) -> bool:
	if not CampaignState.has_campaign():
		return false

	if not _state.append_message(
		conversation_id,
		message_data,
		mark_unread
	):
		return false

	_commit(str(message_data.get("npc_id", "")))
	conversation_changed.emit(conversation_id.strip_edges())
	return true


func get_conversation_history(
	conversation_id: String
) -> Array[Dictionary]:
	return _state.get_conversation_history(conversation_id)


func get_resolved_conversation_history(
	conversation_id: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var conversation: ChatConversationData = get_chat_conversation(
		conversation_id
	)

	if conversation == null:
		return result

	for saved_entry: Dictionary in _state.get_conversation_history(
		conversation.get_display_id()
	):
		var message: ChatMessageData = conversation.get_message(
			str(saved_entry.get("message_id", ""))
		)

		if message == null:
			continue

		var resolved_entry: Dictionary = saved_entry.duplicate(true)
		resolved_entry["text_bbcode"] = message.text_bbcode
		resolved_entry["sender_kind"] = int(message.sender_kind)
		resolved_entry["sender_id"] = message.get_sender_id(
			conversation.get_npc_id()
		)
		resolved_entry["sender_name"] = _resolve_sender_name(
			message,
			conversation
		)
		result.append(resolved_entry)

	return result


func get_unread_count(conversation_id: String) -> int:
	return _state.get_unread_count(conversation_id)


func mark_conversation_read(conversation_id: String) -> bool:
	if not _state.mark_conversation_read(conversation_id):
		return false

	_commit("")
	conversation_changed.emit(conversation_id.strip_edges())
	return true


func record_interaction(interaction_id: String) -> bool:
	if not _state.record_interaction(interaction_id):
		return false

	_commit("")
	return true


func has_completed_interaction(interaction_id: String) -> bool:
	return _state.has_completed_interaction(interaction_id)


func get_interaction_execution_count(interaction_id: String) -> int:
	return _state.get_interaction_execution_count(interaction_id)


func add_party_member(
	npc_id: String,
	owner_id: String
) -> bool:
	if not CampaignState.has_campaign():
		return false

	var npc: NPCData = get_npc(npc_id)

	if npc == null \
		or not npc.can_join_party \
		or npc.party_loadout == null:
		return false

	if not _state.add_party_member(
		npc.get_display_id(),
		owner_id,
		TimeManager.get_total_action_index()
	):
		return false

	_commit(npc.get_display_id())
	party_changed.emit(npc.get_display_id(), true)
	return true


func remove_party_member(
	npc_id: String,
	owner_id: String = ""
) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if not _state.remove_party_member(clean_id, owner_id):
		return false

	_commit(clean_id)
	party_changed.emit(clean_id, false)
	return true


func is_party_member(npc_id: String) -> bool:
	return _state.is_party_member(npc_id)


func get_party_member_ids() -> PackedStringArray:
	return _state.get_party_member_ids()


func get_state_snapshot() -> SocialStateData:
	var snapshot := SocialStateData.new()
	snapshot.load_save_data(_state.to_save_data())
	return snapshot


func _execute_interaction(
	conversation: ChatConversationData,
	interaction: SocialInteractionData,
	transaction_id: String
) -> bool:
	if conversation == null or interaction == null:
		return false

	var condition_context: Dictionary = _make_condition_context(
		conversation,
		transaction_id,
		interaction.get_display_id()
	)
	var execution_count: int = _state.get_interaction_execution_count(
		interaction.get_display_id()
	)

	if interaction.requires_contact \
		and not has_contact(interaction.get_npc_id()):
		interaction_failed.emit(
			interaction.get_display_id(),
			"The contact is not available."
		)
		return false

	if not interaction.can_execute(condition_context, execution_count):
		interaction_failed.emit(
			interaction.get_display_id(),
			"The interaction is no longer available."
		)
		return false

	var effect_context := GameEffectContext.create(
		interaction.get_display_id(),
		interaction.get_npc_id(),
		CampaignState.current_location_id,
		transaction_id,
		conversation.get_display_id()
	)

	if not interaction.execute_effects(effect_context):
		interaction_failed.emit(
			interaction.get_display_id(),
			"One or more social effects failed."
		)
		return false

	var execution_number: int = execution_count + 1
	var player_message: ChatMessageData = conversation.get_message(
		interaction.player_message_id
	)

	if player_message == null:
		interaction_failed.emit(
			interaction.get_display_id(),
			"The Operator message is missing."
		)
		return false

	_append_message_resource(
		conversation,
		player_message,
		_make_interaction_entry_id(
			interaction.get_display_id(),
			player_message.get_display_id(),
			execution_number
		),
		false
	)

	for response_id: String in interaction.response_message_ids:
		var response: ChatMessageData = conversation.get_message(response_id)

		if response == null or not response.can_deliver(condition_context):
			continue

		_append_message_resource(
			conversation,
			response,
			_make_interaction_entry_id(
				interaction.get_display_id(),
				response.get_display_id(),
				execution_number
			),
			response.unread_when_delivered
		)

	_state.record_interaction_execution(interaction.get_display_id())
	_commit(interaction.get_npc_id())
	conversation_changed.emit(conversation.get_display_id())
	interaction_completed.emit(
		interaction.get_display_id(),
		conversation.get_display_id()
	)
	return true


func _append_message_resource(
	conversation: ChatConversationData,
	message: ChatMessageData,
	entry_id: String,
	mark_unread: bool
) -> bool:
	return _state.append_message(
		conversation.get_display_id(),
		{
			"entry_id": entry_id.strip_edges(),
			"message_id": message.get_display_id(),
			"npc_id": conversation.get_npc_id(),
			"delivered_action_index": TimeManager.get_total_action_index(),
			"delivered_day": TimeManager.days_passed,
			"delivered_period": int(TimeManager.current_period),
			"delivered_action_block": TimeManager.current_action_block
		},
		mark_unread
	)


func _make_interaction_entry_id(
	interaction_id: String,
	message_id: String,
	execution_number: int
) -> String:
	return "%s::%03d::%s" % [
		interaction_id.strip_edges(),
		maxi(1, execution_number),
		message_id.strip_edges()
	]


func _make_condition_context(
	conversation: ChatConversationData,
	transaction_id: String = "",
	interaction_id: String = ""
) -> Dictionary:
	var source_id: String = conversation.get_display_id()

	if not interaction_id.strip_edges().is_empty():
		source_id = interaction_id.strip_edges()

	return GameEffectContext.create(
		source_id,
		conversation.get_npc_id(),
		CampaignState.current_location_id,
		transaction_id,
		conversation.get_display_id()
	).to_condition_context()


func _resolve_sender_name(
	message: ChatMessageData,
	conversation: ChatConversationData
) -> String:
	match message.sender_kind:
		ChatMessageData.SenderKind.NPC:
			var sender: NPCData = get_npc(
				message.get_sender_id(conversation.get_npc_id())
			)
			return sender.get_display_name() if sender != null else "UNKNOWN"

		ChatMessageData.SenderKind.OPERATOR:
			var operator_name: String = CampaignState.operator.display_name.strip_edges()
			return operator_name if not operator_name.is_empty() else "OPERATOR"

	return "SYSTEM"


func _is_interaction_pending(interaction_id: String) -> bool:
	var clean_id: String = interaction_id.strip_edges()

	for pending_value: Variant in _pending_interactions.values():
		if pending_value is Dictionary \
			and str((pending_value as Dictionary).get(
				"interaction_id",
				""
			)).strip_edges() == clean_id:
			return true

	return false


func _commit(npc_id: String) -> void:
	_is_committing = true
	CampaignState.social_state = _state.to_save_data()
	CampaignState.campaign_changed.emit(&"social")
	_is_committing = false
	social_state_changed.emit(npc_id.strip_edges())


func _reload_from_campaign() -> void:
	_state.load_save_data(CampaignState.social_state)


func _on_activity_started(
	transaction_id: String,
	activity_id: String,
	_source_id: String,
	request_id: String
) -> void:
	if not _pending_interactions.has(request_id):
		return

	var pending: Dictionary = _pending_interactions[request_id]
	_pending_interactions.erase(request_id)
	var interaction: SocialInteractionData = get_social_interaction(
		str(pending.get("interaction_id", ""))
	)
	var conversation: ChatConversationData = get_chat_conversation(
		str(pending.get("conversation_id", ""))
	)

	if _execute_interaction(conversation, interaction, transaction_id):
		ActivityManager.complete_activity(transaction_id, activity_id)
	else:
		ActivityManager.fail_activity(
			transaction_id,
			"Social interaction execution failed.",
			activity_id
		)


func _on_activity_rejected(
	request_id: String,
	_activity_id: String,
	_source_id: String,
	reason: String
) -> void:
	_resolve_pending_interaction_failure(request_id, reason)


func _on_activity_cancelled(
	request_id: String,
	_activity_id: String,
	_source_id: String,
	reason: String
) -> void:
	_resolve_pending_interaction_failure(request_id, reason)


func _resolve_pending_interaction_failure(
	request_id: String,
	reason: String
) -> void:
	if not _pending_interactions.has(request_id):
		return

	var pending: Dictionary = _pending_interactions[request_id]
	_pending_interactions.erase(request_id)
	interaction_failed.emit(
		str(pending.get("interaction_id", "")),
		reason.strip_edges()
	)


func _on_campaign_reset() -> void:
	_pending_interactions.clear()
	_state.reset()
	social_state_changed.emit("")


func _on_campaign_changed(section: StringName) -> void:
	if _is_committing:
		return

	if section == &"campaign" or section == &"social":
		_reload_from_campaign()
		social_state_changed.emit("")
