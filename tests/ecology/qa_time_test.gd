extends NavigatorTestHarness

func run() -> void:
	SaveManager.configure_storage_root("user://qa_onboarding_%d" % Time.get_ticks_usec())
	CampaignState.reset_campaign()
	var boot := (load("res://core/bootstrap/bootstrap.tscn") as PackedScene).instantiate() as GameBootstrap
	add_child(boot)
	GlobalSignals.request_open_system_settings.emit()
	await settle(0.1)
	var panel := _settings(boot)
	check(panel != null and panel.advance_hour_button.disabled, "QA allowed time without a campaign")
	boot.startup_menu.campaign_create_requested.emit("qa_onboarding", "QA Onboarding", CampaignState.SaveMode.SAFE)
	check(await until(func() -> bool: return is_instance_valid(boot._desktop_instance), 12), "Normal onboarding did not launch the desktop")
	check(CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE, "Onboarding QA fixture lost its true PROLOGUE phase")
	GlobalSignals.request_open_system_settings.emit()
	await settle(0.1)
	panel = _settings(boot)
	check(panel != null, "Production settings did not open")
	if panel != null:
		panel._refresh_time_controls()
		print("QA_ORIGINAL_PHASE=", CampaignState.campaign_phase, " DISABLED=", panel.advance_hour_button.disabled, " REASON=", panel.advance_hour_button.tooltip_text, " STATUS=", panel.time_status_label.text)
		await capture("qa_prologue_safe")
		check(not panel.advance_hour_button.disabled, "Safe onboarding PROLOGUE blocks development time")
		await _safe_and_protected_states(panel)
	boot.queue_free()
	await get_tree().process_frame
	finish("QA_TIME_TEST")

func _settings(node: Node) -> KubuSystemSettingsPanel:
	if node is KubuSystemSettingsPanel:
		return node
	for child: Node in node.get_children():
		var found := _settings(child)
		if found != null:
			return found
	return null

func _safe_and_protected_states(panel: KubuSystemSettingsPanel) -> void:
	var start := TimeManager.get_total_action_index()
	panel.advance_hour_button.pressed.emit()
	check(await until(func() -> bool: return not TimeManager.is_development_advancing()), "PROLOGUE QA did not settle")
	check(TimeManager.get_total_action_index() == start + 1 and CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE, "QA changed onboarding phase or did not advance exactly one hour")
	check(panel.time_status_label.text.contains("PROLOGUE") and panel.time_status_label.text.contains("advanced 1"), "QA status hides phase/result")
	await capture("qa_prologue_operation")
	CampaignState.begin_story_event("prologue.registration_started")
	check(panel.advance_hour_button.disabled and panel.time_status_label.text.contains("narrative"), "Active StoryEvent did not visibly protect PROLOGUE immediately")
	await capture("qa_protected_story")
	CampaignState.clear_active_story_event()
	DialogueManager.start_dialogue("npc.ganbarekun.field_meeting")
	check(panel.advance_hour_button.disabled and panel.time_status_label.text.contains("dialogue"), "Dialogue did not protect QA")
	DialogueManager.reset_save_data()
	var partner := APKProgressionService.create_partner_state("novire_init", "QA", 0, 0)
	CampaignState.set_partner_state(partner)
	CombatManager.load_encounter(load("res://data/content/combat/1v1.tres"))
	check(panel.advance_hour_button.disabled, "Combat did not protect QA")
	CombatManager.reset_encounter()
	var definition := load("res://data/content/activities/fight_rattildus.tres") as ActivityDefinitionData
	var request := ActivityManager.request_activity(definition, "qa.acceptance")
	check(panel.advance_hour_button.disabled, "Pending ActivityRequest did not protect QA immediately")
	ActivityManager.cancel_request(request, "Owner cancelled")
	check(not panel.advance_hour_button.disabled, "Cancelled request left QA blocked")
	definition = definition.duplicate() as ActivityDefinitionData
	definition.requires_confirmation = false
	definition.action_cost = 0
	var transactions: Array[String] = []
	var started := func(id: String, _activity: String, source: String, _request: String) -> void:
		if source == "qa.acceptance": transactions.append(id)
	ActivityManager.activity_started.connect(started)
	ActivityManager.request_activity(definition, "qa.acceptance")
	check(await until(func() -> bool: return not transactions.is_empty()), "QA activity fixture did not start")
	check(panel.advance_hour_button.disabled, "Living transaction did not protect QA")
	if not transactions.is_empty():
		ActivityManager.complete_activity(transactions[0])
		check(not ActivityManager.complete_activity(transactions[0]) and not panel.advance_hour_button.disabled, "Resolved transaction remained active or charged twice")
	ActivityManager.activity_started.disconnect(started)
	var save_protection: Array[bool] = []
	var observe_busy := func() -> void:
		if SaveManager.is_runtime_busy(): save_protection.append(panel.advance_hour_button.disabled and not TimeManager.development_time_denial_reason().is_empty())
	SaveManager.busy_state_changed.connect(observe_busy)
	check(SaveManager.manual_save(), "Onboarding QA could not save a stable checkpoint")
	check(SaveManager.load_campaign("qa_onboarding").is_empty(), "Onboarding QA could not load")
	check(save_protection.size() >= 2 and not save_protection.has(false), "Save/load did not protect QA visibly")
	SaveManager.busy_state_changed.disconnect(observe_busy)
	check(CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE, "QA save/load changed the true onboarding phase")
	# A separate MAIN_CAMPAIGN contract fixture, never a shortcut to unlock PROLOGUE.
	prepare_campaign("qa_main_contract")
	check(not panel.advance_hour_button.disabled, "Safe MAIN_CAMPAIGN QA is blocked")
	start = TimeManager.get_total_action_index()
	panel.next_day_button.pressed.emit()
	var concurrent := await TimeManager.advance_development_hours(1)
	check(not bool(concurrent.ok), "Concurrent QA operation was accepted")
	# The first coroutine runs to completion independently after its first await.
	check(await until(func() -> bool: return not TimeManager.is_development_advancing()), "24-hour QA did not settle")
	check(TimeManager.get_total_action_index() == start + 24, "NEXT DAY did not process exactly 24 hours")
	await capture("qa_main_operation")
