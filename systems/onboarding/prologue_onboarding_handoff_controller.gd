extends Node
class_name PrologueOnboardingHandoffController


signal browser_close_completed
signal navigator_reveal_completed

@export var presentation_data: PrologueOnboardingPresentationData
@export var workspace_manager_path: NodePath
@export var window_manager_path: NodePath

var _handoff_running: bool = false
var _waiting_for_browser_close: bool = false
var _waiting_for_navigator_reveal: bool = false


func _ready() -> void:
	if not GlobalSignals.onboarding_handoff_requested.is_connected(_on_onboarding_handoff_requested):
		GlobalSignals.onboarding_handoff_requested.connect(_on_onboarding_handoff_requested)
	if not GlobalSignals.app_closed.is_connected(_on_app_closed):
		GlobalSignals.app_closed.connect(_on_app_closed)
	if not GlobalSignals.navigator_onboarding_reveal_completed.is_connected(_on_navigator_reveal_completed):
		GlobalSignals.navigator_onboarding_reveal_completed.connect(_on_navigator_reveal_completed)

	call_deferred("_stage_navigator_if_needed")


func _stage_navigator_if_needed() -> void:
	if not _validate_configuration():
		return
	if not CampaignState.has_campaign():
		return
	if GameState.get_flag(presentation_data.world_revealed_flag, false):
		return
	if not _ensure_navigator_installed():
		return
	_activate_navigator_workspace()


func _on_onboarding_handoff_requested(operator_id: String) -> void:
	if _handoff_running:
		return
	if not _validate_handoff(operator_id):
		return

	_handoff_running = true
	await _run_handoff()
	_handoff_running = false


func _run_handoff() -> void:
	if not _ensure_navigator_installed():
		return
	if not _activate_navigator_workspace():
		return

	var window_manager := get_node_or_null(window_manager_path) as WindowManager
	if window_manager == null:
		push_error("Prologue onboarding handoff could not resolve WindowManager.")
		return

	var browser_id := presentation_data.browser_app_id.strip_edges()
	if window_manager.open_windows.has(browser_id):
		_waiting_for_browser_close = true
		GlobalSignals.request_close_app.emit(browser_id)
		if window_manager.open_windows.has(browser_id):
			await browser_close_completed
		_waiting_for_browser_close = false

	if GameState.get_flag(presentation_data.world_revealed_flag, false):
		return

	_waiting_for_navigator_reveal = true
	GlobalSignals.request_navigator_onboarding_reveal.emit()
	await navigator_reveal_completed
	_waiting_for_navigator_reveal = false


func _validate_handoff(operator_id: String) -> bool:
	if not _validate_configuration():
		return false
	if not CampaignState.has_campaign():
		push_error("Onboarding handoff requires an active campaign.")
		return false
	if CampaignState.operator.is_empty():
		push_error("Onboarding handoff requires a registered Operator.")
		return false
	if CampaignState.partner.is_empty():
		push_error("Onboarding handoff requires a synchronized partner.")
		return false
	if operator_id.strip_edges() != CampaignState.operator.operator_id.strip_edges():
		push_error("Onboarding handoff Operator ID does not match CampaignState.")
		return false
	return true


func _validate_configuration() -> bool:
	if presentation_data == null:
		push_error("PrologueOnboardingHandoffController requires presentation_data.")
		return false
	var errors := presentation_data.validate_data()
	if not errors.is_empty():
		for error: String in errors:
			push_error("Prologue onboarding presentation: %s" % error)
		return false
	return true


func _ensure_navigator_installed() -> bool:
	var navigator_id := presentation_data.navigator_app_id.strip_edges()
	var navigator_app := ContentRegistry.get_app(navigator_id)
	if navigator_app == null:
		push_error("Prologue onboarding Navigator AppResource is missing.")
		return false
	if navigator_app.presentation_mode != AppResource.PresentationMode.WORKSPACE:
		push_error("Prologue onboarding Navigator must use WORKSPACE presentation.")
		return false
	if CampaignState.has_installed_app(navigator_id):
		return true
	return AppInstallationManager.install_app(
		navigator_id,
		null,
		false,
		true
	)


func _activate_navigator_workspace() -> bool:
	var workspace_manager := get_node_or_null(workspace_manager_path) as WorkspaceManager
	if workspace_manager == null:
		push_error("Prologue onboarding handoff could not resolve WorkspaceManager.")
		return false
	var navigator_app := ContentRegistry.get_app(presentation_data.navigator_app_id)
	if navigator_app == null:
		return false
	GlobalSignals.request_activate_workspace.emit(navigator_app)
	return (
		workspace_manager.get_active_workspace_id()
		== presentation_data.navigator_app_id.strip_edges()
	)


func _on_app_closed(app_id: String) -> void:
	if not _waiting_for_browser_close or presentation_data == null:
		return
	if app_id.strip_edges() != presentation_data.browser_app_id.strip_edges():
		return
	browser_close_completed.emit()


func _on_navigator_reveal_completed(_location_id: String) -> void:
	if not _waiting_for_navigator_reveal:
		return
	navigator_reveal_completed.emit()
