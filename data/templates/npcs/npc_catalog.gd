extends Resource
class_name NPCCatalog


@export var npcs: Array[NPCData] = []


func get_npc(npc_id: String) -> NPCData:
	var clean_id: String = npc_id.strip_edges()

	for npc: NPCData in npcs:
		if npc != null and npc.get_display_id() == clean_id:
			return npc

	return null


func get_npc_by_network_user(user_id: String) -> NPCData:
	var clean_id: String = user_id.strip_edges()

	for npc: NPCData in npcs:
		if npc != null and npc.get_network_user_id() == clean_id:
			return npc

	return null


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()
	var npc_ids: Dictionary = {}
	var network_user_ids: Dictionary = {}

	for index: int in range(npcs.size()):
		var npc: NPCData = npcs[index]

		if npc == null:
			errors.append("NPC %d is null." % index)
			continue

		var npc_id: String = npc.get_display_id()
		var network_user_id: String = npc.get_network_user_id()

		if npc_ids.has(npc_id):
			errors.append("Duplicate npc_id '%s'." % npc_id)
		else:
			npc_ids[npc_id] = true

		if not network_user_id.is_empty():
			if network_user_ids.has(network_user_id):
				errors.append(
					"Network user '%s' is assigned to multiple NPCs."
					% network_user_id
				)
			else:
				network_user_ids[network_user_id] = true

		for error: String in npc.validate_data():
			errors.append("NPC %d: %s" % [index, error])

	return errors
