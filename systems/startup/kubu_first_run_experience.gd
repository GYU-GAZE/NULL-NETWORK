extends Node
class_name KubuFirstRunExperienceController


@export var experience_data: KubuFirstRunExperienceData
@export var window_manager_path: NodePath
@export var shell_presentation_path: NodePath

@onready var input_shield: Control = %InputShield

var _input_locked: bool = false
var _intro_running: bool = false


func _ready() -> void:
	input_shield.hide()
	set_process_input(false)

	if not GameState.flag_changed.is_connected(_on_flag_changed):
		GameState.flag_changed.connect(_on_flag_changed)

	if not CampaignState.campaign_changed.is_connected(_on_campaign_changed):
		CampaignState.campaign_changed.connect(_on_campaign_changed)

	# Stage the chrome hidden while Bootstrap's screen transition still covers the
	# newly-instantiated Main scene. This prevents one-frame flashes before the
	# first-run reveal begins.
	if _should_play_intro():
		var shell_presentation := _get_shell_presentation()
		if shell_presentation != null:
			shell_presentation.prepare_first_run_reveal()

	call_deferred("_initialize_experience")


func _input(_event: InputEvent) -> void:
	if not _input_locked:
		return

	get_viewport().set_input_as_handled()


func _initialize_experience() -> void:
	if experience_data == null:
		push_error("KubuFirstRunExperienceController requires experience_data.")
		return

	var errors: PackedStringArray = experience_data.validate_data()

	if not errors.is_empty():
		for error: String in errors:
			push_error("First-run experience: %s" % error)
		return

	_refresh_shell_lock()

	if not _should_play_intro():
		return

	_intro_running = true
	_set_input_locked(true)

	# Browser must exist in CampaignState before the BOTTOM DOCK is revealed.
	# This avoids depending on AppInstallationManager's deferred default-app sync
	# and guarantees the first visible dock already contains its single app.
	if not _ensure_browser_installed():
		push_error("First-run experience could not install or resolve the Browser app.")
		_intro_running = false
		_set_input_locked(false)
		return

	var browser_app: AppResource = ContentRegistry.get_app(
		experience_data.browser_app_id
	)

	if browser_app == null:
		push_error("First-run experience Browser AppResource is missing.")
		_intro_running = false
		_set_input_locked(false)
		return

	# The old fixed 1.8-second wait looked like a frozen game. The shell reveal is
	# now the first-run clock: TOP DOCK boots, then BOTTOM DOCK, then Browser opens.
	var shell_presentation := _get_shell_presentation()
	if shell_presentation != null:
		await shell_presentation.play_first_run_reveal()
	else:
		push_error(
			"First-run experience could not resolve KubuShellPresentationController."
		)

	if not is_inside_tree() or not _should_play_intro():
		_intro_running = false
		_set_input_locked(false)
		return

	var window_manager := get_node_or_null(window_manager_path) as WindowManager

	if window_manager == null:
		push_error("First-run experience could not resolve WindowManager.")
		_intro_running = false
		_set_input_locked(false)
		return

	# request_open_app is dispatched synchronously by WindowManager.
	GlobalSignals.request_open_app.emit(browser_app)

	var browser_window: WindowBase = window_manager.open_windows.get(
		experience_data.browser_app_id
	) as WindowBase

	# Keep a one-frame fallback for future WindowManager implementations that may
	# dispatch app creation asynchronously. The normal runtime path resolves above.
	if browser_window == null:
		await get_tree().process_frame
		browser_window = window_manager.open_windows.get(
			experience_data.browser_app_id
		) as WindowBase

	if browser_window == null:
		push_error("First-run experience could not resolve the opened Browser window.")
		_intro_running = false
		_set_input_locked(false)
		return

	# The first-run must not invent a special maximized geometry. Wait until the
	# normal WindowBase opening lifecycle has fully settled, then invoke the SAME
	# maximize() path used by the maximize button. This guarantees the target rect
	# is sampled from the live WindowManager work area instead of a creation-frame
	# approximation and keeps is_maximized, restore geometry and adaptive scaling
	# under the normal window-system contract.
	await browser_window.wait_until_opened()

	if not is_inside_tree() or not is_instance_valid(browser_window):
		return

	if experience_data.maximize_browser and not browser_window.is_maximized:
		await browser_window.maximize()

	if not is_inside_tree() or not is_instance_valid(browser_window):
		return

	# BrowserApp already exposes this global navigation intent for system/story
	# driven navigation. Empty event/step IDs deliberately mean no StoryEvent ACK.
	GlobalSignals.request_browser_navigation.emit(
		experience_data.landing_url,
		"",
		""
	)

	if experience_data.post_open_input_delay_seconds > 0.0:
		await get_tree().create_timer(
			experience_data.post_open_input_delay_seconds
		).timeout

	if not is_inside_tree():
		return

	GameState.set_flag(experience_data.completion_flag, true)
	SaveManager.request_checkpoint(
		experience_data.completion_checkpoint,
		true
	)
	_intro_running = false
	_set_input_locked(false)
	_refresh_shell_lock()


func _should_play_intro() -> bool:
	if experience_data == null or not CampaignState.has_campaign():
		return false

	if CampaignState.campaign_phase != CampaignState.CampaignPhase.PROLOGUE:
		return false

	if not CampaignState.operator.is_empty():
		return false

	return not GameState.get_flag(experience_data.completion_flag, false)


func _ensure_browser_installed() -> bool:
	var app_id: String = experience_data.browser_app_id.strip_edges()

	if CampaignState.has_installed_app(app_id):
		return ContentRegistry.get_app(app_id) != null

	return AppInstallationManager.install_app(
		app_id,
		null,
		false,
		true
	)


func _get_shell_presentation() -> KubuShellPresentationController:
	return get_node_or_null(
		shell_presentation_path
	) as KubuShellPresentationController


func _set_input_locked(value: bool) -> void:
	_input_locked = value
	input_shield.visible = value
	set_process_input(value)


func _refresh_shell_lock() -> void:
	if experience_data == null or not CampaignState.has_campaign():
		GlobalSignals.dock_lock_changed.emit(false, "")
		return

	var should_lock: bool = (
		CampaignState.campaign_phase == CampaignState.CampaignPhase.PROLOGUE
		and CampaignState.operator.is_empty()
		and not GameState.get_flag(experience_data.release_flag, false)
	)
	GlobalSignals.dock_lock_changed.emit(
		should_lock,
		"prologue.kubuchan" if should_lock else ""
	)


func _on_flag_changed(flag_name: String, _value: bool) -> void:
	if experience_data == null:
		return

	if flag_name == experience_data.release_flag:
		_refresh_shell_lock()


func _on_campaign_changed(section: StringName) -> void:
	if section == &"campaign" or section == &"operator":
		_refresh_shell_lock()
