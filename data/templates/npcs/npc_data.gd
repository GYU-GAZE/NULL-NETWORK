extends Resource
class_name NPCData


@export_category("Identity")
@export var npc_id: String = ""
@export var network_user: NetworkUserData
@export var offline_display_name: String = ""
@export var portrait: Texture2D
@export var personality: NPCPersonalityData
@export var tags: PackedStringArray = PackedStringArray()

@export_category("World Presence")
@export var default_location_id: String = ""
@export var routines: Array[NPCRoutineEntryData] = []

@export_category("Narrative")
@export var default_dialogue_id: String = ""
@export var discovery_conditions: ConditionSetData
@export var contact_unlock_conditions: ConditionSetData

@export_category("Party")
@export var can_join_party: bool = false
@export var party_loadout: CharacterLoadout


func get_display_id() -> String:
	return npc_id.strip_edges()


func get_display_name() -> String:
	if network_user != null:
		var network_name: String = network_user.display_name.strip_edges()

		if not network_name.is_empty():
			return network_name

	var local_name: String = offline_display_name.strip_edges()

	if not local_name.is_empty():
		return local_name

	return get_display_id()


func get_network_user_id() -> String:
	if network_user == null:
		return ""

	return network_user.user_id.strip_edges()


func is_discoverable(context: Dictionary = {}) -> bool:
	return discovery_conditions == null \
		or discovery_conditions.is_met(context)


func can_unlock_contact(context: Dictionary = {}) -> bool:
	return contact_unlock_conditions == null \
		or contact_unlock_conditions.is_met(context)


func get_active_routine(
	weekday_index: int = -1,
	day_block: int = -1,
	context: Dictionary = {}
) -> NPCRoutineEntryData:
	var resolved_weekday: int = weekday_index
	var resolved_day_block: int = day_block

	if resolved_weekday < 0:
		resolved_weekday = TimeManager.current_weekday_index

	if resolved_day_block < 0:
		resolved_day_block = TimeManager.get_current_day_block_index()

	var selected: NPCRoutineEntryData

	for routine: NPCRoutineEntryData in routines:
		if routine == null \
			or not routine.matches(
				resolved_weekday,
				resolved_day_block,
				context
			):
			continue

		if selected == null or routine.priority > selected.priority:
			selected = routine

	return selected


func get_current_location_id(context: Dictionary = {}) -> String:
	var routine: NPCRoutineEntryData = get_active_routine(
		-1,
		-1,
		context
	)

	if routine != null and routine.physically_present:
		return routine.location_id.strip_edges()

	return default_location_id.strip_edges()


func get_current_presence(context: Dictionary = {}) -> int:
	var routine: NPCRoutineEntryData = get_active_routine(
		-1,
		-1,
		context
	)

	if routine == null:
		return NPCRoutineEntryData.PresenceState.OFFLINE

	return int(routine.presence_state)


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var routine_ids: Dictionary = {}
	var seen_tags: Dictionary = {}

	if get_display_id().is_empty():
		errors.append("npc_id cannot be empty.")

	if get_display_name().is_empty():
		errors.append(
			"NPC requires network_user.display_name or offline_display_name."
		)

	if network_user != null and get_network_user_id().is_empty():
		errors.append("network_user requires a non-empty user_id.")

	if personality == null:
		errors.append("personality cannot be null.")
	else:
		for error: String in personality.validate_data():
			errors.append("Personality: %s" % error)

	for index: int in range(routines.size()):
		var routine: NPCRoutineEntryData = routines[index]

		if routine == null:
			errors.append("Routine %d is null." % index)
			continue

		var routine_id: String = routine.get_display_id()

		if routine_ids.has(routine_id):
			errors.append("Duplicate routine_id '%s'." % routine_id)
		else:
			routine_ids[routine_id] = true

		for error: String in routine.validate_data():
			errors.append("Routine %d: %s" % [index, error])

	for raw_tag: String in tags:
		var tag: String = raw_tag.strip_edges()

		if tag.is_empty():
			errors.append("tags cannot contain an empty value.")
		elif seen_tags.has(tag):
			errors.append("Duplicate NPC tag '%s'." % tag)
		else:
			seen_tags[tag] = true

	if discovery_conditions != null:
		for error: String in discovery_conditions.validate_data():
			errors.append("Discovery conditions: %s" % error)

	if contact_unlock_conditions != null:
		for error: String in contact_unlock_conditions.validate_data():
			errors.append("Contact conditions: %s" % error)

	if can_join_party and party_loadout == null:
		errors.append("Party-enabled NPC requires party_loadout.")
	elif party_loadout != null:
		for error: String in party_loadout.validate_data():
			errors.append("Party loadout: %s" % error)

	return errors
