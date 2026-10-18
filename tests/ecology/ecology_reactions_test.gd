extends NavigatorTestHarness

func run() -> void:
	prepare_campaign("ecology_reactions")
	CampaignState.set_current_location("akihabara")
	var zone := ContentRegistry.get_ecology_zone("akiba.electric_town")
	EcologyService.ensure_zone(zone)
	var thread := load("res://data/content/forum/threads/ecology_akiba_collapse.tres") as ThreadButtonData
	check(not thread.is_visible(), "Ecological collapse commentary leaked before the condition")
	EncyclopediaService.record_observation("exe.rattildus", {"seen": true, "scanned": true, "known_locations": ["akihabara"]}, "ecology.survey")
	for index: int in range(5):
		EcologyService.apply_operation({"operation_id": "reaction.%d" % index, "zone_id": zone.ecology_zone_id, "species_line_id": "rattildus", "operation": "PURGE", "source": "protagonist", "target_id": "signature.%d" % index, "formal_result": true, "collapse_authorized": index == 4})
	check(await until(func() -> bool: return CampaignState.has_completed_story_event("ecology.akiba.collapse_report")), "Existing StoryEventManager did not process the authored collapse reaction")
	check(thread.is_visible() and GameState.get_flag("ecology.extinction_route"), "Ecological state did not unlock the authored forum/route conditions")
	var history := SocialService.get_conversation_history("dm.ganbarekun")
	check(history.any(func(message: Dictionary) -> bool: return str(message.get("message_id", "")) == "ganbare.ecology.collapse"), "Existing Social inbox did not deliver the authored NPC reaction")
	var snapshot := EncyclopediaProjectionService.build_entry_snapshot("exe.rattildus")
	check(not snapshot.is_empty() and str(snapshot.get("ecology", [])).contains("LOCALLY ABSENT"), "Known Encyclopedia subject did not expose local ecological absence")
	check(str(ProfileProjectionService.build_snapshot().get("ecology_status", "")).contains("COLLAPSED"), "Profile did not project current ecological world status")
	var manager := (load("res://systems/window_manager/window_manager.tscn") as PackedScene).instantiate() as WindowManager
	add_child(manager)
	manager.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	manager._on_request_open_app(ContentRegistry.get_app("browser"))
	var window := manager.open_windows.browser as WindowBase
	await window.wait_until_opened()
	await window.maximize()
	var browser := window.content_container.get_child(0) as BrowserApp
	browser.url_line_edit.text = "null.net/forums/thread/ecology_akiba_collapse"
	browser.go_button.pressed.emit()
	await settle(0.2)
	var forum := browser._get_current_site() as ForumApp
	check(forum != null and forum.current_thread_id == "ecology_akiba_collapse" and forum.reader_title_label.text.contains("Electric Town"), "Actual Browser/Forum did not render the unlocked ecological thread")
	await capture("ecology_forum_reaction")
	manager.queue_free()
	await get_tree().process_frame
	finish("ECOLOGY_REACTIONS_TEST")
