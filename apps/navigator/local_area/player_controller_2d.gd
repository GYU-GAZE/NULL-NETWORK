extends CharacterBody2D
class_name LocalAreaPlayerController


signal facing_changed(direction: Vector2)
signal interaction_target_changed(
	target: LocalAreaInteractable
)
signal interaction_requested(
	target: LocalAreaInteractable
)


@export_category("Movement")
@export_range(1.0, 480.0, 1.0)
var move_speed: float = 120.0

@export var move_left_action: StringName = (
	&"local_area_move_left"
)
@export var move_right_action: StringName = (
	&"local_area_move_right"
)
@export var move_up_action: StringName = (
	&"local_area_move_up"
)
@export var move_down_action: StringName = (
	&"local_area_move_down"
)

@export_category("Interaction")
@export var interact_action: StringName = (
	&"local_area_interact"
)

@onready var area_camera: Camera2D = %AreaCamera
@onready var interaction_sensor: LocalAreaInteractionSensor = (
	%InteractionSensor
)


var _input_enabled: bool = false
var _last_facing: Vector2 = Vector2.DOWN
var _camera_bounds: Rect2 = Rect2()
var _has_camera_bounds: bool = false


func _ready() -> void:
	var viewport: Viewport = get_viewport()

	if not viewport.size_changed.is_connected(
		_on_viewport_size_changed
	):
		viewport.size_changed.connect(
			_on_viewport_size_changed
		)

	if (
		is_instance_valid(interaction_sensor)
		and not interaction_sensor.target_changed.is_connected(
			_on_interaction_target_changed
		)
	):
		interaction_sensor.target_changed.connect(
			_on_interaction_target_changed
		)

	if (
		is_instance_valid(interaction_sensor)
		and not interaction_sensor.interaction_requested.is_connected(
			_on_interaction_requested
		)
	):
		interaction_sensor.interaction_requested.connect(
			_on_interaction_requested
		)

	if is_instance_valid(interaction_sensor):
		interaction_sensor.update_facing(_last_facing)

	set_input_enabled(false)


func _physics_process(_delta: float) -> void:
	if not _input_enabled:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action
	)

	if not input_direction.is_zero_approx():
		_update_facing(input_direction)

	velocity = input_direction * move_speed
	move_and_slide()

	# O viewport usa pixels inteiros. O snap impede que o player pare
	# entre pixels depois de colisões.
	global_position = global_position.round()
	_refresh_camera_position()

	if (
		is_instance_valid(interaction_sensor)
		and not input_direction.is_zero_approx()
	):
		interaction_sensor.refresh_target()

	if (
		is_instance_valid(interaction_sensor)
		and Input.is_action_just_pressed(interact_action)
	):
		interaction_sensor.try_interact()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	set_physics_process(enabled)

	if is_instance_valid(interaction_sensor):
		interaction_sensor.set_sensor_enabled(enabled)

	if not enabled:
		velocity = Vector2.ZERO
	else:
		call_deferred(
			"_refresh_camera_position",
			true
		)


func configure_camera_bounds(bounds: Rect2) -> void:
	if not is_instance_valid(area_camera):
		return

	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		push_warning(
			"LocalAreaPlayerController: camera bounds are invalid."
		)
		return

	_camera_bounds = bounds
	_has_camera_bounds = true

	# A posição da câmera já é limitada abaixo usando o tamanho real
	# do SubViewport. Manter também os limits nativos criaria dois
	# clamps concorrentes durante um resize.
	area_camera.limit_enabled = false
	area_camera.position_smoothing_enabled = false
	area_camera.enabled = true
	area_camera.reset_smoothing()
	call_deferred(
		"_refresh_camera_position",
		true
	)


func get_facing_direction() -> Vector2:
	return _last_facing


func get_interact_action() -> StringName:
	return interact_action


func _refresh_camera_position(
	force_scroll_update: bool = false
) -> void:
	if (
		not _has_camera_bounds
		or not is_instance_valid(area_camera)
		or not is_inside_tree()
	):
		return

	var viewport_size: Vector2 = get_viewport_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var safe_zoom := Vector2(
		maxf(0.001, absf(area_camera.zoom.x)),
		maxf(0.001, absf(area_camera.zoom.y))
	)
	var visible_world_size: Vector2 = (
		viewport_size / safe_zoom
	)
	var half_view_size: Vector2 = (
		visible_world_size * 0.5
	)
	var minimum_center: Vector2 = (
		_camera_bounds.position + half_view_size
	)
	var maximum_center: Vector2 = (
		_camera_bounds.end - half_view_size
	)
	var target_center: Vector2 = global_position

	target_center.x = _clamp_camera_axis(
		target_center.x,
		minimum_center.x,
		maximum_center.x,
		_camera_bounds.get_center().x
	)
	target_center.y = _clamp_camera_axis(
		target_center.y,
		minimum_center.y,
		maximum_center.y,
		_camera_bounds.get_center().y
	)

	# Coordenadas globais evitam que o deslocamento herdado do Player
	# interfira no novo enquadramento durante um resize.
	area_camera.global_position = target_center.round()

	if force_scroll_update:
		area_camera.force_update_scroll()


func _clamp_camera_axis(
	value: float,
	minimum: float,
	maximum: float,
	fallback_center: float
) -> float:
	if minimum > maximum:
		return fallback_center

	return clampf(value, minimum, maximum)


func _on_viewport_size_changed() -> void:
	call_deferred(
		"_refresh_camera_position",
		true
	)


func _update_facing(input_direction: Vector2) -> void:
	var resolved_facing := Vector2.ZERO

	if absf(input_direction.x) > absf(input_direction.y):
		resolved_facing.x = signf(
			input_direction.x
		)
	else:
		resolved_facing.y = signf(
			input_direction.y
		)

	if resolved_facing == _last_facing:
		return

	_last_facing = resolved_facing

	if is_instance_valid(interaction_sensor):
		interaction_sensor.update_facing(
			_last_facing
		)

	facing_changed.emit(_last_facing)


func _on_interaction_target_changed(
	target: LocalAreaInteractable
) -> void:
	interaction_target_changed.emit(target)


func _on_interaction_requested(
	target: LocalAreaInteractable
) -> void:
	interaction_requested.emit(target)
