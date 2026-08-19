extends Node
class_name UiMotionPlayer


signal operation_finished(control: Control, operation: StringName)

@export var profile: UiMotionProfileData

var _active_tweens: Dictionary = {}
var _operation_revisions: Dictionary = {}
var _target_states: Dictionary = {}


func _ready() -> void:
	assert(profile != null, "UiMotionPlayer requires a UiMotionProfileData resource.")
	for error: String in profile.validate_data():
		push_error("UiMotionPlayer profile: %s" % error)


func _exit_tree() -> void:
	cancel_all()


func enter_control(control: Control, offset: Vector2 = Vector2.INF, duration: float = -1.0) -> void:
	if not _can_animate(control):
		return
	var resolved_offset := profile.panel_offset if offset == Vector2.INF else offset
	var seconds := profile.panel_enter_duration if duration < 0.0 else duration
	var revision := _begin_operation(control)
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, resting_position, control.size, true)
	control.show()
	control.position = KubuOSMetrics.snap_vector(resting_position + resolved_offset)
	control.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_position.bind(control), control.position, resting_position, seconds)
	tween.tween_property(control, "modulate:a", 1.0, seconds * 0.8)
	if not (await _wait_operation(control, revision, seconds)):
		return
	_finish_control(control, resting_position, true, &"enter")


func exit_control(control: Control, offset: Vector2 = Vector2.INF, duration: float = -1.0, hide_after: bool = true) -> void:
	if not _can_animate(control):
		return
	var resolved_offset := profile.panel_offset if offset == Vector2.INF else offset
	var seconds := profile.panel_exit_duration if duration < 0.0 else duration
	var revision := _begin_operation(control)
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, resting_position, control.size, not hide_after)
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_position.bind(control), resting_position, resting_position + resolved_offset, seconds)
	tween.tween_property(control, "modulate:a", 0.0, seconds)
	if not (await _wait_operation(control, revision, seconds)):
		return
	_finish_control(control, resting_position, not hide_after, &"exit")
	if hide_after and is_instance_valid(control):
		control.hide()
		control.modulate = Color.WHITE


func transition_between(old_control: Control, new_control: Control, forward: bool = true) -> void:
	if not _can_animate(old_control) or not _can_animate(new_control):
		return
	var direction := 1.0 if forward else -1.0
	var offset := KubuOSMetrics.snap_vector(profile.page_offset * direction)
	var old_rest := KubuOSMetrics.snap_vector(old_control.position)
	var new_rest := KubuOSMetrics.snap_vector(new_control.position)
	var old_revision := _begin_operation(old_control)
	var new_revision := _begin_operation(new_control)
	_remember_target(old_control, old_rest, old_control.size, false)
	_remember_target(new_control, new_rest, new_control.size, true)
	new_control.show()
	new_control.modulate.a = 0.0
	new_control.position = KubuOSMetrics.snap_vector(new_rest + offset)
	var tween := create_tween().set_parallel(true)
	_register_tween(old_control, tween)
	_register_tween(new_control, tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_position.bind(old_control), old_rest, old_rest - offset, profile.page_exit_duration)
	tween.tween_property(old_control, "modulate:a", 0.0, profile.page_exit_duration)
	tween.tween_method(_set_position.bind(new_control), new_control.position, new_rest, profile.page_enter_duration).set_delay(profile.page_exit_duration * 0.35)
	tween.tween_property(new_control, "modulate:a", 1.0, profile.page_enter_duration * 0.82).set_delay(profile.page_exit_duration * 0.35)
	var total_seconds := maxf(profile.page_exit_duration, profile.page_exit_duration * 0.35 + profile.page_enter_duration)
	await get_tree().create_timer(total_seconds).timeout
	if is_instance_valid(old_control) and _is_current(old_control, old_revision):
		_finish_control(old_control, old_rest, false, &"page_exit")
		old_control.hide()
		old_control.modulate = Color.WHITE
	if is_instance_valid(new_control) and _is_current(new_control, new_revision):
		_finish_control(new_control, new_rest, true, &"page_enter")


func reveal_group_staggered(controls: Array[Control], offset: Vector2 = Vector2.INF) -> void:
	if controls.is_empty():
		return
	for control: Control in controls:
		if not _can_animate(control):
			continue
		enter_control(control, offset, profile.panel_enter_duration)
		if profile.stagger_delay > 0.0:
			await get_tree().create_timer(profile.stagger_delay).timeout
	await get_tree().create_timer(profile.panel_enter_duration).timeout


func pulse_selection(control: Control) -> void:
	await confirm_control(control)


func confirm_control(control: Control) -> void:
	if not _can_animate(control):
		return
	var revision := _begin_operation(control)
	var resting_position := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, resting_position, control.size, control.visible)
	var lifted := resting_position - Vector2(0, profile.selection_lift_pixels)
	var seconds := profile.button_confirm_duration
	var tween := create_tween()
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_position.bind(control), resting_position, lifted, seconds * 0.45)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(_set_position.bind(control), lifted, resting_position, seconds * 0.55)
	if not (await _wait_operation(control, revision, seconds)):
		return
	_finish_control(control, resting_position, true, &"confirm")


func reject_control(control: Control) -> void:
	if not _can_animate(control):
		return
	var revision := _begin_operation(control)
	var rest := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, rest, control.size, control.visible)
	var strength: float = roundf(profile.reject_offset_pixels)
	var step := profile.reject_duration / 4.0
	var tween := create_tween()
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var previous := rest
	for x: float in [strength, -strength, strength * 0.5, 0.0]:
		var target := rest + Vector2(x, 0)
		tween.tween_method(_set_position.bind(control), previous, target, step)
		previous = target
	if not (await _wait_operation(control, revision, profile.reject_duration)):
		return
	_finish_control(control, rest, true, &"reject")


func fade_replace(old_control: Control, new_control: Control) -> void:
	if not _can_animate(old_control) or not _can_animate(new_control):
		return
	var old_revision := _begin_operation(old_control)
	var new_revision := _begin_operation(new_control)
	_remember_target(old_control, old_control.position, old_control.size, false)
	_remember_target(new_control, new_control.position, new_control.size, true)
	new_control.show()
	new_control.modulate.a = 0.0
	var tween := create_tween()
	_register_tween(old_control, tween)
	_register_tween(new_control, tween)
	tween.tween_property(old_control, "modulate:a", 0.0, profile.fade_exit_duration)
	tween.tween_callback(old_control.hide)
	tween.tween_property(new_control, "modulate:a", 1.0, profile.fade_enter_duration)
	var seconds := profile.fade_exit_duration + profile.fade_enter_duration
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(old_control) and _is_current(old_control, old_revision):
		_finish_control(old_control, KubuOSMetrics.snap_vector(old_control.position), false, &"fade_exit")
		old_control.hide()
		old_control.modulate = Color.WHITE
	if is_instance_valid(new_control) and _is_current(new_control, new_revision):
		_finish_control(new_control, KubuOSMetrics.snap_vector(new_control.position), true, &"fade_enter")


func transition_rect(control: Control, target_rect: Rect2, duration: float = -1.0) -> void:
	if not _can_animate(control):
		return
	var seconds := profile.window_geometry_duration if duration < 0.0 else duration
	var revision := _begin_operation(control)
	var target_position := KubuOSMetrics.snap_vector(target_rect.position)
	var target_size := KubuOSMetrics.snap_vector(target_rect.size)
	_remember_target(control, target_position, target_size, control.visible)
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_position.bind(control), control.position, target_position, seconds)
	tween.tween_method(_set_size.bind(control), control.size, target_size, seconds)
	if not (await _wait_operation(control, revision, seconds)):
		return
	control.position = target_position
	control.size = target_size
	control.scale = Vector2.ONE
	control.modulate = Color.WHITE
	control.rotation = 0.0
	_active_tweens.erase(control.get_instance_id())
	_target_states.erase(control.get_instance_id())
	_operation_revisions.erase(control.get_instance_id())
	operation_finished.emit(control, &"geometry")


func flash_control(control: Control, peak: Color = Color(1.12, 1.12, 1.18, 1.0), duration: float = -1.0) -> void:
	if not _can_animate(control):
		return
	var seconds := profile.window_focus_duration if duration < 0.0 else duration
	var revision := _begin_operation(control)
	_remember_target(control, control.position, control.size, control.visible)
	control.modulate = Color.WHITE
	var tween := create_tween()
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", peak, seconds * 0.45)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(control, "modulate", Color.WHITE, seconds * 0.55)
	if not (await _wait_operation(control, revision, seconds)):
		return
	control.modulate = Color.WHITE
	_active_tweens.erase(control.get_instance_id())
	_target_states.erase(control.get_instance_id())
	_operation_revisions.erase(control.get_instance_id())
	operation_finished.emit(control, &"flash")


func enter_scaled_control(control: Control, start_scale: Vector2, offset: Vector2, duration: float) -> void:
	if not _can_animate(control):
		return
	if _is_container_managed(control):
		await _enter_scaled_container_child(control, start_scale, duration)
		return
	var revision := _begin_operation(control)
	var rest := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, rest, control.size, true)
	control.show()
	control.position = KubuOSMetrics.snap_vector(rest + offset)
	control.scale = start_scale
	control.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_position.bind(control), control.position, rest, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.8)
	if not (await _wait_operation(control, revision, duration)):
		return
	_finish_control(control, rest, true, &"scaled_enter")


func exit_scaled_control(control: Control, end_scale: Vector2, offset: Vector2, duration: float) -> void:
	if not _can_animate(control):
		return
	if _is_container_managed(control):
		await _exit_scaled_container_child(control, end_scale, duration)
		return
	var revision := _begin_operation(control)
	var rest := KubuOSMetrics.snap_vector(control.position)
	_remember_target(control, rest, control.size, false)
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_position.bind(control), rest, rest + offset, duration)
	tween.tween_property(control, "scale", end_scale, duration)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	if not (await _wait_operation(control, revision, duration)):
		return
	_finish_control(control, rest, false, &"scaled_exit")


func _enter_scaled_container_child(control: Control, start_scale: Vector2, duration: float) -> void:
	_kill_control_tween(control)
	var revision := _increment_revision(control)
	control.show()
	control.scale = start_scale
	control.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.8)
	if not (await _wait_operation(control, revision, duration)):
		return
	_finish_container_transform(control, true, &"scaled_enter")


func _exit_scaled_container_child(control: Control, end_scale: Vector2, duration: float) -> void:
	_kill_control_tween(control)
	var revision := _increment_revision(control)
	var tween := create_tween().set_parallel(true)
	_register_tween(control, tween)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(control, "scale", end_scale, duration)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	if not (await _wait_operation(control, revision, duration)):
		return
	_finish_container_transform(control, false, &"scaled_exit")


func _finish_container_transform(control: Control, visible_state: bool, operation: StringName) -> void:
	if not is_instance_valid(control):
		return
	control.scale = Vector2.ONE
	control.rotation = 0.0
	control.modulate = Color.WHITE
	control.visible = visible_state
	_active_tweens.erase(control.get_instance_id())
	_target_states.erase(control.get_instance_id())
	_operation_revisions.erase(control.get_instance_id())
	operation_finished.emit(control, operation)


func _is_container_managed(control: Control) -> bool:
	return is_instance_valid(control) and control.get_parent() is Container


func cancel_control(
	control: Control,
	normalize: bool = true,
	settle_to_target: bool = true
) -> void:
	if not is_instance_valid(control):
		return
	_increment_revision(control)
	_kill_control_tween(control)
	if settle_to_target and _target_states.has(control.get_instance_id()):
		_settle_control_target(control)
	elif normalize:
		control.position = KubuOSMetrics.snap_vector(control.position)
		control.size = KubuOSMetrics.snap_vector(control.size)
		control.scale = Vector2.ONE
		control.rotation = 0.0
		control.modulate = Color.WHITE
	_target_states.erase(control.get_instance_id())
	_operation_revisions.erase(control.get_instance_id())


func cancel_all() -> void:
	for tween_value: Variant in _active_tweens.values():
		var tween := tween_value as Tween
		if tween != null and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
	for target_value: Variant in _target_states.values():
		if target_value is not Dictionary:
			continue
		var target: Dictionary = target_value
		var reference: WeakRef = target.get("control") as WeakRef
		var control: Control
		if reference != null:
			control = reference.get_ref() as Control
		if is_instance_valid(control):
			_apply_target_state(control, target)
	_target_states.clear()
	_operation_revisions.clear()


func _can_animate(control: Control) -> bool:
	return profile != null and is_instance_valid(control) and control.is_inside_tree()


func _begin_operation(control: Control) -> int:
	_kill_control_tween(control)
	_settle_control_target(control)
	return _increment_revision(control)


func _increment_revision(control: Control) -> int:
	var id := control.get_instance_id()
	var revision := int(_operation_revisions.get(id, 0)) + 1
	_operation_revisions[id] = revision
	return revision


func _is_current(control: Control, revision: int) -> bool:
	return is_instance_valid(control) and int(_operation_revisions.get(control.get_instance_id(), -1)) == revision


func _wait_operation(control: Control, revision: int, seconds: float) -> bool:
	await get_tree().create_timer(maxf(0.001, seconds)).timeout
	if not is_instance_valid(control):
		return false
	return _is_current(control, revision)


func _set_position(value: Vector2, control_value: Variant) -> void:
	if not is_instance_valid(control_value):
		return
	var control: Control = control_value as Control
	if control != null:
		control.position = KubuOSMetrics.snap_vector(value)


func _set_size(value: Vector2, control_value: Variant) -> void:
	if not is_instance_valid(control_value):
		return
	var control: Control = control_value as Control
	if control != null:
		control.size = KubuOSMetrics.snap_vector(value)


func _register_tween(control: Control, tween: Tween) -> void:
	_active_tweens[control.get_instance_id()] = tween


func _kill_control_tween(control: Control) -> void:
	var control_id := control.get_instance_id()
	var tween := _active_tweens.get(control_id) as Tween
	if tween == null:
		_active_tweens.erase(control_id)
		return
	var linked_ids: Array[int] = []
	for id_value: Variant in _active_tweens.keys():
		var id := int(id_value)
		if _active_tweens.get(id) == tween:
			linked_ids.append(id)
	if tween != null and tween.is_valid():
		tween.kill()
	for id: int in linked_ids:
		_active_tweens.erase(id)
		var target_value: Variant = _target_states.get(id)
		if target_value is not Dictionary:
			continue
		var target: Dictionary = target_value
		var reference: WeakRef = target.get("control") as WeakRef
		var linked_control: Control
		if reference != null:
			linked_control = reference.get_ref() as Control
		if is_instance_valid(linked_control):
			_apply_target_state(linked_control, target)
			if id != control_id:
				_increment_revision(linked_control)
		_target_states.erase(id)


func _remember_target(
	control: Control,
	position: Vector2,
	size: Vector2,
	visible_state: bool
) -> void:
	_target_states[control.get_instance_id()] = {
		"control": weakref(control),
		"position": KubuOSMetrics.snap_vector(position),
		"size": KubuOSMetrics.snap_vector(size),
		"visible": visible_state,
	}


func _settle_control_target(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var id := control.get_instance_id()
	var target_value: Variant = _target_states.get(id)
	if target_value is Dictionary:
		_apply_target_state(control, target_value as Dictionary)
	_target_states.erase(id)


func _apply_target_state(control: Control, target: Dictionary) -> void:
	var target_position: Vector2 = target.get("position", control.position)
	var target_size: Vector2 = target.get("size", control.size)
	control.position = KubuOSMetrics.snap_vector(target_position)
	control.size = KubuOSMetrics.snap_vector(target_size)
	control.scale = Vector2.ONE
	control.rotation = 0.0
	control.modulate = Color.WHITE
	control.visible = bool(target.get("visible", control.visible))


func _finish_control(control: Control, resting_position: Vector2, visible_state: bool, operation: StringName) -> void:
	if not is_instance_valid(control):
		return
	control.position = KubuOSMetrics.snap_vector(resting_position)
	control.scale = Vector2.ONE
	control.rotation = 0.0
	control.modulate = Color.WHITE
	control.visible = visible_state
	_active_tweens.erase(control.get_instance_id())
	_target_states.erase(control.get_instance_id())
	_operation_revisions.erase(control.get_instance_id())
	operation_finished.emit(control, operation)