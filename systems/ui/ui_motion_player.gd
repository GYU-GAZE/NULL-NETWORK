extends Node
class_name UiMotionPlayer


@export var profile: UiMotionProfileData

var _active_tweens: Dictionary = {}


func _ready() -> void:
	assert(profile != null, "UiMotionPlayer requires a UiMotionProfileData resource.")
	for error: String in profile.validate_data():
		push_error("UiMotionPlayer profile: %s" % error)


func enter_control(
	control: Control,
	offset: Vector2 = Vector2.INF,
	duration: float = -1.0
) -> void:
	if not is_instance_valid(control):
		return
	var resolved_offset := profile.panel_offset if offset == Vector2.INF else offset
	var resolved_duration := (
		profile.panel_enter_duration if duration < 0.0 else duration
	)
	_kill_control_tween(control)
	control.show()
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	_set_control_position(resting_position + resolved_offset, control)
	control.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_set_control_position.bind(control),
		control.position,
		resting_position,
		resolved_duration
	)
	tween.tween_property(control, "modulate:a", 1.0, resolved_duration * 0.78)
	await tween.finished
	_finish_control_tween(control, resting_position)


func exit_control(
	control: Control,
	offset: Vector2 = Vector2.INF,
	duration: float = -1.0,
	hide_after: bool = true
) -> void:
	if not is_instance_valid(control):
		return
	var resolved_offset := profile.panel_offset if offset == Vector2.INF else offset
	var resolved_duration := (
		profile.panel_exit_duration if duration < 0.0 else duration
	)
	_kill_control_tween(control)
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(
		_set_control_position.bind(control),
		resting_position,
		resting_position + resolved_offset,
		resolved_duration
	)
	tween.tween_property(control, "modulate:a", 0.0, resolved_duration)
	await tween.finished
	control.position = resting_position
	control.modulate.a = 1.0
	if hide_after:
		control.hide()
	_active_tweens.erase(control.get_instance_id())


func transition_between(
	old_control: Control,
	new_control: Control,
	forward: bool = true
) -> void:
	if not is_instance_valid(old_control) or not is_instance_valid(new_control):
		return
	_kill_control_tween(old_control)
	_kill_control_tween(new_control)
	var direction := 1.0 if forward else -1.0
	var offset := KubuOSMetrics.snap_vector(profile.page_offset * direction)
	var old_rest := KubuOSMetrics.snap_vector(old_control.position)
	var new_rest := KubuOSMetrics.snap_vector(new_control.position)
	new_control.show()
	new_control.modulate.a = 0.0
	_set_control_position(new_rest + offset, new_control)
	var tween := create_tween().set_parallel(true)
	_register_tween(old_control, tween)
	_register_tween(new_control, tween)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_set_control_position.bind(old_control),
		old_rest,
		old_rest - offset,
		profile.page_duration
	)
	tween.tween_property(old_control, "modulate:a", 0.0, profile.page_duration * 0.68)
	tween.tween_method(
		_set_control_position.bind(new_control),
		new_control.position,
		new_rest,
		profile.page_duration
	)
	tween.tween_property(new_control, "modulate:a", 1.0, profile.page_duration * 0.82)
	await tween.finished
	old_control.hide()
	old_control.position = old_rest
	old_control.modulate.a = 1.0
	_finish_control_tween(new_control, new_rest)
	_active_tweens.erase(old_control.get_instance_id())


func reveal_group_staggered(controls: Array[Control], offset: Vector2) -> void:
	if controls.is_empty():
		return
	for control: Control in controls:
		if not is_instance_valid(control):
			continue
		enter_control(control, offset, profile.panel_enter_duration)
		if profile.stagger_delay > 0.0:
			await get_tree().create_timer(profile.stagger_delay).timeout
	await get_tree().create_timer(profile.panel_enter_duration).timeout


func pulse_selection(control: Control) -> void:
	if not is_instance_valid(control):
		return
	_kill_control_tween(control)
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	var lifted_position := resting_position - Vector2(0, profile.selection_lift_pixels)
	var tween := create_tween()
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_set_control_position.bind(control),
		resting_position,
		lifted_position,
		profile.confirm_duration * 0.45
	)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(
		_set_control_position.bind(control),
		lifted_position,
		resting_position,
		profile.confirm_duration * 0.55
	)
	await tween.finished
	control.position = resting_position
	_active_tweens.erase(control.get_instance_id())


func _set_control_position(value: Vector2, control: Control) -> void:
	if is_instance_valid(control):
		control.position = KubuOSMetrics.snap_vector(value)


func _register_tween(control: Control, tween: Tween) -> void:
	_active_tweens[control.get_instance_id()] = tween


func _kill_control_tween(control: Control) -> void:
	var instance_id := control.get_instance_id()
	var tween := _active_tweens.get(instance_id) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_active_tweens.erase(instance_id)


func _finish_control_tween(control: Control, resting_position: Vector2) -> void:
	control.position = KubuOSMetrics.snap_vector(resting_position)
	control.modulate.a = 1.0
	_active_tweens.erase(control.get_instance_id())
