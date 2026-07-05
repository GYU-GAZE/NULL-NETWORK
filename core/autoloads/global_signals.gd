extends Node

signal request_open_app(app: AppResource)
signal request_close_app(app_id: String)

signal request_toggle_notification_center
signal request_close_notification_center

signal time_advanced(period: int, days_passed: int, calendar_day: int, calendar_month: String)

signal request_combat(encounter: CombatEncounter)
