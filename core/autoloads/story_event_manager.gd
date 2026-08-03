extends Node


signal event_queued(event_id: String)
signal event_started(event_id: String)
signal step_dispatched(
	event_id: String,
	step_id: String,
	step_type: StoryEventStepData.StepType,
	payload: Dictionary
)
signal step_waiting(event_id: String, step_id: String)
signal step_completed(event_id: String, step_id: String)
signal event_completed(event_id: String)
signal event_failed(event_id: String, step_id: String, reason: String)


const SOURCE_ID: String = "story_event_manager"

var _processing_scheduled: bool = false
var _is_executing_step: bool = false
var _restored_waiting_signal_emitted: bool = false


func _ready() -> void:
	_connect_signals()
	call_deferred("_resume_campaign_state")


func _connect_signals() -> void:
	if not CampaignState.campaign_created.is_connected(_on_campaign_created):
		CampaignState.campaign_created.connect(_on_campaign_created)

	if not CampaignState.campaign_reset.is_connected(_on_campaign_reset):
		CampaignState.campaign_reset.connect(_on_campaign_reset)

	if not SaveManager.campaign_loaded.is_connected(_on_campaign_loaded):
		SaveManager.campaign_loaded.connect(_on_campaign_loaded)

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	if not GameState.flag_changed.is_connected(_on_flag_changed):
		GameState.flag_changed.connect(_on_flag_changed)

	if not CampaignState.location_changed.is_connected(_on_location_changed):
		CampaignState.location_changed.connect(_on_location_changed)

	if not GlobalSignals.story_event_step_completed.is_connected(
		_on_external_step_completed
	):
		GlobalSignals.story_event_step_completed.connect(
			_on_external_step_completed
		)


func evaluate_manual_trigger(manual_trigger_id: String) -> void:
	_evaluate_trigger(_create_trigger_context(
		StoryEventTriggerData.TriggerType.MANUAL,
		{"manual_trigger_id": manual_trigger_id.strip_edges()}
	))


func queue_event(event_id: String, at_front: bool = false) -> bool:
	var event: StoryEventData = ContentRegistry.get_story_event(event_id)

	if event == null or not _is_repeat_allowed(event):
		return false

	if (
		event.interruption_policy
		== StoryEventData.InterruptionPolicy.IGNORE_WHILE_BUSY
		and _is_busy()
	):
		return false

	var use_front: bool = at_front or (
		event.interruption_policy
		== StoryEventData.InterruptionPolicy.QUEUE_FRONT
	)

	if not CampaignState.enqueue_story_event(event.get_display_id(), use_front):
		return false

	if not use_front:
		_sort_queued_events()

	event_queued.emit(event.get_display_id())
	_schedule_processing()
	return true


func complete_active_step(
	event_id: String,
	step_id: String,
	success: bool = true
) -> bool:
	var clean_event_id: String = event_id.strip_edges()
	var clean_step_id: String = step_id.strip_edges()

	if clean_event_id != CampaignState.active_story_event_id \
		or clean_step_id != CampaignState.active_story_event_step_id \
		or not CampaignState.active_story_event_waiting:
		return false

	if not success:
		event_failed.emit(
			clean_event_id,
			clean_step_id,
			"External StoryEvent step reported failure."
		)
		return false

	_advance_active_step(clean_event_id, clean_step_id)
	return true


func retry_active_step() -> bool:
	if CampaignState.active_story_event_id.is_empty():
		return false

	CampaignState.set_active_story_event_step(
		CampaignState.active_story_event_step_index,
		CampaignState.active_story_event_step_id,
		false
	)
	_restored_waiting_signal_emitted = false
	_schedule_processing()
	return true


func _evaluate_trigger(trigger_context: Dictionary) -> void:
	if not CampaignState.has_campaign():
		return

	var catalog: StoryEventCatalog = ContentRegistry.get_story_event_catalog()

	if catalog == null:
		return

	for event: StoryEventData in catalog.get_ordered_events():
		if event == null \
			or not event.is_eligible(trigger_context) \
			or not _is_repeat_allowed(event):
			continue

		queue_event(event.get_display_id())


func _is_repeat_allowed(event: StoryEventData) -> bool:
	if event == null:
		return false

	var event_id: String = event.get_display_id()

	if event_id.is_empty() \
		or event_id == CampaignState.active_story_event_id \
		or CampaignState.queued_story_event_ids.has(event_id):
		return false

	var repeat_state: Dictionary = (
		CampaignState.get_story_event_repeat_state(event_id)
	)

	match event.repeat_policy:
		StoryEventData.RepeatPolicy.ONCE:
			return int(repeat_state.get("completion_count", 0)) == 0

		StoryEventData.RepeatPolicy.ONCE_PER_DAY:
			return int(repeat_state.get("last_completed_day", -1)) \
				!= TimeManager.days_passed

		StoryEventData.RepeatPolicy.REPEATABLE:
			return true

	return false


func _sort_queued_events() -> void:
	var sortable: Array[String] = []

	for event_id: String in CampaignState.queued_story_event_ids:
		sortable.append(event_id)

	sortable.sort_custom(func(first_id: String, second_id: String) -> bool:
		var first: StoryEventData = ContentRegistry.get_story_event(first_id)
		var second: StoryEventData = ContentRegistry.get_story_event(second_id)

		if first == null:
			return false

		if second == null:
			return true

		if first.priority == second.priority:
			return first_id.naturalnocasecmp_to(second_id) < 0

		return first.priority > second.priority
	)

	CampaignState.reorder_queued_story_events(PackedStringArray(sortable))


func _schedule_processing() -> void:
	if _processing_scheduled or is_queued_for_deletion():
		return

	_processing_scheduled = true
	call_deferred("_process_next_step")


func _process_next_step() -> void:
	_processing_scheduled = false

	if _is_executing_step or not CampaignState.has_campaign():
		return

	if CampaignState.active_story_event_id.is_empty():
		_start_next_queued_event()

	var event_id: String = CampaignState.active_story_event_id

	if event_id.is_empty():
		return

	var event: StoryEventData = ContentRegistry.get_story_event(event_id)

	if event == null:
		_fail_active_event("Active StoryEvent is not registered.")
		return

	if CampaignState.active_story_event_waiting:
		if not _restored_waiting_signal_emitted:
			_restored_waiting_signal_emitted = true
			step_waiting.emit(
				event_id,
				CampaignState.active_story_event_step_id
			)
		return

	var step_index: int = CampaignState.active_story_event_step_index

	if step_index >= event.steps.size():
		_complete_active_event(event)
		return

	var step: StoryEventStepData = event.steps[step_index]

	if step == null:
		_fail_active_event("Active StoryEvent contains a null step.")
		return

	var step_id: String = step.get_display_id()
	var waits_for_ack: bool = (
		step.completion_mode
		== StoryEventStepData.CompletionMode.EXTERNAL_ACKNOWLEDGEMENT
	)
	CampaignState.set_active_story_event_step(
		step_index,
		step_id,
		waits_for_ack
	)
	_restored_waiting_signal_emitted = false
	_is_executing_step = true
	var payload: Dictionary = _build_presentation_payload(step)
	step_dispatched.emit(event_id, step_id, step.step_type, payload)
	var succeeded: bool = _dispatch_step(event, step, payload)
	_is_executing_step = false

	if not succeeded:
		_fail_active_event("StoryEvent step dispatch failed.")
		return

	if CampaignState.active_story_event_id != event_id \
		or CampaignState.active_story_event_step_index != step_index:
		return

	if waits_for_ack:
		step_waiting.emit(event_id, step_id)
		_request_step_checkpoint(event_id, step_index)
		return

	_advance_active_step(event_id, step_id)


func _start_next_queued_event() -> void:
	while not CampaignState.queued_story_event_ids.is_empty():
		var event_id: String = CampaignState.queued_story_event_ids[0]
		var event: StoryEventData = ContentRegistry.get_story_event(event_id)

		if event == null or not _is_repeat_allowed_for_queued(event):
			CampaignState.remove_queued_story_event(event_id)
			continue

		if CampaignState.begin_story_event(event_id):
			_restored_waiting_signal_emitted = false
			event_started.emit(event_id)
			return

		return


func _is_repeat_allowed_for_queued(event: StoryEventData) -> bool:
	if event == null:
		return false

	var repeat_state: Dictionary = CampaignState.get_story_event_repeat_state(
		event.get_display_id()
	)

	match event.repeat_policy:
		StoryEventData.RepeatPolicy.ONCE:
			return int(repeat_state.get("completion_count", 0)) == 0
		StoryEventData.RepeatPolicy.ONCE_PER_DAY:
			return int(repeat_state.get("last_completed_day", -1)) \
				!= TimeManager.days_passed
		StoryEventData.RepeatPolicy.REPEATABLE:
			return true

	return false


func _dispatch_step(
	event: StoryEventData,
	step: StoryEventStepData,
	payload: Dictionary
) -> bool:
	var context := GameEffectContext.create(
		SOURCE_ID,
		"",
		CampaignState.current_location_id,
		"",
		event.get_display_id()
	)

	match step.step_type:
		StoryEventStepData.StepType.SHOW_ALERT:
			UniversalAlerts.show_alert(
				step.title,
				step.message,
				step.alert_animation
			)
			return true

		StoryEventStepData.StepType.SHOW_NOTIFICATION:
			UniversalNotifications.push_data(
				step.title,
				step.message,
				step.notification_type,
				step.target_url,
				step.source_app_id,
				step.source_thread_id,
				step.notification_priority
			)
			return true

		StoryEventStepData.StepType.OPEN_APP:
			var app: AppResource = ContentRegistry.get_app(step.app_id)

			if app == null or not CampaignState.has_installed_app(app.app_id):
				return false

			if app.presentation_mode == AppResource.PresentationMode.WORKSPACE:
				GlobalSignals.request_activate_workspace.emit(app)
			else:
				GlobalSignals.request_open_app.emit(app)
			return true

		StoryEventStepData.StepType.NAVIGATE_BROWSER:
			GlobalSignals.request_browser_navigation.emit(
				step.browser_url,
				event.get_display_id(),
				step.get_display_id()
			)
			return true

		StoryEventStepData.StepType.START_DIALOGUE:
			GlobalSignals.request_story_dialogue.emit(
				step.dialogue_id,
				event.get_display_id(),
				step.get_display_id()
			)
			return true

		StoryEventStepData.StepType.START_ENCOUNTER:
			var encounter: CombatEncounter = ContentRegistry.get_combat_encounter(
				step.encounter_id
			)

			if encounter == null:
				return false

			GlobalSignals.request_story_encounter.emit(
				encounter,
				event.get_display_id(),
				step.get_display_id()
			)
			return true

		StoryEventStepData.StepType.DISCOVER_LOCATION:
			if ContentRegistry.get_location(step.location_id) == null:
				return false

			CampaignState.discover_location(step.location_id)
			return true

		StoryEventStepData.StepType.INSTALL_APP:
			return AppInstallationManager.install_app(step.app_id, context)

		StoryEventStepData.StepType.ADD_LEAD:
			if ContentRegistry.get_lead(step.lead_id) == null:
				return false

			CampaignState.activate_lead(step.lead_id)
			return true

		StoryEventStepData.StepType.APPLY_EFFECTS:
			return GameEffectData.apply_all(step.effects, context).is_empty()

		StoryEventStepData.StepType.START_ACTIVITY:
			return not ActivityManager.request_activity(
				step.activity,
				"story_event.%s" % event.get_display_id()
			).is_empty()

		StoryEventStepData.StepType.ADVANCE_EVENT:
			return queue_event(step.target_event_id, true)

	return false


func _build_presentation_payload(step: StoryEventStepData) -> Dictionary:
	return {
		"title": step.title,
		"message": step.message,
		"app_id": step.app_id.strip_edges(),
		"browser_url": step.browser_url.strip_edges(),
		"dialogue_id": step.dialogue_id.strip_edges(),
		"encounter_id": step.encounter_id.strip_edges(),
		"location_id": step.location_id.strip_edges(),
		"lead_id": step.lead_id.strip_edges(),
		"target_event_id": step.target_event_id.strip_edges()
	}


func _advance_active_step(event_id: String, step_id: String) -> void:
	var next_index: int = CampaignState.active_story_event_step_index + 1
	CampaignState.set_active_story_event_step(next_index, "", false)
	_restored_waiting_signal_emitted = false
	step_completed.emit(event_id, step_id)
	_request_step_checkpoint(event_id, next_index)
	_schedule_processing()


func _complete_active_event(event: StoryEventData) -> void:
	var event_id: String = event.get_display_id()
	var context := GameEffectContext.create(
		SOURCE_ID,
		"",
		CampaignState.current_location_id,
		"",
		event_id
	)
	var failed_effects: PackedStringArray = GameEffectData.apply_all(
		event.completion_effects,
		context
	)

	if not failed_effects.is_empty():
		CampaignState.set_active_story_event_step(
			CampaignState.active_story_event_step_index,
			"<completion>",
			true
		)
		event_failed.emit(
			event_id,
			"<completion>",
			"Completion effects failed: %s" % failed_effects
		)
		return

	CampaignState.record_story_event_completion(
		event_id,
		TimeManager.days_passed,
		TimeManager.get_total_action_index()
	)
	CampaignState.clear_active_story_event()
	_restored_waiting_signal_emitted = false
	event_completed.emit(event_id)
	SaveManager.request_checkpoint(
		StringName("story_event.%s.completed" % event_id),
		true
	)
	_schedule_processing()


func _fail_active_event(reason: String) -> void:
	var event_id: String = CampaignState.active_story_event_id
	var step_id: String = CampaignState.active_story_event_step_id
	CampaignState.set_active_story_event_step(
		CampaignState.active_story_event_step_index,
		step_id,
		true
	)
	event_failed.emit(event_id, step_id, reason)


func _request_step_checkpoint(event_id: String, step_index: int) -> void:
	SaveManager.request_checkpoint(
		StringName("story_event.%s.step.%d" % [event_id, step_index]),
		true
	)


func _resume_campaign_state() -> void:
	if not CampaignState.has_campaign():
		return

	_restored_waiting_signal_emitted = false
	_schedule_processing()


func _is_busy() -> bool:
	return (
		not CampaignState.active_story_event_id.is_empty()
		or not CampaignState.queued_story_event_ids.is_empty()
	)


func _create_trigger_context(
	trigger_type: StoryEventTriggerData.TriggerType,
	extra: Dictionary = {}
) -> Dictionary:
	var context: Dictionary = {
		"trigger_type": int(trigger_type),
		"days_passed": TimeManager.days_passed,
		"period": int(TimeManager.current_period),
		"action_block": TimeManager.current_action_block,
		"location_id": CampaignState.current_location_id
	}

	for key: Variant in extra.keys():
		context[key] = extra[key]

	return context


func _on_campaign_created(_campaign_id: String) -> void:
	call_deferred(
		"_evaluate_trigger",
		_create_trigger_context(
			StoryEventTriggerData.TriggerType.CAMPAIGN_CREATED
		)
	)


func _on_campaign_loaded(
	_campaign_id: String,
	_recovered_from_backup: bool
) -> void:
	_restored_waiting_signal_emitted = false
	_schedule_processing()
	call_deferred(
		"_evaluate_trigger",
		_create_trigger_context(
			StoryEventTriggerData.TriggerType.CAMPAIGN_LOADED
		)
	)


func _on_campaign_reset() -> void:
	_processing_scheduled = false
	_is_executing_step = false
	_restored_waiting_signal_emitted = false


func _on_time_advanced(
	_period: int,
	_days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	_evaluate_trigger(_create_trigger_context(
		StoryEventTriggerData.TriggerType.TIME_ADVANCED
	))


func _on_flag_changed(flag_name: String, value: bool) -> void:
	_evaluate_trigger(_create_trigger_context(
		StoryEventTriggerData.TriggerType.FLAG_CHANGED,
		{"flag_name": flag_name.strip_edges(), "flag_value": value}
	))


func _on_location_changed(location_id: String) -> void:
	_evaluate_trigger(_create_trigger_context(
		StoryEventTriggerData.TriggerType.LOCATION_CHANGED,
		{"location_id": location_id.strip_edges()}
	))


func _on_external_step_completed(
	event_id: String,
	step_id: String,
	success: bool
) -> void:
	complete_active_step(event_id, step_id, success)
