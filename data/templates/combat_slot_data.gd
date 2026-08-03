extends Resource
class_name CombatSlotData


enum ParticipantSource {
	FIXED_LOADOUT,
	PLAYER_PARTNER,
	PARTY_MEMBER
}

@export_range(0, 3) var slot_index: int = 0
@export var participant_source: ParticipantSource = ParticipantSource.FIXED_LOADOUT
@export var character: CharacterLoadout
@export var party_member_id: String = ""
@export var availability_conditions: ConditionSetData


func is_available() -> bool:
	if availability_conditions != null and not availability_conditions.is_met():
		return false

	match participant_source:
		ParticipantSource.FIXED_LOADOUT:
			return character != null
		ParticipantSource.PLAYER_PARTNER:
			return not CampaignState.partner.is_empty()
		ParticipantSource.PARTY_MEMBER:
			return false

	return false


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	match participant_source:
		ParticipantSource.FIXED_LOADOUT:
			if character == null:
				errors.append("FIXED_LOADOUT combat slot requires a CharacterLoadout.")
			else:
				errors.append_array(character.validate_data())
		ParticipantSource.PLAYER_PARTNER:
			if slot_index != 0:
				errors.append("PLAYER_PARTNER must occupy allied slot 0.")
		ParticipantSource.PARTY_MEMBER:
			if party_member_id.strip_edges().is_empty():
				errors.append("PARTY_MEMBER combat slot requires party_member_id.")

	return errors
