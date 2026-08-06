extends GameContentCatalog
class_name SocialGameContentCatalog


@export_category("NPC and Social")
@export var npc_catalog: NPCCatalog
@export var social_catalog: SocialContentCatalog


func get_content_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = super.get_content_groups()
	var registered_npcs: Array[NPCData] = []
	var registered_profiles: Array[ChatProfileData] = []
	var registered_conversations: Array[ChatConversationData] = []
	var registered_interactions: Array[SocialInteractionData] = []

	if npc_catalog != null:
		registered_npcs = npc_catalog.npcs

	if social_catalog != null:
		registered_profiles = social_catalog.profiles
		registered_conversations = social_catalog.conversations
		registered_interactions = social_catalog.interactions

	groups.append({
		"category": &"npcs",
		"id_property": &"npc_id",
		"resources": registered_npcs
	})
	groups.append({
		"category": &"chat_profiles",
		"id_property": &"profile_id",
		"resources": registered_profiles
	})
	groups.append({
		"category": &"chat_conversations",
		"id_property": &"conversation_id",
		"resources": registered_conversations
	})
	groups.append({
		"category": &"social_interactions",
		"id_property": &"interaction_id",
		"resources": registered_interactions
	})
	return groups


func validate_data() -> PackedStringArray:
	var errors: PackedStringArray = super.validate_data()

	if npc_catalog == null:
		errors.append("npc_catalog cannot be null.")
	else:
		for error: String in npc_catalog.validate_data():
			errors.append("NPC catalog: %s" % error)

	if social_catalog == null:
		errors.append("social_catalog cannot be null.")
	else:
		for error: String in social_catalog.validate_data():
			errors.append("Social catalog: %s" % error)

	if npc_catalog == null or social_catalog == null:
		return errors

	var known_location_ids: Dictionary = {}
	var known_dialogue_ids: Dictionary = {}
	var known_npc_ids: Dictionary = {}

	for location: MapLocation in locations:
		if location != null:
			known_location_ids[location.location_id.strip_edges()] = true

	for dialogue: DialogueData in dialogues:
		if dialogue != null:
			known_dialogue_ids[dialogue.dialogue_id.strip_edges()] = true

	for npc: NPCData in npc_catalog.npcs:
		if npc == null:
			continue

		known_npc_ids[npc.get_display_id()] = true
		_validate_npc_references(
			errors,
			npc,
			known_location_ids,
			known_dialogue_ids
		)

	for profile: ChatProfileData in social_catalog.profiles:
		if profile == null:
			continue

		if not known_npc_ids.has(profile.get_npc_id()):
			errors.append(
				"Chat profile '%s' references unknown NPC '%s'."
				% [profile.get_display_id(), profile.get_npc_id()]
			)

	for conversation: ChatConversationData in social_catalog.conversations:
		if conversation == null:
			continue

		if not known_npc_ids.has(conversation.get_npc_id()):
			errors.append(
				"Chat conversation '%s' references unknown NPC '%s'."
				% [
					conversation.get_display_id(),
					conversation.get_npc_id()
				]
			)

		var profile: ChatProfileData = social_catalog.get_profile(
			conversation.get_profile_id()
		)

		if profile != null and profile.get_npc_id() != conversation.get_npc_id():
			errors.append(
				"Chat conversation '%s' and profile '%s' reference different NPCs."
				% [
					conversation.get_display_id(),
					profile.get_display_id()
				]
			)

	for interaction: SocialInteractionData in social_catalog.interactions:
		if interaction == null:
			continue

		if not known_npc_ids.has(interaction.get_npc_id()):
			errors.append(
				"Social interaction '%s' references unknown NPC '%s'."
				% [interaction.get_display_id(), interaction.get_npc_id()]
			)

		_validate_effect_references(
			errors,
			interaction.effects.effects if interaction.effects != null else [],
			"Social interaction '%s'" % interaction.get_display_id(),
			known_npc_ids
		)

	for encounter: CombatEncounter in combat_encounters:
		if encounter != null:
			_validate_party_slots(errors, encounter, known_npc_ids)

	for incident: IncidentData in incidents:
		if incident == null:
			continue

		_validate_effect_references(
			errors,
			incident.effects,
			"Incident '%s'" % incident.get_display_id(),
			known_npc_ids
		)

		for stage: IncidentStageData in incident.stages:
			if stage != null:
				_validate_effect_references(
					errors,
					stage.effects,
					"Incident '%s' stage '%s'" % [
						incident.get_display_id(),
						stage.get_display_id()
					],
					known_npc_ids
				)

		for branch: IncidentResolutionBranchData in incident.resolution_branches:
			if branch != null:
				_validate_effect_references(
					errors,
					branch.effects,
					"Incident '%s' resolution" % incident.get_display_id(),
					known_npc_ids
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


func _validate_party_slots(
	errors: PackedStringArray,
	encounter: CombatEncounter,
	known_npc_ids: Dictionary
) -> void:
	var slots: Array[CombatSlotData] = []
	slots.append_array(encounter.ally_slots)
	slots.append_array(encounter.enemy_slots)

	for slot: CombatSlotData in slots:
		if slot == null \
			or slot.participant_source \
			!= CombatSlotData.ParticipantSource.PARTY_MEMBER:
			continue

		var npc_id: String = slot.party_member_id.strip_edges()

		if not known_npc_ids.has(npc_id):
			errors.append(
				"Combat encounter '%s' references unknown party NPC '%s'."
				% [encounter.encounter_id, npc_id]
			)
			continue

		var npc: NPCData = npc_catalog.get_npc(npc_id)

		if npc == null or not npc.can_join_party or npc.party_loadout == null:
			errors.append(
				"Combat encounter '%s' party NPC '%s' has no valid party loadout."
				% [encounter.encounter_id, npc_id]
			)


func _validate_effect_references(
	errors: PackedStringArray,
	effects: Array,
	owner_label: String,
	known_npc_ids: Dictionary
) -> void:
	for effect_value: Variant in effects:
		var effect := effect_value as GameEffectData

		if effect == null:
			continue

		if effect is AddLeadEffectData:
			var lead_effect := effect as AddLeadEffectData
			var lead_id: String = lead_effect.lead_id.strip_edges()

			if lead_catalog == null or lead_catalog.get_lead(lead_id) == null:
				errors.append(
					"%s references unknown Lead '%s'."
					% [owner_label, lead_id]
				)

		elif effect is ModifyAffinityEffectData:
			_validate_npc_effect_reference(
				errors,
				owner_label,
				"affinity",
				(effect as ModifyAffinityEffectData).npc_id,
				known_npc_ids
			)

		elif effect is SetFriendshipEffectData:
			_validate_npc_effect_reference(
				errors,
				owner_label,
				"friendship",
				(effect as SetFriendshipEffectData).npc_id,
				known_npc_ids
			)

		elif effect is SetPartyMembershipEffectData:
			_validate_npc_effect_reference(
				errors,
				owner_label,
				"party membership",
				(effect as SetPartyMembershipEffectData).npc_id,
				known_npc_ids
			)


func _validate_npc_effect_reference(
	errors: PackedStringArray,
	owner_label: String,
	effect_label: String,
	npc_id_value: String,
	known_npc_ids: Dictionary
) -> void:
	var npc_id: String = npc_id_value.strip_edges()

	if not npc_id.is_empty() and not known_npc_ids.has(npc_id):
		errors.append(
			"%s %s effect references unknown NPC '%s'."
			% [owner_label, effect_label, npc_id]
		)
