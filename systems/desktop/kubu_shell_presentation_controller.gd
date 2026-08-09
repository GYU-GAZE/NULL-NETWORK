extends Node
class_name KubuShellPresentationController


signal reveal_started(kind: StringName)
signal reveal_finished(kind: StringName)

const REVEAL_FIRST_RUN: StringName = &"first_run"
const REVEAL_DAY_START: StringName = &"day_start"

@export var presentation_data: KubuShellPresentationData
@export var top_taskbar_path: NodePath
@export var bottom_dock_path: NodePath

var _top_taskbar: KubuTopTaskbar
var _bottom_dock: KubuBottomDock
var _first_run_prepared: bool = false
var _day_reveal_pending: bool = false
var _reveal_running: bool = false


func _ready() -> void:
	_resolve_shell_nodes()
	_validate_configuration()

	if not KubuTransitionManager.transition_started.is_connected(
		_on_transition_started
	):
		KubuTransitionManager.transition_started.connect(
			_on_transition_started
		)

	if not KubuTransitionManager.transition_finished.is_connected(
		_on_transition_finished
	):
		KubuTransitionManager.transition_finished.connect(
			_on_transition_finished
		)


func prepare_first_run_reveal() -> void:
	_resolve_shell_nodes()

	if not _has_shell_nodes() or presentation_data == null:
		return

	_first_run_prepared = true
	_top_taskbar.prepare_shell_reveal(
		presentation_data.first_run_top_hidden_scale_y
	)
	_bottom_dock.prepare_shell_reveal(
		presentation_data.first_run_bottom_hidden_scale
	)


func play_first_run_reveal() -> void:
	if _reveal_running:
		return

	_resolve_shell_nodes()

	if not _has_shell_nodes() or presentation_data == null:
		return

	if not _first_run_prepared:
		prepare_first_run_reveal()

	_reveal_running = true
	reveal_started.emit(REVEAL_FIRST_RUN)

	# One layout frame keeps both pivots deterministic while they remain hidden.
	await get_tree().process_frame
	_top_taskbar.refresh_shell_reveal_pivot()
	_bottom_dock.refresh_shell_reveal_pivot()

	_top_taskbar.start_shell_reveal(
		presentation_data.first_run_top_seconds
	)
	await _wait_seconds(presentation_data.first_run_top_seconds)
	_top_taskbar.finish_shell_reveal()

	await _wait_seconds(presentation_data.first_run_gap_seconds)

	_bottom_dock.start_shell_reveal(
		presentation_data.first_run_bottom_seconds
	)
	await _wait_seconds(presentation_data.first_run_bottom_seconds)
	_bottom_dock.finish_shell_reveal()

	await _wait_seconds(presentation_data.first_run_settle_seconds)

	_first_run_prepared = false
	_reveal_running = false
	reveal_finished.emit(REVEAL_FIRST_RUN)


func _on_transition_started(kind: StringName) -> void:
	if kind != KubuTransitionManager.TRANSITION_DAY:
		return

	if _reveal_running or presentation_data == null:
		return

	_resolve_shell_nodes()

	if not _has_shell_nodes():
		return

	# The time-transition underlay is already covering the runtime when the DAY
	# transition starts, so the shell can be staged hidden without flashing.
	_day_reveal_pending = true
	_top_taskbar.prepare_shell_reveal(
		presentation_data.day_start_top_hidden_scale_y
	)
	_bottom_dock.prepare_shell_reveal(
		presentation_data.day_start_bottom_hidden_scale
	)


func _on_transition_finished(kind: StringName) -> void:
	if kind != KubuTransitionManager.TRANSITION_DAY or not _day_reveal_pending:
		return

	_day_reveal_pending = false
	call_deferred("_play_day_start_reveal")


func _play_day_start_reveal() -> void:
	if _reveal_running or presentation_data == null or not _has_shell_nodes():
		return

	_reveal_running = true
	reveal_started.emit(REVEAL_DAY_START)
	_top_taskbar.refresh_shell_reveal_pivot()
	_bottom_dock.refresh_shell_reveal_pivot()

	# Normal day starts are intentionally simultaneous and quicker than the
	# first-run boot sequence.
	_top_taskbar.start_shell_reveal(presentation_data.day_start_seconds)
	_bottom_dock.start_shell_reveal(presentation_data.day_start_seconds)
	await _wait_seconds(presentation_data.day_start_seconds)
	_top_taskbar.finish_shell_reveal()
	_bottom_dock.finish_shell_reveal()

	_reveal_running = false
	reveal_finished.emit(REVEAL_DAY_START)


func _resolve_shell_nodes() -> void:
	if not is_instance_valid(_top_taskbar):
		_top_taskbar = get_node_or_null(top_taskbar_path) as KubuTopTaskbar

	if not is_instance_valid(_bottom_dock):
		_bottom_dock = get_node_or_null(bottom_dock_path) as KubuBottomDock


func _has_shell_nodes() -> bool:
	return is_instance_valid(_top_taskbar) and is_instance_valid(_bottom_dock)


func _validate_configuration() -> void:
	if presentation_data == null:
		push_error("KubuShellPresentationController requires presentation_data.")
		return

	for error: String in presentation_data.validate_data():
		push_error("Kubu shell presentation: %s" % error)

	if not _has_shell_nodes():
		push_error("KubuShellPresentationController could not resolve both docks.")


func _wait_seconds(seconds: float) -> void:
	if seconds <= 0.0:
		return

	await get_tree().create_timer(seconds).timeout
