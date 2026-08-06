extends "res://apps/navigator/app_navigator.gd"


const SUCCESSION_REGISTRATION_URL: String = "null.net/register"


func _on_combat_finished(result: CombatResult) -> void:
	if result == null:
		return

	if not bool(result.metadata.get("operator_lost", false)):
		super._on_combat_finished(result)
		return

	var failed_transaction_id: String = _active_combat_transaction_id
	var failed_activity_id: String = _active_combat_activity_id
	_pending_incident_id = ""
	_pending_exe_actor = null
	_active_combat_transaction_id = ""
	_active_combat_activity_id = ""

	if not failed_transaction_id.is_empty():
		ActivityManager.fail_activity(
			failed_transaction_id,
			"The active Operator was archived.",
			failed_activity_id
		)

	local_area_view.refresh_population()
	_set_mode(NavigatorMode.WORLD_MAP)
	call_deferred("_open_successor_registration")


func _open_successor_registration() -> void:
	var browser: AppResource = ContentRegistry.get_app("browser")

	if browser != null:
		GlobalSignals.request_open_app.emit(browser)

	GlobalSignals.request_browser_navigation.emit(
		SUCCESSION_REGISTRATION_URL,
		"operator_loss",
		"successor_registration"
	)
	UniversalAlerts.show_alert(
		"OPERATOR ARCHIVED",
		"Synchronization was lost. Register a new Operator to continue this campaign."
	)
