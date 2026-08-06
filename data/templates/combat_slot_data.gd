extends Resource
class_name CombatSlotData


enum ParticipantSource {
	FIXED_LOADOUT,
	PLAYER_PARTNER,
	PARTY_MEMBER,
	CATALOG_APK
}

@export_range(0, 3) var slot_index: int = 0
@export var participant_source: ParticipantSource = ParticipantSource.FIXED_LOADOUT
@export var character: CharacterLoadout
@export var party_member_id: String = ""

@export_category("Catalog APK")
@export var apk_id: String = ""
@export_range(1, 100, 1) var apk_level: int = 1
@export var apk_integrity_state: PartnerStateData.IntegrityState = (
	PartnerStateData.IntegrityState.EXE
)

@export_category("Rules and Rewards")
@export var availability_conditions: ConditionSetData
@export var reward_profile: CombatRewardData


func is_available() -> bool:
	if availability_conditions != null \
		and not availability_conditions.is_met():
		return false

	match participant_source:
		ParticipantSource.FIXED_LOADOUT:
			return character != null
		ParticipantSource.PLAYER_PARTNER:
			return not CampaignState.partner.is_empty()
		ParticipantSource.PARTY_MEMBER:
			var clean_party_member_id: String = party_member_id.strip_edges()
			var npc: NPCData = ContentRegistry.get_npc(clean_party_member_id)
			return (
				not clean_party_member_id.is_empty()
				and npc != null
				and npc.can_join_party
				and npc.party_loadout != null
				and SocialService.is_party_member(clean_party_member_id)
			)
		ParticipantSource.CATALOG_APK:
			return ContentRegistry.get_apk(
				apk_id.strip_edges()
			) != null

	return false


func validate_data() -> PackedStringArray:
	var errors := PackedStringArray()

	match participant_source:
		ParticipantSource.FIXED_LOADOUT:
			if character == null:
				errors.append(
					"FIXED_LOADOUT combat slot requires a CharacterLoadout."
				)
			else:
				errors.append_array(character.validate_data())

		ParticipantSource.PLAYER_PARTNER:
			if slot_index != 0:
				errors.append(
					"PLAYER_PARTNER must occupy allied slot 0."
				)

		ParticipantSource.PARTY_MEMBER:
			if party_member_id.strip_edges().is_empty():
				errors.append(
					"PARTY_MEMBER combat slot requires party_member_id."
				)
			elif slot_index == 0:
				errors.append(
					"PARTY_MEMBER cannot replace the PLAYER_PARTNER in allied slot 0."
				)

		ParticipantSource.CATALOG_APK:
			if apk_id.strip_edges().is_empty():
				errors.append(
					"CATALOG_APK combat slot requires apk_id."
				)

			if apk_level < 1 or apk_level > 100:
				errors.append(
					"CATALOG_APK level must remain between 1 and 100."
				)

	if reward_profile != null:
		errors.append_array(reward_profile.validate_data())

	return errors
