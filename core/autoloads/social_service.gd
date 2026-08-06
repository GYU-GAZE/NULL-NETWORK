extends Node


signal social_state_changed(npc_id: String)
signal contact_discovered(npc_id: String)
signal conversation_changed(conversation_id: String)
signal party_changed(npc_id: String, joined: bool)


const NPC_CATEGORY: StringName = &"npcs"

var _state: SocialStateData = SocialStateData.new()
var _is_committing: bool = false


func _ready() -> void:
	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	if not CampaignState.campaign_changed.is_connected(
		_on_campaign_changed
	):
		CampaignState.campaign_changed.connect(
			_on_campaign_changed
		)

	_reload_from_campaign()


func get_npc(npc_id: String) -> NPCData:
	return ContentRegistry.resolve(
		NPC_CATEGORY,
		npc_id
	) as NPCData


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
	var npc: NPCData = get_npc(npc_id)

	if npc == null or not CampaignState.has_campaign():
		return 0

	var result: int = _state.set_affinity(
		npc.get_display_id(),
		value
	)
	_commit(npc.get_display_id())
	return result


func modify_affinity(npc_id: String, amount: int) -> int:
	var npc: NPCData = get_npc(npc_id)

	if npc == null or not CampaignState.has_campaign():
		return 0

	var result: int = _state.modify_affinity(
		npc.get_display_id(),
		amount
	)
	_commit(npc.get_display_id())
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


func _commit(npc_id: String) -> void:
	_is_committing = true
	CampaignState.social_state = _state.to_save_data()
	CampaignState.campaign_changed.emit(&"social")
	_is_committing = false
	social_state_changed.emit(npc_id.strip_edges())


func _reload_from_campaign() -> void:
	_state.load_save_data(CampaignState.social_state)


func _on_campaign_reset() -> void:
	_state.reset()
	social_state_changed.emit("")


func _on_campaign_changed(section: StringName) -> void:
	if _is_committing:
		return

	if section == &"campaign" or section == &"social":
		_reload_from_campaign()
		social_state_changed.emit("")
