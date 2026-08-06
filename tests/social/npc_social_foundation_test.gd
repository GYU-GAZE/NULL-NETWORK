extends Node


var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog_errors := ContentRegistry.reset_to_default_catalog()
	_check(catalog_errors.is_empty(), "Default catalog rejected NPC content.")

	var npc := SocialService.get_npc("ganbarekun")
	_check(npc != null, "Cataloged NPC could not be resolved.")

	if npc != null:
		_check(
			npc.get_display_name() == "GANBAREkun",
			"NPC identity did not use NetworkUserData."
		)
		var online_routine := npc.get_active_routine(1, 0)
		_check(
			online_routine != null \
			and online_routine.location_id == "akihabara" \
			and online_routine.presence_state \
			== NPCRoutineEntryData.PresenceState.ONLINE,
			"NPC DAY routine did not resolve online in Akihabara."
		)
		var offline_routine := npc.get_active_routine(1, 12)
		_check(
			offline_routine != null \
			and not offline_routine.physically_present \
			and offline_routine.presence_state \
			== NPCRoutineEntryData.PresenceState.OFFLINE,
			"NPC NIGHT routine did not resolve offline."
		)

	CampaignState.reset_campaign()
	_check(
		CampaignState.create_campaign(
			"npc_social_foundation",
			CampaignState.SaveMode.SAFE,
			CampaignState.CampaignPhase.MAIN_CAMPAIGN
		),
		"Social fixture campaign could not be created."
	)
	_check(
		SocialService.discover_contact("ganbarekun"),
		"Valid NPC was not discovered."
	)
	_check(
		SocialService.has_known_contact("ganbarekun"),
		"Discovered NPC was not recorded as known."
	)
	_check(
		not SocialService.has_contact("ganbarekun")
		and not SocialService.is_friend("ganbarekun"),
		"World discovery incorrectly added the NPC to the friend list."
	)
	_check(
		SocialService.add_friend("ganbarekun"),
		"Known NPC could not be added to the friend list."
	)
	_check(
		SocialService.has_contact("ganbarekun")
		and SocialService.is_friend("ganbarekun")
		and SocialService.get_contacts().size() == 1,
		"Social contacts did not mirror the friend list."
	)
	_check(
		SocialService.modify_affinity("ganbarekun", 3) == 3,
		"Affinity did not update."
	)

	var message := {
		"message_id": "ganbare.intro.001",
		"npc_id": "ganbarekun",
		"text": "Keep moving forward!"
	}
	_check(
		SocialService.append_message("dm.ganbarekun", message, true),
		"Valid message was not persisted."
	)
	_check(
		not SocialService.append_message("dm.ganbarekun", message, true),
		"Stable message ID was duplicated."
	)
	_check(
		SocialService.get_unread_count("dm.ganbarekun") == 1,
		"Unread count is not idempotent."
	)

	var exported := CampaignState.export_save_data()
	CampaignState.reset_campaign()
	var restore_errors := CampaignState.restore_save_data(exported)
	_check(restore_errors.is_empty(), "Social state round-trip failed.")
	_check(
		SocialService.has_known_contact("ganbarekun")
		and SocialService.is_friend("ganbarekun")
		and SocialService.get_affinity("ganbarekun") == 3
		and SocialService.get_conversation_history("dm.ganbarekun").size() == 1,
		"Social and friend-list data did not survive restore."
	)

	_finish_test()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_test() -> void:
	CampaignState.reset_campaign()
	ContentRegistry.reset_to_default_catalog()

	if _failures.is_empty():
		print("NPC_SOCIAL_FOUNDATION_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)

	print("NPC_SOCIAL_FOUNDATION_TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)
