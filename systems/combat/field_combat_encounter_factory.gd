extends RefCounted
class_name FieldCombatEncounterFactory

## Plain-data recipe for a derived encounter, not a second content registry.
## Reconstructed before CombatManager restores mutable runtime snapshots.
static func create(data: Dictionary) -> CombatEncounter:
	if int(data.get("version", 0)) != 1 or str(data.get("call_id", "")).is_empty():
		return null
	var profile_path := str(data.get("profile_path", ""))
	var profile := load(profile_path) as FieldEncounterProfileData if profile_path.begins_with("res://") and ResourceLoader.exists(profile_path) else null
	var members: Variant = data.get("members", [])
	if profile == null or not profile.validate_data().is_empty() or members is not Array or members.is_empty() or members.size() > 4:
		return null
	var encounter := CombatEncounter.new()
	encounter.encounter_id = str(data.call_id)
	encounter.encounter_name = "FIELD COMBAT CALL"
	encounter.can_escape = profile.can_escape
	encounter.base_escape_chance = profile.base_escape_chance
	encounter.resolution = profile.resolution
	encounter.field_formation = data.duplicate(true)
	var ally := CombatSlotData.new()
	ally.participant_source = CombatSlotData.ParticipantSource.PLAYER_PARTNER
	encounter.ally_slots.append(ally)
	var ids := {}
	for index: int in range(members.size()):
		if members[index] is not Dictionary:
			return null
		var member: Dictionary = members[index]
		var id := str(member.get("unit_id", ""))
		var apk_id := str(member.get("apk_id", ""))
		if id.is_empty() or ids.has(id) or ContentRegistry.get_apk(apk_id) == null:
			return null
		ids[id] = true
		var slot := CombatSlotData.new()
		slot.slot_index = index
		slot.participant_source = CombatSlotData.ParticipantSource.CATALOG_APK
		slot.apk_id = apk_id
		slot.apk_level = int(member.get("level", 1))
		if slot.apk_level < 1 or slot.apk_level > 100:
			return null
		slot.field_unit_id = id
		slot.field_variant_node_id = str(member.get("variant_node_id", ""))
		slot.initial_hp_fraction = clampf(float(member.get("hp_fraction", 1)), 0, 1)
		slot.initial_stability_fraction = clampf(float(member.get("stability_fraction", 1)), 0, 1)
		var reward_path := str(member.get("reward_path", ""))
		if not reward_path.is_empty():
			slot.reward_profile = load(reward_path) as CombatRewardData if reward_path.begins_with("res://") and ResourceLoader.exists(reward_path) else null
			if slot.reward_profile == null:
				return null
		encounter.enemy_slots.append(slot)
	return encounter if encounter.validate_data().is_empty() else null
