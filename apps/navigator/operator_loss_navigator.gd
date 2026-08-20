extends "res://apps/navigator/app_navigator.gd"
class_name OperatorLossNavigator


const SUCCESSION_REGISTRATION_URL: String = "null.net/register"

@export var onboarding_presentation_data: PrologueOnboardingPresentationData

@onready var onboarding_blackout: RadialRevealOverlay = %OnboardingBlackout

var _onboarding_reveal_running: bool = false


func _ready() -> void:
	super._ready()

	if not GlobalSignals.request_navigator_onboarding_reveal.is_connected(
		_on_request_navigator_onboarding_reveal
	):
		GlobalSignals.request_navigator_onboarding_reveal.connect(
			_on_request_navigator_onboarding_reveal
		)

	_sync_onboarding_blackout()


func prepare_onboarding_blackout() -> void:
	_sync_onboarding_blackout(true)


func reveal_onboarding_world() -> void:
	if _onboarding_reveal_running:
		return

	if not _validate_onboarding_presentation():
		_complete_failed_onboarding_reveal()
		return

	var reveal_flag := onboarding_presentation_data.world_revealed_flag
	if GameState.get_flag(reveal_flag, false):
		onboarding_blackout.uncover_immediately()
		GlobalSignals.navigator_onboarding_reveal_completed.emit(
			CampaignState.current_location_id
		)
		return

	var location_id := onboarding_presentation_data.onboarding_location_id.strip_edges()
	var location := ContentRegistry.get_location(location_id)
	if location == null:
		push_error("Navigator onboarding location '%s' is not registered." % location_id)
		_complete_failed_onboarding_reveal()
		return
	if location.local_area == null:
		push_error("Navigator onboarding location '%s' has no LocalAreaData." % location_id)
		_complete_failed_onboarding_reveal()
		return

	_onboarding_reveal_running = true
	CampaignState.discover_location(location_id)

	if not _enter_location(location):
		push_error("Navigator failed to open onboarding local area '%s'." % location_id)
		_onboarding_reveal_running = false
		_complete_failed_onboarding_reveal()
		return

	local_area_view.set_interaction_enabled(false)
	onboarding_blackout.cover()
	await get_tree().process_frame

	var reveal_origin := _resolve_player_reveal_global_position()
	await onboarding_blackout.reveal_from_global_position(
		reveal_origin,
		onboarding_presentation_data.reveal_duration_seconds,
		onboarding_presentation_data.reveal_end_radius,
		onboarding_presentation_data.reveal_feather
	)

	if not is_inside_tree():
		return

	GameState.set_flag(reveal_flag, true)
	SaveManager.request_checkpoint(
		onboarding_presentation_data.completion_checkpoint,
		true
	)
	_onboarding_reveal_running = false
	local_area_view.set_interaction_enabled(_is_app_active)
	GlobalSignals.navigator_onboarding_reveal_completed.emit(location_id)


func is_onboarding_blackout_active() -> bool:
	return (
		is_instance_valid(onboarding_blackout)
		and onboarding_blackout.is_covering()
	)


func _validate_onboarding_presentation() -> bool:
	if onboarding_presentation_data == null:
		push_error("Navigator requires onboarding_presentation_data.")
		return false
	var errors := onboarding_presentation_data.validate_data()
	if not errors.is_empty():
		for error: String in errors:
			push_error("Navigator onboarding presentation: %s" % error)
		return false
	return true


func _sync_onboarding_blackout(force_blackout: bool = false) -> void:
	if not is_instance_valid(onboarding_blackout):
		return

	var should_blackout := force_blackout
	if not should_blackout and CampaignState.has_campaign() and onboarding_presentation_data != null:
		should_blackout = not GameState.get_flag(
			onboarding_presentation_data.world_revealed_flag,
			false
		)

	if should_blackout:
		onboarding_blackout.cover()
	else:
		onboarding_blackout.uncover_immediately()

	if _current_mode == NavigatorMode.LOCAL_AREA:
		local_area_view.set_interaction_enabled(
			_is_app_active and not should_blackout
		)


func _resolve_player_reveal_global_position() -> Vector2:
	var fallback_rect := onboarding_blackout.get_global_rect()
	var fallback_position := fallback_rect.get_center()
	var area_instance := local_area_view.get_current_area_instance()
	if area_instance == null:
		return fallback_position
	if not is_instance_valid(local_area_view.area_viewport) \
		or not is_instance_valid(local_area_view.viewport_container):
		return fallback_position

	var viewport_size := Vector2(local_area_view.area_viewport.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return fallback_position

	var player_viewport_position := (
		local_area_view.area_viewport.get_canvas_transform()
		* area_instance.get_player_position()
	)
	var viewport_rect := local_area_view.viewport_container.get_global_rect()
	var viewport_scale := viewport_rect.size / viewport_size
	return (
		viewport_rect.position
		+ player_viewport_position * viewport_scale
	)


func _complete_failed_onboarding_reveal() -> void:
	_onboarding_reveal_running = false
	GlobalSignals.navigator_onboarding_reveal_completed.emit("")


func _on_request_navigator_onboarding_reveal() -> void:
	await reveal_onboarding_world()


func _set_app_active(active: bool) -> void:
	_is_app_active = active
	if _current_mode != NavigatorMode.LOCAL_AREA:
		return
	local_area_view.set_interaction_enabled(
		_is_app_active and not is_onboarding_blackout_active()
	)


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
