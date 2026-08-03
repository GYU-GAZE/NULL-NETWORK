extends Node

signal request_open_app(app: AppResource)
signal request_close_app(app_id: String)
signal request_activate_workspace(app: AppResource)

signal app_opened(app_id: String)
signal app_closed(app_id: String)
signal app_focused(app_id: String)
signal workspace_activated(workspace_id: String)

signal dock_lock_changed(locked: bool, reason: String)

signal request_toggle_notification_center
signal request_close_notification_center

signal time_advanced(
	period: int,
	days_passed: int,
	calendar_day: int,
	calendar_month: String
)

signal activity_confirmation_requested(
	request_id: String,
	definition: ActivityDefinitionData,
	preview: ActivityPreviewData,
	source_id: String
)
signal activity_confirmation_resolved(
	request_id: String,
	confirmed: bool
)
signal activity_request_cancelled(request_id: String)

signal request_combat(encounter: CombatEncounter)

signal request_browser_navigation(
	url: String,
	event_id: String,
	step_id: String
)
signal request_story_dialogue(
	dialogue_id: String,
	event_id: String,
	step_id: String
)
signal request_story_encounter(
	encounter: CombatEncounter,
	event_id: String,
	step_id: String
)
signal story_event_step_completed(
	event_id: String,
	step_id: String,
	success: bool
)
