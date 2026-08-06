extends Node


const CONVERSATION_ID: String = "dm.ganbarekun"
const PARTY_OWNER_ID: String = "lead.integration_field_test"
const PARTY_ENCOUNTER_ID: String = (
	"akihabara_rattildus_ganbarekun_2v1"
)

var _failures := PackedStringArray()
var _interaction_completed: bool = false


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors: PackedStringArray = (
		ContentRegistry.reset_to_default_catalog()
	)
	_check(
		catalog_errors.is_empty(),
		"Default catalog rejected friend-party content: %s"
		% catalog_errors
	)

	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ActivityManager.reset_runtime_state()
	CombatManager.reset_encounter()
	_check(
		CampaignState.create_campaign(
			"friend_party_combat",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Could not create the friend-party fixture campaign."
	)

	var partner: PartnerStateData = (
		APKProgressionService.create_partner_state(
			"novire_init",
			"NOVIRE",
			0,
			0
		)
	)
	_check(
		partner != null \
		and CampaignState.set_partner_state(partner),
		"Could not create the player PartnerState fixture."
	)

	if not GlobalSignals.activity_confirmation_requested.is_connected(
		_on_activity_confirmation_requested
	):
		GlobalSignals.activity_confirmation_requested.connect(
			_on_activity_confirmation_requested
		)

	if not SocialService.interaction_completed.is_connected(
		_on_interaction_completed
	):
		SocialService.interaction_completed.connect(
			_on_interaction_completed
		)

	SocialInboxProjectionService.synchronize_available_conversations()
	_check(
		SocialService.is_friend("ganbarekun"),
		"Unlocked Social content did not establish Ganbarekun friendship."
	)
	_check(
		SocialService.get_friend_ids() == PackedStringArray(["ganbarekun"]),
		"Friend list did not expose Ganbarekun as its only member."
	)
	_check(
		SocialService.open_conversation(CONVERSATION_ID),
		"Friend conversation could not be opened."
	)
	_check(
		SocialService.select_chat_choice(
			CONVERSATION_ID,
			"ask_about_field_test"
		),
		"Field-test interaction could not be selected."
	)

	for _frame: int in range(30):
		await get_tree().process_frame

		if _interaction_completed:
			break

	_check(
		_interaction_completed,
		"Field-test interaction did not complete."
	)
	_check(
		SocialService.is_party_member("ganbarekun"),
		"Ganbarekun did not join the objective-owned party."
	)
	_check(
		not SocialService.remove_party_member(
			"ganbarekun",
			"lead.wrong_owner"
		),
		"An unrelated owner removed the party member."
	)

	var state_snapshot := (
		SocialService.get_state_snapshot()
		as FriendListSocialStateData
	)
	_check(
		state_snapshot != null \
		and state_snapshot.is_friend("ganbarekun") \
		and str(state_snapshot.get_party_membership(
			"ganbarekun"
		).get("owner_id", "")) == PARTY_OWNER_ID,
		"Friendship or party ownership was missing from the Social snapshot."
	)

	var encounter: CombatEncounter = (
		ContentRegistry.get_combat_encounter(PARTY_ENCOUNTER_ID)
	)
	_check(encounter != null, "Party encounter was not registered.")
	_check(
		CombatManager.load_encounter(encounter),
		"CombatManager rejected the active friend-party encounter."
	)

	var party_actor: Variant = CombatManager.ally_team[1]
	_check(
		party_actor is Dictionary \
		and int((party_actor as Dictionary).get("source_kind", -1)) \
		== CombatSlotData.ParticipantSource.PARTY_MEMBER \
		and str((party_actor as Dictionary).get("character_id", "")) \
		== "ganbarekun_party_partner_integration",
		"PARTY_MEMBER did not resolve Ganbarekun's cataloged loadout."
	)

	var saved_campaign: Dictionary = CampaignState.export_save_data()
	var saved_combat: Dictionary = CombatManager.export_save_data()
	CombatManager.reset_encounter()
	CampaignState.reset_campaign()
	var restore_errors: PackedStringArray = CampaignState.restore_save_data(
		saved_campaign
	)
	_check(
		restore_errors.is_empty(),
		"CampaignState rejected friend-party restore: %s" % restore_errors
	)
	CombatManager.import_save_data(saved_combat)
	_check(
		SocialService.is_friend("ganbarekun") \
		and SocialService.is_party_member("ganbarekun"),
		"Friend or party membership did not survive campaign restore."
	)
	_check(
		CombatManager.ally_team[1] is Dictionary \
		and int((CombatManager.ally_team[1] as Dictionary).get(
			"source_kind",
			-1
		)) == CombatSlotData.ParticipantSource.PARTY_MEMBER,
		"Active combat did not reconstruct the restored party member."
	)

	var incident: IncidentData = ContentRegistry.get_incident(
		"akihabara_aquarium_relay"
	)
	var effect_context := GameEffectContext.create(
		"incident.akihabara_aquarium_relay.resolution",
		"ganbarekun",
		"akihabara"
	)
	var victory_branch: IncidentResolutionBranchData = (
		incident.get_resolution_branch(
			CombatResult.Outcome.VICTORY,
			effect_context
		)
		if incident != null
		else null
	)
	var failed_effects := PackedStringArray(["<missing_branch>"])

	if victory_branch != null:
		failed_effects = GameEffectData.apply_all(
			victory_branch.effects,
			effect_context
		)

	_check(
		failed_effects.is_empty(),
		"Victory resolution failed party leave Effects: %s"
		% failed_effects
	)
	_check(
		not SocialService.is_party_member("ganbarekun"),
		"Completed objective did not remove its party member."
	)
	_check(
		SocialService.is_friend("ganbarekun"),
		"Party departure incorrectly removed the friendship."
	)

	var legacy_state := FriendListSocialStateData.new()
	legacy_state.load_save_data({
		"contact_ids": ["ganbarekun"]
	})
	_check(
		legacy_state.is_friend("ganbarekun"),
		"Legacy Social contacts were not migrated into the friend list."
	)

	_finish_test()


func _on_activity_confirmation_requested(
	request_id: String,
	_definition: ActivityDefinitionData,
	_preview: ActivityPreviewData,
	_source_id: String
) -> void:
	call_deferred("_confirm_activity", request_id)


func _confirm_activity(request_id: String) -> void:
	GlobalSignals.activity_confirmation_resolved.emit(request_id, true)


func _on_interaction_completed(
	interaction_id: String,
	_conversation_id: String
) -> void:
	if interaction_id == "social.ganbarekun.field_test_tip":
		_interaction_completed = true


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CombatManager.reset_encounter()
	ActivityManager.reset_runtime_state()
	CampaignState.reset_campaign()
	TimeManager.reset_save_data()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("FRIEND_PARTY_COMBAT_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("FRIEND_PARTY_COMBAT_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
