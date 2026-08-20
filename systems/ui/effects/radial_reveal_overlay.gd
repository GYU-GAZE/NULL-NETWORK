extends ColorRect
class_name RadialRevealOverlay


signal reveal_completed

var _reveal_tween: Tween


func _ready() -> void:
	if not resized.is_connected(_refresh_aspect_ratio):
		resized.connect(_refresh_aspect_ratio)
	_refresh_aspect_ratio()


func cover() -> void:
	_cancel_reveal()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_reveal_radius(0.0)


func uncover_immediately() -> void:
	_cancel_reveal()
	set_reveal_radius(0.0)
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func reveal_from_global_position(
	global_position: Vector2,
	duration_seconds: float,
	end_radius: float,
	feather: float
) -> void:
	cover()
	set_feather(feather)
	set_reveal_center_global(global_position)

	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_SINE)
	_reveal_tween.set_ease(Tween.EASE_IN_OUT)
	_reveal_tween.tween_method(
		set_reveal_radius,
		0.0,
		maxf(0.01, end_radius),
		maxf(0.01, duration_seconds)
	)
	await _reveal_tween.finished

	if not is_inside_tree():
		return

	_reveal_tween = null
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_completed.emit()


func set_reveal_center_global(global_position: Vector2) -> void:
	var rect := get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_set_shader_parameter("reveal_center", Vector2(0.5, 0.5))
		return

	_set_shader_parameter(
		"reveal_center",
		Vector2(
			clampf((global_position.x - rect.position.x) / rect.size.x, 0.0, 1.0),
			clampf((global_position.y - rect.position.y) / rect.size.y, 0.0, 1.0)
		)
	)


func set_reveal_radius(radius: float) -> void:
	_set_shader_parameter("reveal_radius", maxf(0.0, radius))


func set_feather(feather: float) -> void:
	_set_shader_parameter("reveal_feather", maxf(0.001, feather))


func is_covering() -> bool:
	return visible


func _refresh_aspect_ratio() -> void:
	var safe_height := maxf(1.0, size.y)
	_set_shader_parameter(
		"aspect_ratio",
		maxf(0.1, size.x / safe_height)
	)


func _set_shader_parameter(parameter: StringName, value: Variant) -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(parameter, value)


func _cancel_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = null
