extends Resource
class_name SocialStateData


const AFFINITY_KEY: String = "affinity_by_npc"
const CONTACTS_KEY: String = "contact_ids"
const CONVERSATIONS_KEY: String = "conversation_history"
const UNREAD_KEY: String = "unread_by_conversation"
const PRESENCE_KEY: String = "known_presence_by_npc"
const INTERACTIONS_KEY: String = "completed_interaction_ids"
const INTERACTION_COUNTS_KEY: String = "interaction_execution_counts"
const PARTY_KEY: String = "party_members"
const PARTY_PARTNERS_KEY: String = "party_partner_states"


var contact_ids: PackedStringArray = PackedStringArray()
var affinity_by_npc: Dictionary = {}
var conversation_history: Dictionary = {}
var unread_by_conversation: Dictionary = {}
var known_presence_by_npc: Dictionary = {}
var completed_interaction_ids: PackedStringArray = PackedStringArray()
var interaction_execution_counts: Dictionary = {}
## npc_id -> {owner_id, joined_action_index}
var party_members: Dictionary = {}
## npc_id -> NPCPartyPartnerStateData.to_save_data()
##
## This state intentionally survives party departure. Rejoining preserves EXP,
## HP and permanent partner loss instead of recreating a fresh loadout.
var party_partner_states: Dictionary = {}


func reset() -> void:
	contact_ids.clear()
	affinity_by_npc.clear()
	conversation_history.clear()
	unread_by_conversation.clear()
	known_presence_by_npc.clear()
	completed_interaction_ids.clear()
	interaction_execution_counts.clear()
	party_members.clear()
	party_partner_states.clear()


func discover_contact(npc_id: String) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() or contact_ids.has(clean_id):
		return false

	contact_ids.append(clean_id)
	return true


func forget_contact(npc_id: String) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if not contact_ids.has(clean_id):
		return false

	contact_ids.erase(clean_id)
	return true


func has_contact(npc_id: String) -> bool:
	return contact_ids.has(npc_id.strip_edges())


func get_affinity(npc_id: String) -> int:
	return int(affinity_by_npc.get(npc_id.strip_edges(), 0))


func set_affinity(npc_id: String, value: int) -> int:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty():
		return 0

	affinity_by_npc[clean_id] = value
	return value


func modify_affinity(npc_id: String, amount: int) -> int:
	return set_affinity(npc_id, get_affinity(npc_id) + amount)


func append_message(
	conversation_id: String,
	message_data: Dictionary,
	mark_unread: bool = false
) -> bool:
	var clean_conversation_id: String = conversation_id.strip_edges()
	var message_id: String = str(
		message_data.get("message_id", "")
	).strip_edges()
	var entry_id: String = str(
		message_data.get("entry_id", message_id)
	).strip_edges()

	if clean_conversation_id.is_empty() \
		or message_id.is_empty() \
		or entry_id.is_empty():
		return false

	var history: Array = _read_message_array(
		conversation_history.get(clean_conversation_id, [])
	)

	for existing: Variant in history:
		if existing is Dictionary \
			and str((existing as Dictionary).get("entry_id", "")) \
				.strip_edges() == entry_id:
			return false

	var saved_message: Dictionary = message_data.duplicate(true)
	saved_message["message_id"] = message_id
	saved_message["entry_id"] = entry_id
	history.append(saved_message)
	conversation_history[clean_conversation_id] = history

	if mark_unread:
		unread_by_conversation[clean_conversation_id] = (
			get_unread_count(clean_conversation_id) + 1
		)

	return true


func get_conversation_history(conversation_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var history: Array = _read_message_array(
		conversation_history.get(conversation_id.strip_edges(), [])
	)

	for entry: Variant in history:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))

	return result


func has_message(conversation_id: String, message_id: String) -> bool:
	var clean_message_id: String = message_id.strip_edges()

	if clean_message_id.is_empty():
		return false

	for entry: Dictionary in get_conversation_history(conversation_id):
		if str(entry.get("message_id", "")).strip_edges() == clean_message_id:
			return true

	return false


func has_entry(conversation_id: String, entry_id: String) -> bool:
	var clean_entry_id: String = entry_id.strip_edges()

	if clean_entry_id.is_empty():
		return false

	for entry: Dictionary in get_conversation_history(conversation_id):
		if str(entry.get("entry_id", "")).strip_edges() == clean_entry_id:
			return true

	return false


func get_unread_count(conversation_id: String) -> int:
	return maxi(
		0,
		int(unread_by_conversation.get(
			conversation_id.strip_edges(),
			0
		))
	)


func mark_conversation_read(conversation_id: String) -> bool:
	var clean_id: String = conversation_id.strip_edges()

	if clean_id.is_empty() or get_unread_count(clean_id) == 0:
		return false

	unread_by_conversation.erase(clean_id)
	return true


func set_known_presence(npc_id: String, presence: int) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty():
		return false

	known_presence_by_npc[clean_id] = presence
	return true


func get_known_presence(
	npc_id: String,
	default_presence: int = NPCRoutineEntryData.PresenceState.OFFLINE
) -> int:
	return int(known_presence_by_npc.get(
		npc_id.strip_edges(),
		default_presence
	))


func record_interaction(interaction_id: String) -> bool:
	if has_completed_interaction(interaction_id):
		return false

	return record_interaction_execution(interaction_id) == 1


func record_interaction_execution(interaction_id: String) -> int:
	var clean_id: String = interaction_id.strip_edges()

	if clean_id.is_empty():
		return 0

	var new_count: int = get_interaction_execution_count(clean_id) + 1
	interaction_execution_counts[clean_id] = new_count

	if not completed_interaction_ids.has(clean_id):
		completed_interaction_ids.append(clean_id)

	return new_count


func get_interaction_execution_count(interaction_id: String) -> int:
	return maxi(
		0,
		int(interaction_execution_counts.get(
			interaction_id.strip_edges(),
			0
		))
	)


func has_completed_interaction(interaction_id: String) -> bool:
	var clean_id: String = interaction_id.strip_edges()
	return (
		completed_interaction_ids.has(clean_id)
		or get_interaction_execution_count(clean_id) > 0
	)


func add_party_member(
	npc_id: String,
	owner_id: String,
	joined_action_index: int
) -> bool:
	var clean_npc_id: String = npc_id.strip_edges()
	var clean_owner_id: String = owner_id.strip_edges()

	if clean_npc_id.is_empty() \
		or clean_owner_id.is_empty() \
		or party_members.has(clean_npc_id):
		return false

	party_members[clean_npc_id] = {
		"owner_id": clean_owner_id,
		"joined_action_index": maxi(0, joined_action_index)
	}
	return true


func remove_party_member(
	npc_id: String,
	owner_id: String = ""
) -> bool:
	var clean_npc_id: String = npc_id.strip_edges()
	var clean_owner_id: String = owner_id.strip_edges()
	var membership: Dictionary = get_party_membership(clean_npc_id)

	if membership.is_empty():
		return false

	if not clean_owner_id.is_empty() \
		and str(membership.get("owner_id", "")) != clean_owner_id:
		return false

	party_members.erase(clean_npc_id)
	return true


func is_party_member(npc_id: String) -> bool:
	return party_members.has(npc_id.strip_edges())


func get_party_membership(npc_id: String) -> Dictionary:
	var value: Variant = party_members.get(npc_id.strip_edges(), {})

	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func get_party_member_ids() -> PackedStringArray:
	var result := PackedStringArray()

	for raw_id: Variant in party_members.keys():
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty():
			result.append(clean_id)

	result.sort()
	return result


func set_party_partner_state(state: NPCPartyPartnerStateData) -> bool:
	if state == null:
		return false

	var clean_npc_id: String = state.npc_id.strip_edges()

	if clean_npc_id.is_empty() or not state.validate_state().is_empty():
		return false

	party_partner_states[clean_npc_id] = state.to_save_data()
	return true


func has_party_partner_state(npc_id: String) -> bool:
	return party_partner_states.has(npc_id.strip_edges())


func get_party_partner_state(npc_id: String) -> NPCPartyPartnerStateData:
	var clean_npc_id: String = npc_id.strip_edges()
	var raw_state: Variant = party_partner_states.get(clean_npc_id)

	if clean_npc_id.is_empty() or raw_state is not Dictionary:
		return null

	var state := NPCPartyPartnerStateData.new()
	state.load_save_data(raw_state as Dictionary)
	return state


func remove_party_partner_state(npc_id: String) -> bool:
	var clean_npc_id: String = npc_id.strip_edges()

	if not party_partner_states.has(clean_npc_id):
		return false

	party_partner_states.erase(clean_npc_id)
	return true


func to_save_data() -> Dictionary:
	return {
		CONTACTS_KEY: _string_array_to_array(contact_ids),
		AFFINITY_KEY: affinity_by_npc.duplicate(true),
		CONVERSATIONS_KEY: conversation_history.duplicate(true),
		UNREAD_KEY: unread_by_conversation.duplicate(true),
		PRESENCE_KEY: known_presence_by_npc.duplicate(true),
		INTERACTIONS_KEY: _string_array_to_array(
			completed_interaction_ids
		),
		INTERACTION_COUNTS_KEY: interaction_execution_counts.duplicate(true),
		PARTY_KEY: party_members.duplicate(true),
		PARTY_PARTNERS_KEY: party_partner_states.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	reset()
	contact_ids = _read_id_array(data.get(CONTACTS_KEY, []))
	affinity_by_npc = _read_dictionary(data.get(AFFINITY_KEY, {}))
	conversation_history = _read_conversation_dictionary(
		data.get(CONVERSATIONS_KEY, {})
	)
	unread_by_conversation = _read_non_negative_int_dictionary(
		data.get(UNREAD_KEY, {})
	)
	known_presence_by_npc = _read_int_dictionary(
		data.get(PRESENCE_KEY, {})
	)
	completed_interaction_ids = _read_id_array(
		data.get(INTERACTIONS_KEY, [])
	)
	interaction_execution_counts = _read_non_negative_int_dictionary(
		data.get(INTERACTION_COUNTS_KEY, {})
	)
	party_members = _read_party_dictionary(data.get(PARTY_KEY, {}))
	party_partner_states = _read_party_partner_state_dictionary(
		data.get(PARTY_PARTNERS_KEY, {})
	)
	_migrate_legacy_contact_entries(data)
	_migrate_legacy_interaction_counts()


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()

	if data.get(CONTACTS_KEY, []) is not Array \
		and data.get(CONTACTS_KEY, []) is not PackedStringArray:
		errors.append("social_state.contact_ids must be an array.")

	for dictionary_key: String in [
		AFFINITY_KEY,
		CONVERSATIONS_KEY,
		UNREAD_KEY,
		PRESENCE_KEY,
		INTERACTION_COUNTS_KEY,
		PARTY_KEY,
		PARTY_PARTNERS_KEY
	]:
		if data.get(dictionary_key, {}) is not Dictionary:
			errors.append(
				"social_state.%s must be a dictionary."
				% dictionary_key
			)

	if data.get(INTERACTIONS_KEY, []) is not Array \
		and data.get(INTERACTIONS_KEY, []) is not PackedStringArray:
		errors.append(
			"social_state.completed_interaction_ids must be an array."
		)

	var conversations: Variant = data.get(CONVERSATIONS_KEY, {})

	if conversations is Dictionary:
		for raw_id: Variant in (conversations as Dictionary).keys():
			var conversation_id: String = str(raw_id).strip_edges()
			var history: Variant = (conversations as Dictionary).get(raw_id)

			if conversation_id.is_empty():
				errors.append("social_state contains an empty conversation ID.")
			elif history is not Array:
				errors.append(
					"Conversation '%s' history must be an array."
					% conversation_id
				)
			else:
				_validate_message_history(
					errors,
					conversation_id,
					history as Array
				)

	var memberships: Variant = data.get(PARTY_KEY, {})

	if memberships is Dictionary:
		for raw_id: Variant in (memberships as Dictionary).keys():
			var npc_id: String = str(raw_id).strip_edges()
			var membership: Variant = (memberships as Dictionary).get(raw_id)

			if npc_id.is_empty():
				errors.append("social_state party contains an empty npc_id.")
			elif membership is not Dictionary:
				errors.append(
					"Party membership '%s' must be a dictionary."
					% npc_id
				)
			elif str((membership as Dictionary).get("owner_id", "")) \
				.strip_edges().is_empty():
				errors.append(
					"Party membership '%s' requires owner_id."
					% npc_id
				)

	var partner_states: Variant = data.get(PARTY_PARTNERS_KEY, {})

	if partner_states is Dictionary:
		for raw_id: Variant in (partner_states as Dictionary).keys():
			var npc_id: String = str(raw_id).strip_edges()
			var raw_state: Variant = (partner_states as Dictionary).get(raw_id)

			if npc_id.is_empty():
				errors.append(
					"social_state party partner states contain an empty npc_id."
				)
				continue

			if raw_state is not Dictionary:
				errors.append(
					"Party partner state '%s' must be a dictionary."
					% npc_id
				)
				continue

			var state := NPCPartyPartnerStateData.new()
			state.load_save_data(raw_state as Dictionary)

			if state.npc_id != npc_id:
				errors.append(
					"Party partner state key '%s' does not match npc_id '%s'."
					% [npc_id, state.npc_id]
				)

			for error: String in state.validate_state():
				errors.append(
					"Party partner state '%s': %s" % [npc_id, error]
				)

	return errors


func _validate_message_history(
	errors: PackedStringArray,
	conversation_id: String,
	history: Array
) -> void:
	var entry_ids: Dictionary = {}

	for index: int in range(history.size()):
		var entry: Variant = history[index]

		if entry is not Dictionary:
			errors.append(
				"Conversation '%s' message %d must be a dictionary."
				% [conversation_id, index]
			)
			continue

		var message_id: String = str(
			(entry as Dictionary).get("message_id", "")
		).strip_edges()
		var entry_id: String = str(
			(entry as Dictionary).get("entry_id", message_id)
		).strip_edges()

		if message_id.is_empty():
			errors.append(
				"Conversation '%s' message %d requires message_id."
				% [conversation_id, index]
			)

		if entry_id.is_empty():
			errors.append(
				"Conversation '%s' message %d requires entry_id."
				% [conversation_id, index]
			)
		elif entry_ids.has(entry_id):
			errors.append(
				"Conversation '%s' duplicates entry_id '%s'."
				% [conversation_id, entry_id]
			)
		else:
			entry_ids[entry_id] = true


func _migrate_legacy_contact_entries(data: Dictionary) -> void:
	var reserved_keys: Dictionary = {
		CONTACTS_KEY: true,
		AFFINITY_KEY: true,
		CONVERSATIONS_KEY: true,
		UNREAD_KEY: true,
		PRESENCE_KEY: true,
		INTERACTIONS_KEY: true,
		INTERACTION_COUNTS_KEY: true,
		PARTY_KEY: true,
		PARTY_PARTNERS_KEY: true
	}

	for raw_key: Variant in data.keys():
		var npc_id: String = str(raw_key).strip_edges()
		var entry: Variant = data.get(raw_key)

		if reserved_keys.has(npc_id) \
			or npc_id.is_empty() \
			or entry is not Dictionary:
			continue

		discover_contact(npc_id)

		if (entry as Dictionary).has("affinity"):
			set_affinity(
				npc_id,
				int((entry as Dictionary).get("affinity", 0))
			)


func _migrate_legacy_interaction_counts() -> void:
	for interaction_id: String in completed_interaction_ids:
		if get_interaction_execution_count(interaction_id) == 0:
			interaction_execution_counts[interaction_id] = 1


func _read_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func _read_id_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()

	if value is not Array and value is not PackedStringArray:
		return result

	for raw_id: Variant in value:
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty() and not result.has(clean_id):
			result.append(clean_id)

	return result


func _read_message_array(value: Variant) -> Array:
	var result: Array = []

	if value is not Array:
		return result

	for entry: Variant in value:
		if entry is not Dictionary:
			continue

		var clean_entry: Dictionary = (entry as Dictionary).duplicate(true)
		var message_id: String = str(
			clean_entry.get("message_id", "")
		).strip_edges()
		var entry_id: String = str(
			clean_entry.get("entry_id", message_id)
		).strip_edges()

		if message_id.is_empty() or entry_id.is_empty():
			continue

		clean_entry["message_id"] = message_id
		clean_entry["entry_id"] = entry_id
		result.append(clean_entry)

	return result


func _read_conversation_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}

	if value is not Dictionary:
		return result

	for raw_id: Variant in (value as Dictionary).keys():
		var clean_id: String = str(raw_id).strip_edges()
		var history: Array = _read_message_array(
			(value as Dictionary).get(raw_id, [])
		)

		if not clean_id.is_empty():
			result[clean_id] = history

	return result


func _read_int_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}

	if value is not Dictionary:
		return result

	for raw_id: Variant in (value as Dictionary).keys():
		var clean_id: String = str(raw_id).strip_edges()

		if not clean_id.is_empty():
			result[clean_id] = int((value as Dictionary).get(raw_id, 0))

	return result


func _read_non_negative_int_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = _read_int_dictionary(value)

	for key: Variant in result.keys():
		result[key] = maxi(0, int(result[key]))

	return result


func _read_party_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}

	if value is not Dictionary:
		return result

	for raw_id: Variant in (value as Dictionary).keys():
		var npc_id: String = str(raw_id).strip_edges()
		var membership: Variant = (value as Dictionary).get(raw_id)

		if npc_id.is_empty() or membership is not Dictionary:
			continue

		var owner_id: String = str(
			(membership as Dictionary).get("owner_id", "")
		).strip_edges()

		if owner_id.is_empty():
			continue

		result[npc_id] = {
			"owner_id": owner_id,
			"joined_action_index": maxi(
				0,
				int((membership as Dictionary).get(
					"joined_action_index",
					0
				))
			)
		}

	return result


func _read_party_partner_state_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}

	if value is not Dictionary:
		return result

	for raw_id: Variant in (value as Dictionary).keys():
		var npc_id: String = str(raw_id).strip_edges()
		var raw_state: Variant = (value as Dictionary).get(raw_id)

		if npc_id.is_empty() or raw_state is not Dictionary:
			continue

		var state := NPCPartyPartnerStateData.new()
		state.load_save_data(raw_state as Dictionary)

		if state.npc_id != npc_id or not state.validate_state().is_empty():
			continue

		result[npc_id] = state.to_save_data()

	return result


func _string_array_to_array(value: PackedStringArray) -> Array[String]:
	var result: Array[String] = []

	for entry: String in value:
		result.append(entry)

	return result
