extends ColorRect
class_name TimeTransitionUnderlay


@export var intro_overlap_seconds: float = 0.06
@export var release_seconds: float = 0.08

var _last_period: int = TimeManager.TimePeriod.DAY
var _last_day: int = 1
var _pending_time_transition: bool = false
var _release_tween: Tween


func _ready() -> void:
	_last_period = int(TimeManager.current_period)
	_last_day = TimeManager.days_passed
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

	if not GlobalSignals.time_advanced.is_connected(_on_time_advanced):
		GlobalSignals.time_advanced.connect(_on_time_advanced)

	var manager: Node = get_parent()

	if manager != null and manager.has_signal("transition_started"):
		if not manager.transition_started.is_connected(_on_transition_started):
			manager.transition_started.connect(_on_transition_started)

	if manager != null and manager.has_signal("transition_finished"):
		if not manager.transition_finished.is_connected(_on_transition_finished):
			manager.transition_finished.connect(_on_transition_finished)


func _on_time_advanced(
	period: int,
	days_passed: int,
	_calendar_day: int,
	_calendar_month: String
) -> void:
	var previous_period: int = _last_period
	var previous_day: int = _last_day
	_last_period = period
	_last_day = days_passed

	var period_changed: bool = period != previous_period
	var day_changed: bool = days_passed != previous_day

	if not period_changed and not day_changed:
		return

	var manager: Node = get_parent()

	if manager == null or not bool(manager.get("_runtime_active")):
		return

	var data := manager.get("presentation_data") as KubuTransitionPresentationData

	if data == null:
		return

	_kill_release_tween()
	_pending_time_transition = true
	color = (
		data.night_background_color
		if previous_period == TimeManager.TimePeriod.NIGHT
		else data.day_background_color
	)
	modulate.a = 1.0
	show()


func _on_transition_started(kind: StringName) -> void:
	if not _pending_time_transition:
		return

	if kind != &"period" and kind != &"day":
		return

	var manager: Node = get_parent()
	var data := manager.get("presentation_data") as KubuTransitionPresentationData
	var intro_seconds: float = 0.0

	if data != null:
		intro_seconds = maxf(0.0, data.time_intro_seconds)

	_kill_release_tween()
	_release_tween = create_tween()
	_release_tween.tween_interval(intro_seconds + maxf(0.0, intro_overlap_seconds))
	_release_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		maxf(0.01, release_seconds)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_release_tween.tween_callback(_finish_release)


func _on_transition_finished(kind: StringName) -> void:
	if kind != &"period" and kind != &"day":
		return

	if not _pending_time_transition:
		return

	_finish_release()


func _finish_release() -> void:
	_pending_time_transition = false
	hide()
	modulate.a = 1.0
	_release_tween = null


func _kill_release_tween() -> void:
	if _release_tween != null and _release_tween.is_valid():
		_release_tween.kill()

	_release_tween = null
