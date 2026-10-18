extends NavigatorTestHarness


func run() -> void:
	seed(8301)
	SaveManager.configure_storage_root("user://navigator_exploration_acceptance")
	check(SaveManager.create_campaign("navigator_e2e", CampaignState.SaveMode.SAFE).is_empty(), "Could not create on-disk acceptance campaign")
	prepare_campaign("navigator_e2e", 90)
	var desktop := Control.new()
	desktop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop)
	var workspace := (load("res://systems/workspace/workspace_manager.tscn") as PackedScene).instantiate() as WorkspaceManager
	desktop.add_child(workspace)
	var windows := (load("res://systems/window_manager/window_manager.tscn") as PackedScene).instantiate() as WindowManager
	desktop.add_child(windows)
	var confirmation := (load("res://systems/ui/activity_confirmation_dialog.tscn") as PackedScene).instantiate() as ActivityConfirmationDialog
	add_child(confirmation)
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("browser"))
	var browser_window := windows.open_windows["browser"] as WindowBase
	await browser_window.wait_until_opened()
	var browser := browser_window.content_container.get_child(0) as BrowserApp
	browser.url_line_edit.text = "null.net/forums"
	browser.go_button.pressed.emit()
	await settle()
	var forum := browser._get_current_site() as ForumApp
	var row: ForumThreadRowUI
	for child: Node in forum.thread_list_container.get_children():
		if child is ForumThreadRowUI and child.thread_data.thread_ref.thread_id == "aquarium_signal_rumour":
			row = child
	check(row != null, "Production Lead thread has no real Forum row")
	if row == null:
		finish("NAVIGATOR_EXPLORATION_FLOW_TEST")
		return
	row.thread_title_button.pressed.emit()
	await settle()
	forum = browser._get_current_site() as ForumApp
	check(forum.current_mode == ForumApp.MODE_THREAD, "End-to-end interaction did not enter Forum reader")
	var post: ForumPostUI
	for child: Node in forum.post_list.get_children():
		if child is ForumPostUI and child.text_content.text.contains("lead://aquarium_signal"):
			post = child
	check(post != null, "Production thread lost its Lead interaction")
	if post == null:
		finish("NAVIGATOR_EXPLORATION_FLOW_TEST")
		return
	post.text_content.meta_clicked.emit("lead://aquarium_signal")
	await settle(0.1)
	check(CampaignState.active_lead_ids.has("aquarium_signal"), "Actual Forum post link did not activate Lead")
	check(browser._active_url.ends_with("aquarium_signal_rumour"), "Local Lead intent was misrouted as a Browser URL")
	check(LocationDiscoveryService.is_discovered("akihabara"), "Lead did not discover its registered area")
	await capture("e2e_forum_lead")
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("navigator"))
	var navigator := workspace.get_active_workspace_instance() as NavigatorApp
	check(navigator != null, "Desktop intent did not open Navigator workspace")
	browser_window.close_button.pressed.emit()
	await settle()
	await until(func() -> bool: return not navigator.world_map_view._discovery_sequence_running)
	var location := ContentRegistry.get_location("akihabara")
	var state := NavigatorLocationStateResolver.resolve(location)
	check(state.activity_badge != null and state.activity_badge.badge_id == "rumour_lead", "Lead badge did not project into world map")
	var marker := navigator.world_map_view._markers_by_location_id["akihabara"] as NavigatorLocationMarker
	marker.pressed.emit()
	await settle(0.08)
	check(navigator.world_map_view.get_selected_location() == location and not navigator.world_map_view.enter_area_button.disabled, "World marker selection did not enable valid travel")
	await capture("e2e_world_map_lead")
	var initial_time := TimeManager.get_total_action_index()
	navigator.world_map_view.enter_area_button.pressed.emit()
	await until(func() -> bool: return confirmation.visible)
	confirmation.cancel_button.pressed.emit()
	await settle(0.05)
	check(CampaignState.current_location_id != "akihabara" and TimeManager.get_total_action_index() == initial_time, "Cancelled travel changed physical region or time")
	navigator.world_map_view.enter_area_button.pressed.emit()
	await until(func() -> bool: return confirmation.visible)
	confirmation.confirm_button.pressed.emit()
	check(await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and not navigator._travel_pending), "Confirmed travel did not settle in Local Area")
	check(CampaignState.current_location_id == "akihabara" and navigator._current_location_id == "akihabara", "Physical location disagrees between Navigator and CampaignState")
	check(TimeManager.get_total_action_index() == initial_time + 1, "Travel did not commit exactly one action")
	var area := navigator.local_area_view.get_current_area_instance()
	var instance_id := area.get_instance_id()
	area.player.global_position = Vector2(700, 360)
	navigator.local_area_view.back_button.pressed.emit()
	await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.WORLD_MAP and navigator.can_save_now())
	check(CampaignState.current_location_id == "akihabara", "Returning to map erased physical location")
	marker = navigator.world_map_view._markers_by_location_id["akihabara"] as NavigatorLocationMarker
	marker.pressed.emit()
	navigator.world_map_view.enter_area_button.pressed.emit()
	await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.can_save_now())
	check(area.get_instance_id() == instance_id and area.player.global_position == Vector2(700, 360), "Reopening current area recreated or reset it")
	check(TimeManager.get_total_action_index() == initial_time + 1 and not confirmation.visible, "Staying in the same region charged another trip")
	var incident: LocalAreaIncidentActor
	for child: Node in area.get_node("PopulationController/PopulationActors").get_children():
		if child is LocalAreaIncidentActor:
			incident = child
	check(incident != null, "Lead did not project a physical incident")
	if incident == null:
		finish("NAVIGATOR_EXPLORATION_FLOW_TEST")
		return
	check(await interact(area, incident), "Player sensor could not interact with incident")
	check(await until(func() -> bool: return confirmation.visible), "Incident did not request its authored activity")
	confirmation.confirm_button.pressed.emit()
	check(DialogueManager.is_dialogue_active() and navigator._current_mode == NavigatorApp.NavigatorMode.DIALOGUE, "Incident did not enter its real dialogue")
	await capture("e2e_incident_dialogue")
	for attempt: int in range(10):
		if not DialogueManager.is_dialogue_active():
			break
		navigator.dialogue_player.try_advance_from_navigator_input()
		await settle(0.05)
	check(await until(func() -> bool: return navigator.combat_app.is_encounter_active() and navigator.can_save_now()), "Incident dialogue did not open contained combat")
	check(TimeManager.get_total_action_index() == initial_time + 3, "Incident and included combat charged duplicate activity costs")
	await capture("e2e_contained_combat")
	if DisplayServer.get_name() != "headless":
		KubuDisplaySetting.set_windowed_size(Vector2i(1280, 720))
		await settle()
		check(get_window().content_scale_factor == 2.0, "Display change altered fixed 2x scale")
		await capture("e2e_combat_small_display")
		KubuDisplaySetting.set_windowed_size(Vector2i(1800, 1100))
		await settle()
	for cycle: int in range(6):
		if navigator.combat_app.resolution_panel.visible:
			break
		navigator.combat_app.execute_btn.pressed.emit()
		check(await until(func() -> bool: return not navigator.combat_app.execute_btn.disabled or navigator.combat_app.resolution_panel.visible, 15), "Real combat cycle failed to settle")
	check(CombatManager.is_resolution_applied() and CombatManager.get_pending_outcome() == CombatResult.Outcome.VICTORY, "Production encounter did not resolve through real combat controls")
	await capture("e2e_combat_resolution")
	navigator.combat_app.resolution_panel.continue_button.pressed.emit()
	check(await until(func() -> bool: return navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.can_save_now()), "Resolution did not return to the same Overworld")
	check(navigator.local_area_view.get_current_area_instance().get_instance_id() == instance_id, "Combat return arbitrarily reset Local Area")
	check(CampaignState.has_completed_incident("akihabara_aquarium_relay") and CampaignState.completed_lead_ids.has("aquarium_signal"), "Incident/Lead completion did not persist")
	check(GameState.get_flag("incident.akihabara_aquarium_relay.resolved"), "Incident resolution effect did not reach GameState")
	check(ActivityManager.export_save_data().transactions.is_empty(), "Completed exploration left an orphan activity transaction")
	check(TimeManager.get_total_action_index() == initial_time + 3, "Resolution charged included combat again")
	var position := navigator.local_area_view.get_current_player_position()
	await settle()
	check(SaveManager.manual_save(), "Real SaveManager could not save the settled Navigator")
	navigator.local_area_view.get_current_area_instance().player.global_position += Vector2(50, 20)
	check(SaveManager.load_campaign("navigator_e2e").is_empty(), "Real SaveManager could not reload the exploration campaign")
	await settle()
	check(navigator.local_area_view.get_current_player_position() == position and CampaignState.current_location_id == "akihabara", "Load lost local position or physical region")
	check(GameState.get_flag("incident.akihabara_aquarium_relay.resolved") and TimeManager.get_total_action_index() == initial_time + 3, "Load repeated or lost activity/reward resolution")
	await capture("e2e_overworld_after_load")
	if DisplayServer.get_name() != "headless":
		KubuDisplaySetting.set_windowed_size(Vector2i(1280, 720))
		await settle()
		check(navigator.local_area_view.get_current_player_position() == position, "Display change reset local Player position")
		await capture("e2e_overworld_small_display")
	workspace.clear_active_workspace()
	await get_tree().process_frame
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("navigator"))
	await settle()
	navigator = workspace.get_active_workspace_instance() as NavigatorApp
	check(navigator._current_mode == NavigatorApp.NavigatorMode.LOCAL_AREA and navigator.local_area_view.get_current_player_position() == position, "Closing/reopening Navigator lost its area session")
	GlobalSignals.request_open_app.emit(ContentRegistry.get_app("browser"))
	await settle()
	browser = (windows.open_windows["browser"] as WindowBase).content_container.get_child(0) as BrowserApp
	forum = browser._get_current_site() as ForumApp
	check(forum != null and forum.current_thread_id == "aquarium_signal_rumour" and CampaignState.completed_lead_ids.has("aquarium_signal"), "Forum and Navigator disagree after completed exploration/reopen")
	windows.reset_save_data()
	workspace.clear_active_workspace()
	desktop.queue_free()
	confirmation.queue_free()
	await get_tree().process_frame
	finish("NAVIGATOR_EXPLORATION_FLOW_TEST")
