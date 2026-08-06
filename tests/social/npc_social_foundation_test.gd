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
		var routine := npc.get_active_routine(1, 0)
		_check(
			routine != null and routine.location_id == "akihabara",
			"NPC routine did not resolve Akihabara."
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
		"Valid contact was not discovered."
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
		SocialService.has_contact("ganbarekun")
		and SocialService.get_affinity("ganbarekun") == 3
		and SocialService.get_conversation_history("dm.ganbarekun").size() == 1,
		"Social data did not survive restore."
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
