extends "res://apps/navigator/app_navigator.gd"
class_name OperatorLossNavigator


const SUCCESSION_REGISTRATION_URL: String = "null.net/register"

@export var onboarding_presentation_data: PrologueOnboardingPresentationData

@onready var onboarding_blackout: ColorRect = %OnboardingBlackout

var _onboarding_reveal_running: bool = false
var _onboarding_reveal_tween: Tween


func _ready() -> void:
	super._ready()

	if not GlobalSignals.request_navigator_onboarding_reveal.is_connected(
		_on_request_navigator_onboarding_reveal
	):
		GlobalSignals.request_navigator_onboarding_reveal.connect(
			_on_request_navigator_onboarding_reveal
		)

	if not resized.is_connected(_refresh_onboarding_reveal_material):
		resized.connect(_refresh_onboarding_reveal_material)

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
		_set_onboarding_blackout_visible(false)
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
	_set_onboarding_blackout_visible(true)
	await get_tree().process_frame

	_refresh_onboarding_reveal_material()
	_set_onboarding_reveal_center(_resolve_player_reveal_center())
	_set_onboarding_reveal_radius(0.0)

	if _onboarding_reveal_tween != null and _onboarding_reveal_tween.is_valid():
		_onboarding_reveal_tween.kill()

	_onboarding_reveal_tween = create_tween()
	_onboarding_reveal_tween.set_trans(Tween.TRANS_SINE)
	_onboarding_reveal_tween.set_ease(Tween.EASE_IN_OUT)
	_onboarding_reveal_tween.tween_method(
		_set_onboarding_reveal_radius,
		0.0,
		onboarding_presentation_data.reveal_end_radius,
		onboarding_presentation_data.reveal_duration_seconds
	)
	await _onboarding_reveal_tween.finished

	if not is_inside_tree():
		return

	_onboarding_reveal_tween = null
	_set_onboarding_blackout_visible(false)
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
		and onboarding_blackout.visible
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

	_set_onboarding_blackout_visible(should_blackout)
	if should_blackout:
		_set_onboarding_reveal_radius(0.0)
	if _current_mode == NavigatorMode.LOCAL_AREA:
		local_area_view.set_interaction_enabled(
			_is_app_active and not should_blackout
		)


func _set_onboarding_blackout_visible(visible_value: bool) -> void:
	if not is_instance_valid(onboarding_blackout):
		return
	onboarding_blackout.visible = visible_value
	onboarding_blackout.mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if visible_value
		else Control.MOUSE_FILTER_IGNORE
	)


func _refresh_onboarding_reveal_material() -> void:
	if not is_instance_valid(onboarding_blackout):
		return
	var shader_material := onboarding_blackout.material as ShaderMaterial
	if shader_material == null:
		return
	var safe_height := maxf(1.0, size.y)
	shader_material.set_shader_parameter(
		"aspect_ratio",
		maxf(0.1, size.x / safe_height)
	)
	if onboarding_presentation_data != null:
		shader_material.set_shader_parameter(
			"reveal_feather",
			onboarding_presentation_data.reveal_feather
		)


func _set_onboarding_reveal_center(center: Vector2) -> void:
	var shader_material := onboarding_blackout.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("reveal_center", center)


func _set_onboarding_reveal_radius(radius: float) -> void:
	if not is_instance_valid(onboarding_blackout):
		return
	var shader_material := onboarding_blackout.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("reveal_radius", maxf(0.0, radius))


func _resolve_player_reveal_center() -> Vector2:
	var area_instance := local_area_view.get_current_area_instance()
	if area_instance == null:
		return Vector2(0.5, 0.5)
	if not is_instance_valid(local_area_view.area_viewport) \
		or not is_instance_valid(local_area_view.viewport_container):
		return Vector2(0.5, 0.5)

	var viewport_size := Vector2(local_area_view.area_viewport.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return Vector2(0.5, 0.5)

	var player_viewport_position := (
		local_area_view.area_viewport.get_canvas_transform()
		* area_instance.get_player_position()
	)
	var viewport_rect := local_area_view.viewport_container.get_global_rect()
	var viewport_scale := viewport_rect.size / viewport_size
	var player_global_position := (
		viewport_rect.position
		+ player_viewport_position * viewport_scale
	)
	var navigator_rect := get_global_rect()
	if navigator_rect.size.x <= 0.0 or navigator_rect.size.y <= 0.0:
		return Vector2(0.5, 0.5)

	return Vector2(
		clampf(
			(player_global_position.x - navigator_rect.position.x)
			/ navigator_rect.size.x,
			0.0,
			1.0
		),
		clampf(
			(player_global_position.y - navigator_rect.position.y)
			/ navigator_rect.size.y,
			0.0,
			1.0
		)
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
