extends CharacterBody2D
class_name LocalAreaPlayerController


signal facing_changed(direction: Vector2)


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

@onready var area_camera: Camera2D = %AreaCamera


var _input_enabled: bool = false
var _last_facing: Vector2 = Vector2.DOWN


func _ready() -> void:
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

	# O viewport usa pixels inteiros. O snap impede que o sprite e a câmera
	# parem entre pixels depois de colisões.
	global_position = global_position.round()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	set_physics_process(enabled)

	if not enabled:
		velocity = Vector2.ZERO


func configure_camera_bounds(bounds: Rect2) -> void:
	if not is_instance_valid(area_camera):
		return

	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		push_warning(
			"LocalAreaPlayerController: camera bounds are invalid."
		)
		return

	var bounds_end: Vector2 = bounds.end

	area_camera.limit_left = floori(bounds.position.x)
	area_camera.limit_top = floori(bounds.position.y)
	area_camera.limit_right = ceili(bounds_end.x)
	area_camera.limit_bottom = ceili(bounds_end.y)
	area_camera.position_smoothing_enabled = false
	area_camera.enabled = true
	area_camera.reset_smoothing()


func get_facing_direction() -> Vector2:
	return _last_facing


func _update_facing(input_direction: Vector2) -> void:
	var resolved_facing := Vector2.ZERO

	if absf(input_direction.x) > absf(input_direction.y):
		resolved_facing.x = signf(input_direction.x)
	else:
		resolved_facing.y = signf(input_direction.y)

	if resolved_facing == _last_facing:
		return

	_last_facing = resolved_facing
	facing_changed.emit(_last_facing)
