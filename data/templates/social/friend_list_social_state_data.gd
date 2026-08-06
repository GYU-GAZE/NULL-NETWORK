extends SocialStateData
class_name FriendListSocialStateData


const FRIENDS_KEY: String = "friend_ids"

var friend_ids: PackedStringArray = PackedStringArray()


func reset() -> void:
	super.reset()
	friend_ids.clear()


func add_friend(npc_id: String) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if clean_id.is_empty() or friend_ids.has(clean_id):
		return false

	# Every friend is also a known contact, but a known contact is not
	# automatically a friend. This keeps discovery and friendship separate.
	discover_contact(clean_id)
	friend_ids.append(clean_id)
	return true


func remove_friend(npc_id: String) -> bool:
	var clean_id: String = npc_id.strip_edges()

	if not friend_ids.has(clean_id):
		return false

	friend_ids.erase(clean_id)
	return true


func is_friend(npc_id: String) -> bool:
	return friend_ids.has(npc_id.strip_edges())


func get_friend_ids() -> PackedStringArray:
	var result: PackedStringArray = friend_ids.duplicate()
	result.sort()
	return result


func to_save_data() -> Dictionary:
	var data: Dictionary = super.to_save_data()
	data[FRIENDS_KEY] = _string_array_to_array(friend_ids)
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)

	if data.has(FRIENDS_KEY):
		friend_ids = _read_id_array(data.get(FRIENDS_KEY, []))
	else:
		# Phase-12 migration: before the friend list existed, every Social
		# contact was implicitly treated as a friend. Preserve those saves.
		friend_ids = contact_ids.duplicate()

	for npc_id: String in friend_ids:
		discover_contact(npc_id)


func validate_save_data(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = super.validate_save_data(data)
	var raw_friends: Variant = data.get(FRIENDS_KEY, [])

	if raw_friends is not Array and raw_friends is not PackedStringArray:
		errors.append("social_state.friend_ids must be an array.")
		return errors

	var seen: Dictionary = {}

	for raw_id: Variant in raw_friends:
		var npc_id: String = str(raw_id).strip_edges()

		if npc_id.is_empty():
			errors.append("social_state.friend_ids contains an empty NPC ID.")
		elif seen.has(npc_id):
			errors.append(
				"social_state.friend_ids duplicates NPC '%s'." % npc_id
			)
		else:
			seen[npc_id] = true

	return errors
