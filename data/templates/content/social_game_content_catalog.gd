extends GameContentCatalog
class_name SocialGameContentCatalog


@export_category("NPC and Social")
@export var npc_catalog: NPCCatalog


func get_content_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = super.get_content_groups()
	var registered_npcs: Array[NPCData] = []

	if npc_catalog != null:
		registered_npcs = npc_catalog.npcs

	groups.append({
		"category": &"npcs",
		"id_property": &"npc_id",
		"resources": registered_npcs
	})
	return groups


func validate_data() -> PackedStringArray:
	var errors: PackedStringArray = super.validate_data()

	if npc_catalog == null:
		errors.append("npc_catalog cannot be null.")
		return errors

	for error: String in npc_catalog.validate_data():
		errors.append("NPC catalog: %s" % error)

	var known_location_ids: Dictionary = {}
	var known_dialogue_ids: Dictionary = {}

	for location: MapLocation in locations:
		if location != null:
			known_location_ids[location.location_id.strip_edges()] = true

	for dialogue: DialogueData in dialogues:
		if dialogue != null:
			known_dialogue_ids[dialogue.dialogue_id.strip_edges()] = true

	for npc: NPCData in npc_catalog.npcs:
		if npc == null:
			continue

		_validate_npc_references(
			errors,
			npc,
			known_location_ids,
			known_dialogue_ids
		)

	return errors


func _validate_npc_references(
	errors: PackedStringArray,
	npc: NPCData,
	known_location_ids: Dictionary,
	known_dialogue_ids: Dictionary
) -> void:
	var default_location_id: String = npc.default_location_id.strip_edges()
	var dialogue_id: String = npc.default_dialogue_id.strip_edges()

	if not default_location_id.is_empty() \
		and not known_location_ids.has(default_location_id):
		errors.append(
			"NPC '%s' references unknown default location '%s'."
			% [npc.get_display_id(), default_location_id]
		)

	if not dialogue_id.is_empty() \
		and not known_dialogue_ids.has(dialogue_id):
		errors.append(
			"NPC '%s' references unknown dialogue '%s'."
			% [npc.get_display_id(), dialogue_id]
		)

	for routine: NPCRoutineEntryData in npc.routines:
		if routine == null:
			continue

		var location_id: String = routine.location_id.strip_edges()

		if not location_id.is_empty() \
			and not known_location_ids.has(location_id):
			errors.append(
				"NPC '%s' routine '%s' references unknown location '%s'."
				% [
					npc.get_display_id(),
					routine.get_display_id(),
					location_id
				]
			)
