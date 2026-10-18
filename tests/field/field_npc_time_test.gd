extends FieldIntegrationHarness

func run() -> void:
	await boot("field_npc_time")
	var npc := area.find_interactable_by_id("akihabara.npc.ganbarekun.0") as LocalAreaNPCActor
	check(npc != null and npc.interaction_data.kind == LocalAreaInteractionData.InteractionKind.DIALOGUE, "Production GANBAREkun still uses EXAMINE instead of VN")
	var before := TimeManager.get_total_action_index()
	check(await interact(area, npc), "Player sensor could not talk to GANBAREkun")
	check(DialogueManager.is_dialogue_active() and navigator._current_mode == NavigatorApp.NavigatorMode.DIALOGUE, "Production conversation did not open the existing VN runtime")
	navigator.dialogue_player.try_advance_from_navigator_input()
	await settle(0.3)
	check(navigator.dialogue_player.get_visible_portrait_count() == 1 and navigator.dialogue_player.get_rendered_choice_ids().size() == 3, "GANBAREkun did not render his portrait and three authored choices")
	check(navigator.dialogue_player.choice_container.is_visible_in_tree(), "Production VN choices were hidden by a population refresh")
	await capture("field_ganbarekun_vn")
	var denied := await TimeManager.advance_development_hours(1)
	check(not bool(denied.ok) and TimeManager.get_total_action_index() == before, "QA time advanced through a live dialogue")
	var choice := navigator.dialogue_player.choice_container.get_child(0) as Button
	choice.pressed.emit()
	for step: int in range(8):
		if not DialogueManager.is_dialogue_active():
			break
		navigator.dialogue_player.try_advance_from_navigator_input()
		await settle(0.05)
	check(not DialogueManager.is_dialogue_active() and navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA, "NPC conversation did not return to the same local map")
	check(TimeManager.get_total_action_index() == before, "Free NPC conversation charged time")
	var kiosk := area.find_interactable_by_id("akihabara_kiosk")
	check(kiosk != null and await interact(area, kiosk), "Object EXAMINE stopped working after VN integration")
	check(not DialogueManager.is_dialogue_active(), "Simple object EXAMINE incorrectly started a VN")
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("system_settings"))
	var window := windows.open_windows["system_settings"] as WindowBase
	await window.wait_until_opened()
	var settings := window.content_container.get_child(0) as KubuSystemSettingsPanel
	check(settings != null and not settings.advance_hour_button.disabled, "Settings QA controls were not connected")
	settings.advance_hour_button.pressed.emit()
	check(await until(func() -> bool: return not TimeManager.is_development_advancing()), "QA hour did not finish")
	check(TimeManager.get_total_action_index() == before + 1 and settings.current_time_label.text.contains("BLOCK"), "Actual Settings button did not advance/display an hour")
	await capture("field_settings_time")
	var timeline: Array[int] = []
	var record := func(_p: int, _days: int, _day: int, _month: String) -> void: timeline.append(TimeManager.get_total_action_index())
	GlobalSignals.time_advanced.connect(record)
	var hour := TimeManager.get_current_day_block_index()
	var day := TimeManager.days_passed
	var inventory := CampaignState.inventory.to_save_data()
	var experience := CampaignState.partner.current_exp
	settings.next_day_button.pressed.emit()
	check(await until(func() -> bool: return not TimeManager.is_development_advancing()), "QA next-day command did not finish")
	check(TimeManager.days_passed == day + 1 and TimeManager.get_current_day_block_index() == hour, "QA next day did not preserve the current hour")
	check(timeline.size() == 24, "QA next day skipped intermediate time signals")
	for index: int in range(1, timeline.size()):
		check(timeline[index] == timeline[index - 1] + 1, "Intermediate QA hours were processed out of order")
	GlobalSignals.time_advanced.disconnect(record)
	check(CampaignState.partner.current_exp == experience and CampaignState.inventory.to_save_data() == inventory, "QA controls granted artificial EXP/items")
	check(SaveManager.manual_save(), "Settled QA time left save blocked")
	# Advance DAY→NIGHT through the actual control and verify schedule/population.
	for _hour: int in range(12 - TimeManager.current_action_block):
		settings.advance_hour_button.pressed.emit()
		await until(func() -> bool: return not TimeManager.is_development_advancing())
	await settle(0.1)
	check(TimeManager.is_night() and area.find_interactable_by_id("akihabara.npc.ganbarekun.0") == null, "DAY/NIGHT QA change did not update physical NPC schedule")
	var passive: LocalAreaExeActor
	for actor: LocalAreaExeActor in area.get_field_exes():
		if actor.spawn_entry.spawn_id.ends_with("passive"):
			passive = actor
	check(passive != null and passive.effective_behavior == FieldBehaviorProfileData.Behavior.CAUTIOUS, "Time-conditioned field behavior was not reevaluated")
	check(area.get_field_exes().size() == 4, "Time changes duplicated environmental units")
	# Pending confirmation and active combat both deny unrestricted QA mutation.
	var request := ActivityManager.request_activity(load("res://data/content/activities/fight_rattildus.tres"), "field.qa.test")
	await settle(0.03)
	denied = await TimeManager.advance_development_hours(1)
	check(not bool(denied.ok), "QA time ignored a pending paid confirmation")
	ActivityManager.cancel_request(request)
	await dispose()
	finish("FIELD_NPC_TIME_TEST")
